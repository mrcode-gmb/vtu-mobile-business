import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/utils/export_download.dart';
import '../../data/transaction_history_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

const List<_ChoiceOption<_TransactionStatus?>> _statusFilterOptions =
    <_ChoiceOption<_TransactionStatus?>>[
      _ChoiceOption(value: null, label: 'All Status'),
      _ChoiceOption(value: _TransactionStatus.success, label: 'Successful'),
      _ChoiceOption(value: _TransactionStatus.pending, label: 'Pending'),
      _ChoiceOption(value: _TransactionStatus.failed, label: 'Failed'),
    ];

const List<_ChoiceOption<_DateRangeFilter>> _dateFilterOptions =
    <_ChoiceOption<_DateRangeFilter>>[
      _ChoiceOption(value: _DateRangeFilter.all, label: 'All Time'),
      _ChoiceOption(value: _DateRangeFilter.today, label: 'Today'),
      _ChoiceOption(value: _DateRangeFilter.week, label: 'This Week'),
      _ChoiceOption(value: _DateRangeFilter.month, label: 'This Month'),
      _ChoiceOption(value: _DateRangeFilter.quarter, label: 'Last 3 Months'),
    ];

class TransactionHistoryPage extends StatefulWidget {
  const TransactionHistoryPage({super.key});

  @override
  State<TransactionHistoryPage> createState() => _TransactionHistoryPageState();
}

class _TransactionHistoryPageState extends State<TransactionHistoryPage> {
  static const List<_TransactionTypeChip> _typeChips = <_TransactionTypeChip>[
    _TransactionTypeChip(value: null, label: 'All'),
    _TransactionTypeChip(value: _TransactionType.airtime, label: 'Airtime'),
    _TransactionTypeChip(value: _TransactionType.data, label: 'Data'),
    _TransactionTypeChip(value: _TransactionType.funding, label: 'Funding'),
    _TransactionTypeChip(value: _TransactionType.transfer, label: 'Transfer'),
    _TransactionTypeChip(
      value: _TransactionType.electricity,
      label: 'Electricity',
    ),
    _TransactionTypeChip(value: _TransactionType.cable, label: 'Cable'),
  ];

  List<_TransactionRecord> _transactions = <_TransactionRecord>[];

  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  String _searchQuery = '';
  _TransactionType? _selectedType;
  _TransactionStatus? _selectedStatus;
  _DateRangeFilter _selectedDateRange = _DateRangeFilter.all;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalRecords = 0;
  bool _isLoading = true;
  String? _exportingFormat;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Map<String, List<_TransactionRecord>> get _groupedTransactions {
    final Map<String, List<_TransactionRecord>> grouped =
        <String, List<_TransactionRecord>>{};

    for (final _TransactionRecord item in _transactions) {
      final String key = _groupLabel(item.date);
      grouped.putIfAbsent(key, () => <_TransactionRecord>[]).add(item);
    }

    return grouped;
  }

  bool get _hasActiveFilters =>
      _searchQuery.trim().isNotEmpty ||
      _selectedType != null ||
      _selectedStatus != null ||
      _selectedDateRange != _DateRangeFilter.all;

  String get _selectedTypeApiValue => _selectedType?.apiValue ?? 'all';

  String get _selectedStatusApiValue => _selectedStatus?.apiValue ?? 'all';

  String get _selectedDateRangeApiValue => _selectedDateRange.apiValue;

  String get _statusFilterLabel =>
      _selectedStatus == null
          ? 'All Status'
          : _statusMeta[_selectedStatus!]!.label;

  String get _dateFilterLabel =>
      _dateFilterOptions
          .firstWhere(
            (_ChoiceOption<_DateRangeFilter> option) =>
                option.value == _selectedDateRange,
          )
          .label;

  String _groupLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime target = DateTime(date.year, date.month, date.day);

    if (target == today) {
      return 'Today';
    }

    if (target == yesterday) {
      return 'Yesterday';
    }

    if (!target.isBefore(today.subtract(const Duration(days: 7)))) {
      return 'This Week';
    }

