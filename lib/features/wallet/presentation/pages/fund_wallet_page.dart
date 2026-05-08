import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../data/fund_wallet_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _softTint = Color(0xFFF3F4F6);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class FundWalletPage extends StatefulWidget {
  const FundWalletPage({super.key});

  @override
  State<FundWalletPage> createState() => _FundWalletPageState();
}

class _FundWalletPageState extends State<FundWalletPage> {
  List<_FundingRecord> _records = <_FundingRecord>[];

  double _walletBalance = 0;
  List<_ReceivingAccount> _receivingAccounts = <_ReceivingAccount>[];
  bool _isLoadingOverview = true;
  String? _copiedAccountNumber;

  @override
  void initState() {
    super.initState();
    _loadAccountOverview();
  }

  Future<void> _loadAccountOverview() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingOverview = false);
      return;
    }

    final FundWalletOverviewApiResult result = await FundWalletApiService
        .instance
        .fetchOverview(token: token);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await AppSessionService.instance.clear();
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingOverview = false);
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (Route<dynamic> route) => false,
      );
      return;
    }

    if (result.isSuccess && result.overview != null) {
      final FundWalletOverview overview = result.overview!;
      setState(() {
        _walletBalance = overview.walletBalance;
        _receivingAccounts = overview.receivingAccounts
            .map(
              (FundWalletReceivingAccount account) => _ReceivingAccount(
                bankName: account.bankName,
                accountName:
                    account.accountName.isNotEmpty
                        ? account.accountName.toUpperCase()
                        : 'PTS DATA USER',
                accountNumber: account.accountNumber,
              ),
            )
            .toList(growable: false);
        _records = overview.history
            .map(
              (FundWalletHistoryItem item) => _FundingRecord(
                createdAt: item.createdAt,
                amount: item.amount,
                status: item.status,
                reference: item.reference,
                typeLabel: item.typeLabel,
                paymentMethod: item.paymentMethod,
              ),
            )
            .toList(growable: false);
        _isLoadingOverview = false;
      });
      return;
    }

    setState(() => _isLoadingOverview = false);
    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _refreshAccountOverview() async {
    await _loadAccountOverview();
  }

  Future<void> _copyAccountNumber(String accountNumber) async {
    await Clipboard.setData(ClipboardData(text: accountNumber));
    if (!mounted) {
      return;
    }

    setState(() {
      _copiedAccountNumber = accountNumber;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Account number copied.')));

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || _copiedAccountNumber != accountNumber) {
      return;
    }

    setState(() {
      _copiedAccountNumber = null;
    });
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleAppBottomNavigationTap(
      context,
      destination: destination,
      currentDestination: AppBottomNavDestination.wallet,
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

  String _formatDate(DateTime value) {
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
    final String month = months[value.month - 1];
    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String minute = value.minute.toString().padLeft(2, '0');
    final String suffix = value.hour >= 12 ? 'PM' : 'AM';
    return '$month ${value.day}, ${value.year}, $hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? _darkBackground : Colors.white;
    final Color pageSurface = isDark ? _darkSurface : Colors.white;
    final Color panelColor = isDark ? _darkPanel : const Color(0xFFF8FAFC);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: titleColor,
          ),
        ),
        title: Text(
          'Fund Wallet',
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double bottomPadding =
              112 + MediaQuery.paddingOf(context).bottom;

          return RefreshIndicator.adaptive(
            color: _primary,
            onRefresh: _refreshAccountOverview,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - bottomPadding + 24,
                ),
                child: Container(
                  color: pageSurface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Fund your wallet by transferring to any active account below. Your wallet history updates when payment is processed.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 12.2,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            final double itemWidth =
                                (constraints.maxWidth - 16) / 3;
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                SizedBox(
                                  width: itemWidth,
                                  child: _HeroMetric(
                                    label: 'Balance',
                                    value:
                                        _isLoadingOverview
                                            ? '...'
                                            : _formatCurrency(_walletBalance),
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _HeroMetric(
                                    label: 'Review',
                                    value: 'Up to 10m',
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _HeroMetric(
                                    label: 'Accounts',
                                    value:
                                        _isLoadingOverview
                                            ? '...'
                                            : '${_receivingAccounts.length}',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Receive With These Accounts',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Use any of the accounts below to fund your wallet.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_isLoadingOverview)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                ),
                              ),
                            ),
                          )
                        else if (_receivingAccounts.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? _darkPanel : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    isDark
                                        ? const Color(0xFF3A4054)
                                        : _softBorder,
                              ),
                            ),
                            child: Text(
                              'No active receiving accounts were found for this wallet yet.',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                height: 1.35,
                              ),
                            ),
                          )
                        else
                          ..._receivingAccounts.map(
                            (_ReceivingAccount account) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ReceivingAccountCard(
                                account: account,
                                isDark: isDark,
                                copied:
                                    _copiedAccountNumber ==
                                    account.accountNumber,
                                onCopy:
                                    () => _copyAccountNumber(
                                      account.accountNumber,
                                    ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  isDark
                                      ? const Color(0xFF3A4054)
                                      : _softBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Funding Guide',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _GuideStep(
                                title: '1. Transfer funds',
                                description:
                                    'Send to any bank account shown on this page.',
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _GuideStep(
                                title: '2. Use your exact wallet account',
                                description:
                                    'Copy the account number carefully before sending payment.',
                                isDark: isDark,
                              ),
                              const SizedBox(height: 10),
                              _GuideStep(
                                title: '3. Wallet gets credited',
                                description:
                                    'Your payment appears in history after processing.',
                                isDark: isDark,
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? _darkSurface : Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Text(
                                  'Keep your bank receipt until the wallet transaction is processed.',
                                  style: TextStyle(
                                    color: mutedText,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  isDark
                                      ? const Color(0xFF3A4054)
                                      : _softBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          'Funding History',
                                          style: TextStyle(
                                            color: titleColor,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Latest wallet funding records',
                                          style: TextStyle(
                                            color: mutedText,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          isDark ? _darkSurface : Colors.white,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      '${_records.length} records',
                                      style: TextStyle(
                                        color: titleColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              if (_records.isEmpty)
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isDark ? _darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    'No funding records yet. Your transfers will appear here after processing.',
                                    style: TextStyle(
                                      color: mutedText,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                )
                              else
                                ..._records.map(
                                  (_FundingRecord record) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: _FundingRecordCard(
                                      record: record,
                                      isDark: isDark,
                                      formatter: _formatCurrency,
                                      dateFormatter: _formatDate,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigation(
        isDark: isDark,
        selectedDestination: AppBottomNavDestination.wallet,
        onSelect: _handleBottomNavigation,
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : _softTint,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: <Widget>[
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? _darkMuted : const Color(0xFF4B5563),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF111827),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivingAccountCard extends StatelessWidget {
  const _ReceivingAccountCard({
    required this.account,
    required this.isDark,
    required this.copied,
    required this.onCopy,
  });

  final _ReceivingAccount account;
  final bool isDark;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_rounded,
                  color: _primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      account.bankName,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      account.accountName,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Account Number',
            style: TextStyle(
              color: mutedText,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              account.accountNumber,
              style: TextStyle(
                color: titleColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? _darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.bolt_rounded, size: 15, color: _primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Use this for instant wallet funding',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.tonalIcon(
                onPressed: onCopy,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      copied
                          ? const Color(0xFFDCFCE7)
                          : _primary.withValues(alpha: isDark ? 0.20 : 0.12),
                  foregroundColor: copied ? const Color(0xFF166534) : _primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                icon: Icon(
                  copied ? Icons.check_rounded : Icons.copy_rounded,
                  size: 16,
                ),
                label: Text(copied ? 'Copied' : 'Copy'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.title,
    required this.description,
    required this.isDark,
  });

  final String title;
  final String description;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFF3F4F6) : const Color(0xFF374151),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: isDark ? _darkMuted : const Color(0xFF374151),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundingRecordCard extends StatelessWidget {
  const _FundingRecordCard({
    required this.record,
    required this.isDark,
    required this.formatter,
    required this.dateFormatter,
  });

  final _FundingRecord record;
  final bool isDark;
  final String Function(num amount) formatter;
  final String Function(DateTime value) dateFormatter;

  @override
  Widget build(BuildContext context) {
    final bool isApproved = record.status == 'approved';
    final bool isPending = record.status == 'pending';
    final Color badgeBackground =
        isApproved
            ? const Color(0xFFDCFCE7)
            : (isPending ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2));
    final Color badgeColor =
        isApproved
            ? const Color(0xFF166534)
            : (isPending ? const Color(0xFF92400E) : const Color(0xFFB91C1C));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  dateFormatter(record.createdAt),
                  style: TextStyle(
                    color: isDark ? _darkMuted : const Color(0xFF4B5563),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  record.status.toUpperCase(),
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text(
                  formatter(record.amount),
                  style: TextStyle(
                    color:
                        isDark
                            ? const Color(0xFFF8FAFC)
                            : const Color(0xFF111827),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  record.reference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isDark ? _darkMuted : const Color(0xFF4B5563),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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

class _ReceivingAccount {
  const _ReceivingAccount({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
  });

  final String bankName;
  final String accountName;
  final String accountNumber;
}

class _FundingRecord {
  const _FundingRecord({
    required this.createdAt,
    required this.amount,
    required this.status,
    required this.reference,
    this.typeLabel = '',
    this.paymentMethod = '',
  });

  final DateTime createdAt;
  final double amount;
  final String status;
  final String reference;
  final String typeLabel;
  final String paymentMethod;
}
