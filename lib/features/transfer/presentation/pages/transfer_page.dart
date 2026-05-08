import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../data/transfer_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _softTint = Color(0xFFF3F4F6);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});

  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  static const List<int> _quickAmounts = <int>[1000, 2000, 5000, 10000];

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  List<_TransferHistoryItem> _history = <_TransferHistoryItem>[];

  double _walletBalance = 0;
  double _minimumAmount = 100;
  String? _validatedRecipient;
  bool _isLoadingOverview = true;
  bool _validating = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text.trim()) ?? 0;

  bool get _canValidate =>
      _usernameController.text.trim().length >= 3 && _amount >= _minimumAmount;

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  Future<void> _loadOverview({bool showFailure = true}) async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingOverview = false);
      return;
    }

    final TransferOverviewApiResult result = await TransferApiService.instance
        .fetchOverview(token: token, limit: 8);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() => _isLoadingOverview = false);
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess && result.overview != null) {
      setState(() {
        _walletBalance = result.overview!.walletBalance;
        _minimumAmount = result.overview!.minAmount;
        _history = _mapHistory(result.overview!.history);
        _isLoadingOverview = false;
      });
      return;
    }

    setState(() => _isLoadingOverview = false);
    if (showFailure && result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _refreshOverview() async {
    await _loadOverview(showFailure: false);
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  void _applyQuickAmount(int amount) {
    _amountController.value = TextEditingValue(
      text: amount.toString(),
      selection: TextSelection.collapsed(offset: amount.toString().length),
    );
    setState(() {
      _validatedRecipient = null;
    });
  }

  List<_TransferHistoryItem> _mapHistory(List<TransferApiHistoryItem> items) {
    return items
        .map(
          (TransferApiHistoryItem item) => _TransferHistoryItem(
            username: item.username,
            recipientName: item.recipientName,
            amount: item.amount,
            createdAt: item.createdAt ?? DateTime.now(),
            status: item.status,
          ),
        )
        .toList(growable: false);
  }

  Future<void> _validateRecipient() async {
    if (!_canValidate || _validating) {
      return;
    }

    setState(() {
      _validating = true;
      _validatedRecipient = null;
    });

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(
      context,
      text: 'Validating user...',
      color: _primary,
    );

    final String? token = await AppSessionService.instance.getApiToken();
    TransferValidateRecipientApiResult result;
    try {
      if (token == null || token.isEmpty) {
        result = const TransferValidateRecipientApiResult.unauthorized(
          'Your session has expired. Please sign in again.',
        );
      } else {
        result = await TransferApiService.instance.validateRecipient(
          token: token,
          username: _usernameController.text.trim(),
        );
      }
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() {
        _validating = false;
      });
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _validating = false;
        _validatedRecipient = result.recipientName;
      });
      return;
    }

    setState(() {
      _validating = false;
    });
    final String message =
        result.fieldErrors['username'] ??
        result.message ??
        'We could not validate this PTS DATA user.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openConfirmationSheet() async {
    if (_validatedRecipient == null) {
      return;
    }

    final bool? shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _TransferConfirmationSheet(
          username: _usernameController.text.trim(),
          recipientName: _validatedRecipient!,
          amount: _formatCurrency(_amount),
          note: _noteController.text.trim(),
        );
      },
    );

    if (!mounted || shouldContinue != true) {
      return;
    }

    await _openPinSheet();
  }

  Future<void> _openPinSheet() async {
    final AppSettings settings = await AppSettingsService.instance.load();
    if (!mounted) {
      return;
    }

    final _TransferResult? result = await showModalBottomSheet<_TransferResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !_processing,
      builder: (BuildContext context) {
        return _TransferPinSheet(
          canUseBiometric: settings.biometricUnlockEnabled,
          onSubmit: (String pin) => _submitTransfer(pin),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    await _openResultSheet(result);
  }

  Future<_TransferResult> _submitTransfer(String pin) async {
    if (_processing || pin.length != 4 || _validatedRecipient == null) {
      throw StateError('Transfer request is invalid or already processing.');
    }

    setState(() {
      _processing = true;
    });

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return _TransferResult(
        isSuccessful: false,
        username: _usernameController.text.trim(),
        recipientName: _validatedRecipient!,
        amount: _amount,
        note: _noteController.text.trim(),
        reference: '',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    final TransferSubmitApiResult result = await TransferApiService.instance
        .submitTransfer(
          token: token,
          username: _usernameController.text.trim(),
          amount: _amount,
          pin: pin,
          note: _noteController.text.trim(),
        );

    if (!mounted) {
      throw StateError('Widget was disposed during transfer.');
    }

    if (result.isUnauthorized) {
      setState(() {
        _processing = false;
      });
      await _handleUnauthorized();
      return _TransferResult(
        isSuccessful: false,
        username: _usernameController.text.trim(),
        recipientName: _validatedRecipient!,
        amount: _amount,
        note: _noteController.text.trim(),
        reference: '',
        message: 'Your session has expired. Please sign in again.',
      );
    }

    if (result.isSuccess && result.historyItem != null) {
      final _TransferHistoryItem nextItem = _TransferHistoryItem(
        username: result.historyItem!.username,
        recipientName: result.historyItem!.recipientName,
        amount: result.historyItem!.amount,
        createdAt: result.historyItem!.createdAt ?? DateTime.now(),
        status: result.historyItem!.status,
      );
      setState(() {
        _processing = false;
        _walletBalance = result.walletBalance;
        _history = <_TransferHistoryItem>[nextItem, ..._history];
      });
    } else {
      setState(() {
        _processing = false;
      });
    }

    return _TransferResult(
      isSuccessful: result.isSuccess,
      username: _usernameController.text.trim(),
      recipientName:
          result.recipientName.isNotEmpty
              ? result.recipientName
              : _validatedRecipient!,
      amount: _amount,
      note: result.note.isNotEmpty ? result.note : _noteController.text.trim(),
      reference:
          result.reference.isNotEmpty
              ? result.reference
              : 'TRF-${DateTime.now().millisecondsSinceEpoch}',
      message:
          result.fieldErrors['pin'] ??
          result.fieldErrors['amount'] ??
          result.fieldErrors['username'] ??
          result.message ??
          (result.isSuccess
              ? 'Your wallet transfer was completed successfully.'
              : 'We could not complete this transfer right now.'),
    );
  }

  Future<void> _openResultSheet(_TransferResult result) async {
    await showModalBottomSheet<_TransferResultAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _TransferResultSheet(result: result, formatter: _formatCurrency);
      },
    );

    if (!mounted) {
      return;
    }

    if (result.isSuccessful) {
      _resetForm();
      await _loadOverview(showFailure: false);
    }
  }

  void _resetForm() {
    setState(() {
      _usernameController.clear();
      _amountController.clear();
      _noteController.clear();
      _validatedRecipient = null;
    });
  }

  String _formatCurrency(num amount) {
    final bool isNegative = amount < 0;
    final String fixed = amount.abs().toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );
    return '${isNegative ? '-' : ''}\u20A6$whole.${parts.last}';
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

    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String suffix = value.hour >= 12 ? 'PM' : 'AM';
    final String minute = value.minute.toString().padLeft(2, '0');
    return '${months[value.month - 1]} ${value.day}, ${value.year}, $hour:$minute $suffix';
  }

  InputDecoration _fieldDecoration({
    required bool isDark,
    required Color mutedText,
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: isDark ? _darkPanel : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: _primary, width: 1.3),
      ),
      hintStyle: TextStyle(color: mutedText, fontSize: 12.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? _darkBackground : Colors.white;
    final Color pageSurface = isDark ? _darkSurface : Colors.white;
    final Color panelColor = isDark ? _darkPanel : const Color(0xFFF8FAFC);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
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
          'Transfer',
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
            onRefresh: _refreshOverview,
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
                          'Send money instantly to another PTS DATA user with their username and your payment PIN.',
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
                                  child: _TransferMetricTile(
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
                                  child: _TransferMetricTile(
                                    label: 'Fee',
                                    value: '\u20A60.00',
                                    isDark: isDark,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _TransferMetricTile(
                                    label: 'Speed',
                                    value: 'Instant',
                                    isDark: isDark,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'User to User Transfer',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Send money securely to another PTS DATA user using their username.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _usernameController,
                          onChanged:
                              (_) => setState(() => _validatedRecipient = null),
                          decoration: _fieldDecoration(
                            isDark: isDark,
                            mutedText: mutedText,
                            hintText: 'Recipient username',
                            prefixIcon: Icon(
                              Icons.alternate_email_rounded,
                              size: 18,
                              color: mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          onChanged:
                              (_) => setState(() => _validatedRecipient = null),
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: _fieldDecoration(
                            isDark: isDark,
                            mutedText: mutedText,
                            hintText: 'Amount',
                            prefixIcon: Icon(
                              Icons.currency_exchange_rounded,
                              size: 18,
                              color: mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              _quickAmounts.map((int amount) {
                                final bool active =
                                    _amountController.text == amount.toString();

                                return _QuickAmountButton(
                                  amountLabel: _formatCurrency(amount),
                                  selected: active,
                                  isDark: isDark,
                                  onTap: () => _applyQuickAmount(amount),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _noteController,
                          maxLines: 3,
                          decoration: _fieldDecoration(
                            isDark: isDark,
                            mutedText: mutedText,
                            hintText: 'Narration (optional)',
                            prefixIcon: Icon(
                              Icons.notes_rounded,
                              size: 18,
                              color: mutedText,
                            ),
                          ),
                        ),
                        if (_validatedRecipient != null) ...<Widget>[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF052E16)
                                      : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    isDark
                                        ? const Color(0xFF166534)
                                        : const Color(0xFF86EFAC),
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                const CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Color(0xFFDCFCE7),
                                  child: Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _validatedRecipient!,
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? const Color(0xFFF8FAFC)
                                                  : const Color(0xFF166534),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Recipient account has been confirmed for transfer.',
                                        style: TextStyle(
                                          color:
                                              isDark
                                                  ? const Color(0xFFBBF7D0)
                                                  : const Color(0xFF15803D),
                                          fontSize: 11.2,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (_amount > 0) ...<Widget>[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? _primary.withValues(alpha: 0.12)
                                      : _softTint,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color:
                                    isDark
                                        ? _primary.withValues(alpha: 0.18)
                                        : _softBorder,
                              ),
                            ),
                            child: Column(
                              children: <Widget>[
                                _TransferBreakdownRow(
                                  label: 'Recipient',
                                  value:
                                      _usernameController.text.trim().isEmpty
                                          ? 'Pending'
                                          : _usernameController.text.trim(),
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _TransferBreakdownRow(
                                  label: 'Transfer Amount',
                                  value: _formatCurrency(_amount),
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 10),
                                _TransferBreakdownRow(
                                  label: 'Transfer Fee',
                                  value: '\u20A60.00',
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                _validatedRecipient == null
                                    ? (_canValidate ? _validateRecipient : null)
                                    : _openConfirmationSheet,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _validatedRecipient == null
                                  ? (_validating
                                      ? 'Validating...'
                                      : 'Validate User')
                                  : 'Continue to Transfer',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Recent Transfers',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track the latest transfers you made to other PTS DATA users.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._history.map((_TransferHistoryItem item) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: item == _history.last ? 0 : 12,
                                  ),
                                  child: _TransferHistoryCard(
                                    item: item,
                                    isDark: isDark,
                                    formatter: _formatCurrency,
                                    dateFormatter: _formatDate,
                                  ),
                                );
                              }),
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
        selectedDestination: AppBottomNavDestination.home,
        onSelect: _handleBottomNavigation,
      ),
    );
  }
}

class _TransferMetricTile extends StatelessWidget {
  const _TransferMetricTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 12.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAmountButton extends StatelessWidget {
  const _QuickAmountButton({
    required this.amountLabel,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String amountLabel;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor:
            selected ? _primary : (isDark ? _darkPanel : Colors.white),
        foregroundColor: selected ? Colors.white : textColor,
        side: BorderSide(
          color:
              selected
                  ? Colors.transparent
                  : (isDark ? const Color(0xFF3A4054) : _softBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
      ),
      child: Text(amountLabel),
    );
  }
}

class _TransferBreakdownRow extends StatelessWidget {
  const _TransferBreakdownRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: titleColor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TransferConfirmationSheet extends StatelessWidget {
  const _TransferConfirmationSheet({
    required this.username,
    required this.recipientName,
    required this.amount,
    required this.note,
  });

  final String username;
  final String recipientName;
  final String amount;
  final String note;

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
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
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
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      'Confirm Transfer',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: mutedText),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Review this wallet transfer before entering your payment PIN.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                amount,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Username',
                      value: '@$username',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Recipient',
                      value: recipientName,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              if (note.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                _CompactSummaryTile(
                  label: 'Narration',
                  value: note,
                  isDark: isDark,
                ),
              ],
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Continue to PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSummaryTile extends StatelessWidget {
  const _CompactSummaryTile({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 11.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferPinSheet extends StatefulWidget {
  const _TransferPinSheet({
    required this.onSubmit,
    required this.canUseBiometric,
  });

  final Future<_TransferResult> Function(String pin) onSubmit;
  final bool canUseBiometric;

  @override
  State<_TransferPinSheet> createState() => _TransferPinSheetState();
}

class _TransferPinSheetState extends State<_TransferPinSheet> {
  String _pin = '';
  bool _processing = false;
  String? _errorText;

  void _appendDigit(String digit) {
    if (_processing || _pin.length >= 4) {
      return;
    }

    setState(() {
      _errorText = null;
      _pin = '$_pin$digit';
    });

    if (_pin.length == 4) {
      Future<void>.delayed(const Duration(milliseconds: 120), _submitPin);
    }
  }

  void _removeDigit() {
    if (_processing || _pin.isEmpty) {
      return;
    }

    setState(() {
      _errorText = null;
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _submitPin() async {
    if (_processing || _pin.length != 4) {
      return;
    }

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    _TransferResult? submitResult;

    setState(() {
      _processing = true;
      _errorText = null;
    });

    showPtsDataLoaderDialog<void>(
      context,
      text: 'Processing transfer...',
      color: _primary,
    );

    try {
      submitResult = await widget.onSubmit(_pin);
    } catch (_) {
      submitResult = null;
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    if (submitResult == null) {
      setState(() {
        _processing = false;
        _errorText = 'We could not complete this transfer right now.';
      });
      return;
    }

    Navigator.of(context).pop(submitResult);
  }

  Future<void> _submitBiometric() async {
    if (_processing || !widget.canUseBiometric) {
      return;
    }

    setState(() {
      _processing = true;
      _errorText = null;
    });

    final BiometricAuthResult biometricResult =
        await BiometricAuthService.instance.authenticateQuickLogin();
    if (!mounted) {
      return;
    }

    if (!biometricResult.isSuccess) {
      setState(() {
        _processing = false;
        _errorText =
            biometricResult.message ?? 'Biometric payment could not start.';
      });
      return;
    }

    final String? storedPin =
        await SecureTransactionPinService.instance.readPin();
    if (!mounted) {
      return;
    }

    if (storedPin == null || storedPin.length != 4) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
      if (!mounted) {
        return;
      }

      setState(() {
        _processing = false;
        _errorText =
            'Fingerprint payment needs to be enabled again in Settings on this device.';
      });
      return;
    }

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    _TransferResult? submitResult;

    showPtsDataLoaderDialog<void>(
      context,
      text: 'Confirming fingerprint...',
      color: _primary,
    );

    try {
      submitResult = await widget.onSubmit(storedPin);
    } catch (_) {
      submitResult = null;
    } finally {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    if (!mounted) {
      return;
    }

    if (submitResult == null) {
      setState(() {
        _processing = false;
        _errorText = 'We could not complete biometric payment right now.';
      });
      return;
    }

    Navigator.of(context).pop(submitResult);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgColor = isDark ? _darkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double maxHeight = screenHeight * 0.72;
    final bool compact = screenHeight < 700;

    return PopScope(
      canPop: !_processing,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      compact ? 10 : 12,
                      16,
                      compact ? 10 : 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Enter Payment PIN',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: compact ? 14.4 : 15.2,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed:
                                  _processing
                                      ? null
                                      : () => Navigator.of(context).pop(),
                              icon: Icon(Icons.close_rounded, color: mutedText),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 14),
                        _PinIndicatorBoxes(
                          length: _pin.length,
                          isDark: isDark,
                          boxSize: compact ? 44 : 52,
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        TextButton(
                          onPressed:
                              _processing
                                  ? null
                                  : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Payment PIN recovery is not connected yet.',
                                        ),
                                      ),
                                    );
                                  },
                          style: TextButton.styleFrom(
                            foregroundColor: mutedText,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _processing
                                ? 'Processing transfer...'
                                : 'Forgot Payment PIN?',
                            style: TextStyle(
                              fontSize: compact ? 10.5 : 10.8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (_errorText != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Text(
                            _errorText!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 11.2,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (widget.canUseBiometric) ...<Widget>[
                          SizedBox(height: compact ? 10 : 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _processing ? null : _submitBiometric,
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(42),
                                side: BorderSide(
                                  color:
                                      isDark
                                          ? const Color(0xFF374151)
                                          : const Color(0xFFE5E7EB),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              icon: Icon(
                                Icons.fingerprint_rounded,
                                color:
                                    isDark ? const Color(0xFFB89CFF) : _primary,
                                size: 18,
                              ),
                              label: Text(
                                'Use Fingerprint Instead',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: compact ? 11.2 : 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      10,
                      compact ? 8 : 10,
                      10,
                      compact ? 8 : 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF171925)
                              : const Color(0xFFF8FAFC),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.shield_rounded,
                              color: Color(0xFF16A34A),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'PTS DATA Secure Numeric Keypad',
                              style: TextStyle(
                                color: mutedText,
                                fontSize: compact ? 10.4 : 10.7,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: compact ? 8 : 10),
                        _CustomPinKeyboard(
                          isDark: isDark,
                          compact: compact,
                          onDigitTap: _processing ? null : _appendDigit,
                          onBackspace: _processing ? null : _removeDigit,
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
  }
}

class _PinIndicatorBoxes extends StatelessWidget {
  const _PinIndicatorBoxes({
    required this.length,
    required this.isDark,
    this.boxSize = 56,
  });

  final int length;
  final bool isDark;
  final double boxSize;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double resolvedSize =
            (((constraints.maxWidth - 30) / 4).clamp(42.0, boxSize)).toDouble();
        final double spacing = resolvedSize <= 46 ? 6 : 10;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(4, (int index) {
            final bool filled = index < length;
            final bool active = index == length && length < 4;

            return Padding(
              padding: EdgeInsets.only(right: index == 3 ? 0 : spacing),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: resolvedSize,
                height: resolvedSize,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF202331)
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        filled || active
                            ? _primary.withValues(alpha: filled ? 0.48 : 0.24)
                            : (isDark
                                ? const Color(0xFF3A4054)
                                : const Color(0xFFE5E7EB)),
                    width: 1.25,
                  ),
                ),
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
                    opacity: filled ? 1 : 0,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: _primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CustomPinKeyboard extends StatelessWidget {
  const _CustomPinKeyboard({
    required this.isDark,
    required this.compact,
    required this.onDigitTap,
    required this.onBackspace,
  });

  final bool isDark;
  final bool compact;
  final ValueChanged<String>? onDigitTap;
  final VoidCallback? onBackspace;

  @override
  Widget build(BuildContext context) {
    final double spacing = compact ? 6 : 8;
    final double buttonHeight = compact ? 42 : 48;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _PinKeyButton(
                label: '1',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('1'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '2',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('2'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '3',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('3'),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: <Widget>[
            Expanded(
              child: _PinKeyButton(
                label: '4',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('4'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '5',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('5'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '6',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('6'),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: <Widget>[
            Expanded(
              child: _PinKeyButton(
                label: '7',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('7'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '8',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('8'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '9',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('9'),
              ),
            ),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: <Widget>[
            Expanded(
              child: _PinKeyButton(
                isDark: isDark,
                height: buttonHeight,
                placeholder: true,
                onTap: null,
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                label: '0',
                isDark: isDark,
                height: buttonHeight,
                onTap: onDigitTap == null ? null : () => onDigitTap!('0'),
              ),
            ),
            SizedBox(width: spacing),
            Expanded(
              child: _PinKeyButton(
                icon: Icons.backspace_outlined,
                isDark: isDark,
                height: buttonHeight,
                onTap: onBackspace,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PinKeyButton extends StatelessWidget {
  const _PinKeyButton({
    this.label,
    this.icon,
    required this.isDark,
    required this.height,
    required this.onTap,
    this.placeholder = false,
  });

  final String? label;
  final IconData? icon;
  final bool isDark;
  final double height;
  final VoidCallback? onTap;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

    if (placeholder) {
      return SizedBox(height: height);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Ink(
          height: height,
          decoration: BoxDecoration(
            color: isDark ? _darkPanel : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
            ),
            boxShadow:
                isDark
                    ? null
                    : <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
          ),
          child: Center(
            child:
                icon != null
                    ? Icon(icon, color: titleColor, size: 18)
                    : Text(
                      label ?? '',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
          ),
        ),
      ),
    );
  }
}

enum _TransferResultAction { close }

class _TransferResultSheet extends StatelessWidget {
  const _TransferResultSheet({required this.result, required this.formatter});

  final _TransferResult result;
  final String Function(num amount) formatter;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? _darkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final Color statusColor =
        result.isSuccessful ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final Color accentTint =
        result.isSuccessful
            ? const Color(0xFF16A34A).withValues(alpha: isDark ? 0.16 : 0.10)
            : const Color(0xFFDC2626).withValues(alpha: isDark ? 0.18 : 0.10);
    final IconData statusIcon =
        result.isSuccessful ? Icons.check_rounded : Icons.close_rounded;
    final double sheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sheetHeight),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.20),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
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
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pop(_TransferResultAction.close),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.close_rounded, color: mutedText),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: accentTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    result.isSuccessful ? 'Successful' : 'Failed',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    Container(
                      width: 118,
                      height: 118,
                      decoration: BoxDecoration(
                        color: accentTint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.34),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(statusIcon, color: Colors.white, size: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  result.isSuccessful
                      ? 'Transfer Successful!'
                      : 'Transfer Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  result.message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 12.4,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? _darkPanel : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color:
                          isDark
                              ? const Color(0xFF3A4054)
                              : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      _ResultSummaryRow(
                        label: 'Recipient',
                        value: result.recipientName,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Username',
                        value: '@${result.username}',
                        isDark: isDark,
                      ),
                      if (result.note.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 10),
                        _ResultSummaryRow(
                          label: 'Narration',
                          value: result.note,
                          isDark: isDark,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Reference',
                        value: result.reference,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: accentTint,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                'Amount Sent',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              formatter(result.amount),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed:
                      () => Navigator.of(
                        context,
                      ).pop(_TransferResultAction.close),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultSummaryRow extends StatelessWidget {
  const _ResultSummaryRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  final String label;
  final String value;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? _darkMuted : const Color(0xFF4B5563),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _TransferHistoryCard extends StatelessWidget {
  const _TransferHistoryCard({
    required this.item,
    required this.isDark,
    required this.formatter,
    required this.dateFormatter,
  });

  final _TransferHistoryItem item;
  final bool isDark;
  final String Function(num amount) formatter;
  final String Function(DateTime value) dateFormatter;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: _primary.withValues(alpha: 0.12),
            child: const Icon(Icons.send_rounded, color: _primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.recipientName,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${item.username} • ${dateFormatter(item.createdAt)}',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatter(item.amount),
            style: const TextStyle(
              color: _primary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferHistoryItem {
  const _TransferHistoryItem({
    required this.username,
    required this.recipientName,
    required this.amount,
    required this.createdAt,
    required this.status,
  });

  final String username;
  final String recipientName;
  final double amount;
  final DateTime createdAt;
  final String status;
}

class _TransferResult {
  const _TransferResult({
    required this.isSuccessful,
    required this.username,
    required this.recipientName,
    required this.amount,
    required this.note,
    required this.reference,
    required this.message,
  });

  final bool isSuccessful;
  final String username;
  final String recipientName;
  final double amount;
  final String note;
  final String reference;
  final String message;
}