    return _formatDateOnly(date);
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedType = null;
      _selectedStatus = null;
      _selectedDateRange = _DateRangeFilter.all;
      _currentPage = 1;
    });
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final TransactionHistoryApiResult result =
        await TransactionHistoryApiService.instance.fetchTransactions(
          token: token,
          page: _currentPage,
          type: _selectedTypeApiValue,
          status: _selectedStatusApiValue,
          dateRange: _selectedDateRangeApiValue,
          search: _searchQuery.trim(),
        );

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess && result.page != null) {
      setState(() {
        _transactions = result.page!.data
            .map(_TransactionRecord.fromApi)
            .toList(growable: false);
        _currentPage = result.page!.currentPage;
        _totalPages = result.page!.lastPage < 1 ? 1 : result.page!.lastPage;
        _totalRecords = result.page!.total;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _transactions = <_TransactionRecord>[];
      _totalPages = 1;
      _totalRecords = 0;
      _isLoading = false;
    });

    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _exportingFormat = null;
    });

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  Future<void> _exportTransactions(String format) async {
    if (_exportingFormat != null) {
      return;
    }

    final String normalizedFormat = format.toLowerCase();
    if (normalizedFormat != 'csv') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'PDF export is not connected yet. CSV export is ready.',
          ),
        ),
      );
      return;
    }

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    setState(() {
      _exportingFormat = format;
    });

    final TransactionHistoryExportApiResult result =
        await TransactionHistoryApiService.instance.exportTransactions(
          token: token,
          format: normalizedFormat,
          type: _selectedTypeApiValue,
          status: _selectedStatusApiValue,
          dateRange: _selectedDateRangeApiValue,
          search: _searchQuery.trim(),
        );

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (!result.isSuccess ||
        result.bytes == null ||
        result.fileName == null ||
        result.mimeType == null) {
      setState(() {
        _exportingFormat = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'We could not export transactions right now.',
          ),
        ),
      );
      return;
    }

    final bool downloaded = await downloadExportFile(
      bytes: result.bytes!,
      fileName: result.fileName!,
      mimeType: result.mimeType!,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _exportingFormat = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          downloaded
              ? (result.message ?? 'Transactions exported successfully.')
              : 'CSV export is ready on web builds. Native file saving is not connected yet.',
        ),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    final _HistoryFilterResult? result =
        await showModalBottomSheet<_HistoryFilterResult>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _HistoryFilterSheet(
              initialStatus: _selectedStatus,
              initialDateRange: _selectedDateRange,
            );
          },
        );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      _selectedStatus = result.status;
      _selectedDateRange = result.dateRange;
      _currentPage = 1;
    });
    await _loadTransactions();
  }

  void _queueSearch(String value) {
    _searchDebounce?.cancel();
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
    });

    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadTransactions();
    });
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    if (destination == AppBottomNavDestination.home) {
      await Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (Route<dynamic> route) => false,
      );
      return;
    }

    await handleAppBottomNavigationTap(
      context,
      destination: destination,
      currentDestination: AppBottomNavDestination.home,
    );
  }

  String _formatCurrency(num amount) {
    final String fixed = amount.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );
    return '\u20A6$whole.${parts.last}';
  }

  String _formatTime(DateTime value) {
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  String _formatDateOnly(DateTime value) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final Map<String, List<_TransactionRecord>> grouped = _groupedTransactions;
    final List<_TransactionRecord> transactions = _transactions;

    return PtsDataPageScaffold(
      title: 'Transaction History',
      contentPadding: EdgeInsets.zero,
      onRefresh: _loadTransactions,
      selectedBottomNav: AppBottomNavDestination.home,
      onBottomNavigation:
          (AppBottomNavDestination destination) =>
              _handleBottomNavigation(destination),
      child: Container(
        color: isDark ? ptsDataDarkBackground : const Color(0xFFF6F7FB),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkSurface : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Transactions',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 23,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.35,
                          ),
                        ),
                      ),
                      _TopActionButton(
                        label:
                            _exportingFormat != null ? 'Loading' : 'Statement',
                        icon:
                            _exportingFormat != null
                                ? null
                                : Icons.description_outlined,
                        loading: _exportingFormat != null,
                        isDark: isDark,
                        onTap: () => _exportTransactions('csv'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track your real Airtime, Data, Funding, Transfer, Cable, and Electricity records.',
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 12.2,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.search_rounded, size: 18, color: mutedText),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            onChanged: _queueSearch,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 13.2,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search description, ref, recipient...',
                              hintStyle: TextStyle(
                                color: mutedText,
                                fontSize: 12.4,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _openFilterSheet,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            Icons.tune_rounded,
                            color: titleColor,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        final _TransactionTypeChip chip = _typeChips[index];
                        final bool selected = chip.value == _selectedType;
                        return _TypeChipButton(
                          label: chip.label,
                          selected: selected,
                          isDark: isDark,
                          onTap: () async {
                            setState(() {
                              _selectedType = chip.value;
                              _currentPage = 1;
                            });
                            await _loadTransactions();
                          },
                        );
                      },
                      separatorBuilder:
                          (BuildContext context, int index) =>
                              const SizedBox(width: 8),
                      itemCount: _typeChips.length,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _CompactFilterPill(
                          label: _statusFilterLabel,
                          isDark: isDark,
                          onTap: _openFilterSheet,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompactFilterPill(
                          label: _dateFilterLabel,
                          isDark: isDark,
                          onTap: _openFilterSheet,
                        ),
                      ),
                      if (_hasActiveFilters) ...<Widget>[
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: _resetFilters,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 11,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? _darkPanel : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PtsDataSectionHeader(
                title: 'Recent Activity',
                subtitle:
                    'Your real Airtime, Data, Funding, Transfer, Cable, and Electricity records.',
                trailing: Text(
                  '${_totalRecords > 0 ? _totalRecords : transactions.length} records',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading && transactions.isEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                decoration: BoxDecoration(
                  color: isDark ? ptsDataDarkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: _LoadingState(isDark: isDark),
              )
            else if (transactions.isEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                decoration: BoxDecoration(
                  color: isDark ? ptsDataDarkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: _EmptyState(isDark: isDark),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children:
                    grouped.entries.map((
                      MapEntry<String, List<_TransactionRecord>> entry,
                    ) {
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: entry.key == grouped.keys.last ? 0 : 14,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Text(
                                entry.key,
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color:
                                    isDark ? ptsDataDarkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Column(
                                children:
                                    entry.value
                                        .map(
                                          (_TransactionRecord item) =>
                                              _WalletTransactionTile(
                                                transaction: item,
                                                isDark: isDark,
                                                formattedAmount:
                                                    _formatCurrency(
                                                      item.amount,
                                                    ),
                                                formattedTime: _formatTime(
                                                  item.date,
                                                ),
                                              ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            if (_isLoading && transactions.isNotEmpty) ...<Widget>[
              const SizedBox(height: 14),
              const LinearProgressIndicator(minHeight: 3),
            ],
            if (transactions.isNotEmpty && _totalPages > 1) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: isDark ? ptsDataDarkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Page $_currentPage of $_totalPages',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _PagerButton(
                      label: 'Prev',
                      icon: Icons.chevron_left_rounded,
                      isDark: isDark,
                      enabled: _currentPage > 1 && !_isLoading,
                      onTap: () async {
                        setState(() {
                          _currentPage -= 1;
                        });
                        await _loadTransactions();
                      },
                    ),
                    const SizedBox(width: 8),
                    _PagerButton(
                      label: 'Next',
                      icon: Icons.chevron_right_rounded,
                      isDark: isDark,
                      enabled: _currentPage < _totalPages && !_isLoading,
                      primary: true,
                      onTap: () async {
                        setState(() {
                          _currentPage += 1;
                        });
                        await _loadTransactions();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TopActionButton extends StatelessWidget {
  const _TopActionButton({
    required this.label,
    required this.icon,
    required this.loading,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData? icon;
  final bool loading;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: loading ? null : onTap,
      style: FilledButton.styleFrom(
        backgroundColor: isDark ? _darkSurface : Colors.white,
        disabledBackgroundColor: isDark ? _darkSurface : Colors.white,
        foregroundColor:
            isDark ? const Color(0xFFE5E7EB) : const Color(0xFF252A42),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFD1D5DB),
          ),
        ),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      icon:
          loading
              ? SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? const Color(0xFFE5E7EB) : const Color(0xFF252A42),
                  ),
                ),
              )
              : Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _TypeChipButton extends StatelessWidget {
  const _TypeChipButton({
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? _primary : (isDark ? _darkSurface : Colors.white),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color:
                  selected
                      ? _primary
                      : (isDark
                          ? const Color(0xFF3A4054)
                          : const Color(0xFFD1D5DB)),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color:
                  selected
                      ? Colors.white
                      : (isDark
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF374151)),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactFilterPill extends StatelessWidget {
  const _CompactFilterPill({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: isDark ? _darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF3A4054) : const Color(0xFFD1D5DB),
            ),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isDark
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF374151),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.expand_more_rounded,
                size: 17,
                color:
                    isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletTransactionTile extends StatelessWidget {
  const _WalletTransactionTile({
    required this.transaction,
    required this.isDark,
    required this.formattedAmount,
    required this.formattedTime,
  });

  final _TransactionRecord transaction;
  final bool isDark;
  final String formattedAmount;
  final String formattedTime;

  @override
  Widget build(BuildContext context) {
    final _TransactionTypeMeta typeMeta = _typeMeta[transaction.type]!;
    final _TransactionStatusMeta statusMeta = _statusMeta[transaction.status]!;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final bool isPositive =
        transaction.direction == _TransactionDirection.incoming;
    final Color amountColor =
        isPositive
            ? const Color(0xFF16A34A)
            : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827));
    final String subtitle = <String>[
      formattedTime,
      if (transaction.recipient != null) transaction.recipient!,
      if (transaction.network != null) transaction.network!,
      if (transaction.plan != null) transaction.plan!,
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
            width: 0.6,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: typeMeta.backgroundColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(typeMeta.icon, size: 18, color: typeMeta.iconColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  transaction.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: <Widget>[
                    Text(
                      transaction.reference ?? '-',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (transaction.quantity != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF3A4054) : Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Qty ${transaction.quantity}',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${isPositive ? '+' : '-'}$formattedAmount',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusMeta.backgroundColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusMeta.label,
                  style: TextStyle(
                    color: statusMeta.foregroundColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.label,
    required this.icon,
    required this.isDark,
    required this.enabled,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final IconData icon;
  final bool isDark;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bgColor =
        primary ? _primary : (isDark ? _darkSurface : Colors.white);
    final Color fgColor =
        primary
            ? Colors.white
            : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151));

    return FilledButton.icon(
      onPressed: enabled ? onTap : null,
      style: FilledButton.styleFrom(
        backgroundColor: bgColor,
        disabledBackgroundColor:
            isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
        foregroundColor: fgColor,
        disabledForegroundColor:
            isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side:
              primary
                  ? BorderSide.none
                  : BorderSide(
                    color:
                        isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFD1D5DB),
                  ),
        ),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      icon: Icon(icon, size: 16),
      label: Text(label),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? _darkPanel : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long_rounded,
              size: 24,
              color: isDark ? _darkMuted : const Color(0xFFC7CDDC),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No transactions found',
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or filter settings.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? _darkMuted : const Color(0xFF4B5563),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: <Widget>[
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFFB89CFF) : _primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Loading transactions...',
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFilterSheet extends StatefulWidget {
  const _HistoryFilterSheet({
    required this.initialStatus,
    required this.initialDateRange,
  });

  final _TransactionStatus? initialStatus;
  final _DateRangeFilter initialDateRange;

  @override
  State<_HistoryFilterSheet> createState() => _HistoryFilterSheetState();
}

class _HistoryFilterSheetState extends State<_HistoryFilterSheet> {
  late _TransactionStatus? _status = widget.initialStatus;
  late _DateRangeFilter _dateRange = widget.initialDateRange;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? _darkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFC7CDDC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Filter Transactions',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Match the compact wallet history pattern with quick filter groups.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Status',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _statusFilterOptions
                        .map(
                          (_ChoiceOption<_TransactionStatus?> option) =>
                              ChoiceChip(
                                label: Text(option.label),
                                selected: option.value == _status,
                                onSelected: (bool selected) {
                                  setState(() {
                                    _status = selected ? option.value : null;
                                  });
                                },
                              ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 18),
              Text(
                'Date Range',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    _dateFilterOptions
                        .map(
                          (_ChoiceOption<_DateRangeFilter> option) =>
                              ChoiceChip(
                                label: Text(option.label),
                                selected: option.value == _dateRange,
                                onSelected: (bool selected) {
                                  if (!selected) {
                                    return;
                                  }

                                  setState(() {
                                    _dateRange = option.value;
                                  });
                                },
                              ),
                        )
                        .toList(),
              ),
              const SizedBox(height: 18),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _status = null;
                          _dateRange = _DateRangeFilter.all;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: titleColor,
                        side: BorderSide(
                          color:
                              isDark
                                  ? const Color(0xFF374151)
                                  : const Color(0xFFD1D5DB),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(
                          _HistoryFilterResult(
                            status: _status,
                            dateRange: _dateRange,
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryFilterResult {
  const _HistoryFilterResult({required this.status, required this.dateRange});

  final _TransactionStatus? status;
  final _DateRangeFilter dateRange;
}

class _TransactionRecord {
  const _TransactionRecord({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.direction,
    required this.date,
    required this.description,
    this.recipient,
    this.reference,
    this.network,
    this.plan,
    this.quantity,
  });

  factory _TransactionRecord.fromApi(TransactionHistoryApiItem item) {
    return _TransactionRecord(
      id: item.id,
      type: _TransactionTypeX.fromApiValue(item.type),
      amount: item.amount,
      recipient: _sanitizeText(item.recipient),
      status: _TransactionStatusX.fromApiValue(item.status),
      direction: _TransactionDirectionX.fromApiValue(item.direction),
      date: item.date,
      description: item.description,
      reference: _sanitizeText(item.reference),
      network: _sanitizeText(item.network),
      plan: _sanitizeText(item.plan),
      quantity: item.quantity,
    );
  }

  final String id;
  final _TransactionType type;
  final double amount;
  final String? recipient;
  final _TransactionStatus status;
  final _TransactionDirection direction;
  final DateTime date;
  final String description;
  final String? reference;
  final String? network;
  final String? plan;
  final int? quantity;
}

class _ChoiceOption<T> {
  const _ChoiceOption({required this.value, required this.label});

  final T value;
  final String label;
}

class _TransactionTypeChip {
  const _TransactionTypeChip({required this.value, required this.label});

  final _TransactionType? value;
  final String label;
}

class _TransactionTypeMeta {
  const _TransactionTypeMeta({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
}

class _TransactionStatusMeta {
  const _TransactionStatusMeta({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
}

enum _TransactionType {
  airtime,
  data,
  cable,
  electricity,
  funding,
  transfer,
  cardGeneration,
  epin,
}

enum _TransactionStatus { success, pending, failed }

enum _TransactionDirection { incoming, outgoing }

enum _DateRangeFilter { all, today, week, month, quarter }

extension _TransactionTypeX on _TransactionType {
  String get apiValue {
    switch (this) {
      case _TransactionType.airtime:
        return 'airtime';
      case _TransactionType.data:
        return 'data';
      case _TransactionType.cable:
        return 'cable';
      case _TransactionType.electricity:
        return 'electricity';
      case _TransactionType.funding:
        return 'funding';
      case _TransactionType.transfer:
        return 'transfer';
      case _TransactionType.cardGeneration:
        return 'card_generation';
      case _TransactionType.epin:
        return 'epin';
    }
  }

  static _TransactionType fromApiValue(String value) {
    switch (value.toLowerCase()) {
      case 'airtime':
        return _TransactionType.airtime;
      case 'data':
        return _TransactionType.data;
      case 'cable':
        return _TransactionType.cable;
      case 'electricity':
        return _TransactionType.electricity;
      case 'funding':
        return _TransactionType.funding;
      case 'transfer':
        return _TransactionType.transfer;
      case 'card_generation':
      case 'airtime_card':
        return _TransactionType.cardGeneration;
      case 'epin':
      case 'data_card':
        return _TransactionType.epin;
      default:
        return _TransactionType.funding;
    }
  }
}

extension _TransactionStatusX on _TransactionStatus {
  String get apiValue {
    switch (this) {
      case _TransactionStatus.success:
        return 'success';
      case _TransactionStatus.pending:
        return 'pending';
      case _TransactionStatus.failed:
        return 'failed';
    }
  }

  static _TransactionStatus fromApiValue(String value) {
    switch (value.toLowerCase()) {
      case 'success':
      case 'successful':
        return _TransactionStatus.success;
      case 'pending':
        return _TransactionStatus.pending;
      default:
        return _TransactionStatus.failed;
    }
  }
}

extension _TransactionDirectionX on _TransactionDirection {
  static _TransactionDirection fromApiValue(String value) {
    switch (value.toLowerCase()) {
      case 'incoming':
      case 'credit':
        return _TransactionDirection.incoming;
      default:
        return _TransactionDirection.outgoing;
    }
  }
}

extension _DateRangeFilterX on _DateRangeFilter {
  String get apiValue {
    switch (this) {
      case _DateRangeFilter.all:
        return 'all';
      case _DateRangeFilter.today:
        return 'today';
      case _DateRangeFilter.week:
        return 'week';
      case _DateRangeFilter.month:
        return 'month';
      case _DateRangeFilter.quarter:
        return 'quarter';
    }
  }
}

String? _sanitizeText(String? value) {
  if (value == null) {
    return null;
  }

  final String trimmed = value.trim();
  if (trimmed.isEmpty || trimmed.toUpperCase() == 'N/A') {
    return null;
  }

  return trimmed;
}

const Map<_TransactionType, _TransactionTypeMeta> _typeMeta =
    <_TransactionType, _TransactionTypeMeta>{
      _TransactionType.airtime: _TransactionTypeMeta(
        label: 'Airtime',
        icon: Icons.call_rounded,
        backgroundColor: Color(0xFFE5E7EB),
        iconColor: Color(0xFFB89CFF),
      ),
      _TransactionType.data: _TransactionTypeMeta(
        label: 'Data',
        icon: Icons.wifi_rounded,
        backgroundColor: Color(0xFFDCFCE7),
        iconColor: Color(0xFF16A34A),
      ),
      _TransactionType.cable: _TransactionTypeMeta(
        label: 'Cable TV',
        icon: Icons.tv_rounded,
        backgroundColor: Color(0xFFEDE9FE),
        iconColor: Color(0xFF7C3AED),
      ),
      _TransactionType.electricity: _TransactionTypeMeta(
        label: 'Electricity',
        icon: Icons.bolt_rounded,
        backgroundColor: Color(0xFFFEF3C7),
        iconColor: Color(0xFFD97706),
      ),
      _TransactionType.funding: _TransactionTypeMeta(
        label: 'Funding',
        icon: Icons.account_balance_wallet_rounded,
        backgroundColor: Color(0xFFE0E7FF),
        iconColor: Color(0xFF4F46E5),
      ),
      _TransactionType.transfer: _TransactionTypeMeta(
        label: 'Transfer',
        icon: Icons.swap_horiz_rounded,
        backgroundColor: Color(0xFFFCE7F3),
        iconColor: Color(0xFFDB2777),
      ),
      _TransactionType.cardGeneration: _TransactionTypeMeta(
        label: 'Card Generation',
        icon: Icons.credit_card_rounded,
        backgroundColor: Color(0xFFFFEDD5),
        iconColor: Color(0xFFEA580C),
      ),
      _TransactionType.epin: _TransactionTypeMeta(
        label: 'E-PIN',
        icon: Icons.key_rounded,
        backgroundColor: Color(0xFFFFE4E6),
        iconColor: Color(0xFFE11D48),
      ),
    };

const Map<_TransactionStatus, _TransactionStatusMeta> _statusMeta =
    <_TransactionStatus, _TransactionStatusMeta>{
      _TransactionStatus.success: _TransactionStatusMeta(
        label: 'Successful',
        backgroundColor: Color(0xFFDCFCE7),
        foregroundColor: Color(0xFF15803D),
      ),
      _TransactionStatus.pending: _TransactionStatusMeta(
        label: 'Pending',
        backgroundColor: Color(0xFFFEF3C7),
        foregroundColor: Color(0xFFB45309),
      ),
      _TransactionStatus.failed: _TransactionStatusMeta(
        label: 'Failed',
        backgroundColor: Color(0xFFFEE2E2),
        foregroundColor: Color(0xFFB91C1C),
      ),
    };
