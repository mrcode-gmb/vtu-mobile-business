import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../data/cashback_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class CashbackPage extends StatefulWidget {
  const CashbackPage({super.key});

  @override
  State<CashbackPage> createState() => _CashbackPageState();
}

class _CashbackPageState extends State<CashbackPage> {
  static const List<int> _quickAmounts = <int>[1000, 2500, 5000, 10000];
  static const List<_CashbackRule> _rules = <_CashbackRule>[
    _CashbackRule(
      title: 'Earn on every qualifying data purchase',
      subtitle:
          'Small data buys still credit your cashback wallet automatically.',
      icon: Icons.bolt_rounded,
    ),
    _CashbackRule(
      title: 'Convert anytime',
      subtitle:
          'Move cashback into your main wallet without waiting for settlement.',
      icon: Icons.currency_exchange_rounded,
    ),
    _CashbackRule(
      title: 'Rewards do not expire',
      subtitle:
          'You can keep building your cashback balance as long as you use the app.',
      icon: Icons.workspace_premium_rounded,
    ),
  ];

  final TextEditingController _amountController = TextEditingController();

  List<_CashbackActivity> _activities = <_CashbackActivity>[];
  double _availableCashback = 0;
  double _walletBalance = 0;
  double _totalEarned = 0;
  double _totalConverted = 0;
  bool _isLoading = true;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _loadCashbackOverview();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _enteredAmount =>
      double.tryParse(_amountController.text.trim()) ?? 0;

  bool get _canContinue =>
      _enteredAmount > 0 && _enteredAmount <= _availableCashback;

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  Future<void> _loadCashbackOverview() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    final CashbackOverviewApiResult result = await CashbackApiService.instance
        .fetchOverview(token: token);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess && result.overview != null) {
      setState(() {
        _applyOverview(result.overview!);
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = false);
    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _refreshCashbackOverview() async {
    await _loadCashbackOverview();
  }

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = false;
      _processing = false;
    });
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  void _applyOverview(CashbackOverview overview) {
    _availableCashback = overview.balance;
    _walletBalance = overview.walletBalance;
    _totalEarned = overview.totalEarned;
    _totalConverted = overview.totalConverted;
    _activities = overview.recentTransactions
        .map(_CashbackActivity.fromApi)
        .toList(growable: false);

    final double enteredAmount = _enteredAmount;
    if (enteredAmount > _availableCashback) {
      _amountController.clear();
    }
  }

  void _applyQuickAmount(int amount) {
    final int resolved =
        amount > _availableCashback ? _availableCashback.floor() : amount;
    final String value = resolved.toString();
    _amountController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
    setState(() {});
  }

  Future<void> _openConfirmationSheet() async {
    if (!_canContinue) {
      return;
    }

    final bool? shouldContinue = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _CashbackConfirmationSheet(
          amount: _formatCurrency(_enteredAmount),
          availableBalance: _formatCurrency(_availableCashback),
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

    final _CashbackResult? result = await showModalBottomSheet<_CashbackResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: !_processing,
      builder: (BuildContext context) {
        return _CashbackPinSheet(
          canUseBiometric: settings.biometricUnlockEnabled,
          onSubmit: (String pin) => _submitConversion(pin),
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    await _openResultSheet(result);
  }

  Future<_CashbackResult> _submitConversion(String pin) async {
    final double amount = _enteredAmount;
    if (_processing ||
        pin.length != 4 ||
        amount <= 0 ||
        amount > _availableCashback) {
      throw StateError('Cashback conversion is invalid or already processing.');
    }

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      throw StateError('Your session has expired.');
    }

    setState(() {
      _processing = true;
    });

    final CashbackConvertApiResult response = await CashbackApiService.instance
        .convertToWallet(token: token, amount: amount, pin: pin);
    if (!mounted) {
      throw StateError('Widget was disposed during cashback conversion.');
    }

    if (response.isUnauthorized) {
      await _handleUnauthorized();
      throw StateError('Your session has expired.');
    }

    setState(() {
      if (response.isSuccess && response.overview != null) {
        _applyOverview(response.overview!);
      }
      _processing = false;
    });

    return _CashbackResult(
      isSuccessful: response.isSuccess,
      amount: response.convertedAmount ?? amount,
      availableBalance: _availableCashback,
      reference:
          response.reference?.isNotEmpty == true
              ? response.reference!
              : 'Pending',
      message:
          response.message ??
          'We could not convert this cashback right now. Please try again.',
    );
  }

  Future<void> _openResultSheet(_CashbackResult result) async {
    final _CashbackResultAction? action =
        await showModalBottomSheet<_CashbackResultAction>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (BuildContext context) {
            return _CashbackResultSheet(
              result: result,
              formatter: _formatCurrency,
            );
          },
        );

    if (!mounted) {
      return;
    }

    if (result.isSuccessful) {
      _amountController.clear();
      setState(() {});
      return;
    }

    if (action == _CashbackResultAction.retry) {
      await _openConfirmationSheet();
    }
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

    final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final String suffix = value.hour >= 12 ? 'PM' : 'AM';
    final String minute = value.minute.toString().padLeft(2, '0');
    return '${months[value.month - 1]} ${value.day}, ${value.year}, $hour:$minute $suffix';
  }

  InputDecoration _fieldDecoration({
    required bool isDark,
    required Color mutedText,
    required String hintText,
    String? prefixText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      prefixStyle: TextStyle(
        color: mutedText,
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
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
          'Cashback',
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double bottomPadding =
              112 + MediaQuery.paddingOf(context).bottom;

          return RefreshIndicator.adaptive(
            color: _primary,
            onRefresh: _refreshCashbackOverview,
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
                        if (_isLoading) ...<Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(minHeight: 4),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'Track every reward, convert cashback to wallet balance, and keep your reward history in one clean view.',
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
                                (constraints.maxWidth - 8) / 2;

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                SizedBox(
                                  width: itemWidth,
                                  child: _CashbackMetricTile(
                                    label: 'Cashback Balance',
                                    value: _formatCurrency(_availableCashback),
                                    isDark: isDark,
                                    accent: _primary,
                                    icon: Icons.card_giftcard_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _CashbackMetricTile(
                                    label: 'Total Earned',
                                    value: _formatCurrency(_totalEarned),
                                    isDark: isDark,
                                    accent: const Color(0xFF16A34A),
                                    icon: Icons.trending_up_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _CashbackMetricTile(
                                    label: 'Converted',
                                    value: _formatCurrency(_totalConverted),
                                    isDark: isDark,
                                    accent: const Color(0xFF7FA0F5),
                                    icon: Icons.account_balance_wallet_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _CashbackMetricTile(
                                    label: 'Wallet Balance',
                                    value: _formatCurrency(_walletBalance),
                                    isDark: isDark,
                                    accent: const Color(0xFFF59E0B),
                                    icon: Icons.account_balance_wallet_outlined,
                                  ),
                                ),
                              ],
                            );
                          },
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
                                'Available Cashback',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Earn \u20A65 below \u20A6300 data purchases and \u20A610 from \u20A6300 upward, then convert it to wallet whenever you want.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _formatCurrency(_availableCashback),
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setState(() {}),
                                decoration: _fieldDecoration(
                                  isDark: isDark,
                                  mutedText: mutedText,
                                  hintText: '1000',
                                  prefixText: '\u20A6 ',
                                  prefixIcon: Icon(
                                    Icons.wallet_rounded,
                                    size: 18,
                                    color: mutedText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Available to convert: ${_formatCurrency(_availableCashback)}',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                    children:
                                        _quickAmounts
                                            .map(
                                              (int amount) => SizedBox(
                                                width: itemWidth,
                                                child: _QuickAmountButton(
                                                  amountLabel: '\u20A6$amount',
                                                  isDark: isDark,
                                                  selected:
                                                      _enteredAmount == amount,
                                                  onTap:
                                                      () => _applyQuickAmount(
                                                        amount,
                                                      ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed:
                                    _canContinue
                                        ? _openConfirmationSheet
                                        : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: _primary,
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 12.8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 18,
                                ),
                                label: const Text('Convert to Wallet'),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'How Cashback Works',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cashback is earned automatically on eligible services and can be converted any time.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._rules.map((_CashbackRule rule) {
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom: rule == _rules.last ? 0 : 12,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: _primary.withValues(
                                          alpha: 0.12,
                                        ),
                                        child: Icon(
                                          rule.icon,
                                          size: 18,
                                          color: _primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              rule.title,
                                              style: TextStyle(
                                                color: titleColor,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              rule.subtitle,
                                              style: TextStyle(
                                                color: mutedText,
                                                fontSize: 11.2,
                                                fontWeight: FontWeight.w500,
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Recent Activity',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Every cashback credit and conversion is recorded here.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_activities.isEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isDark
                                            ? _darkSurface
                                            : const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color:
                                          isDark
                                              ? const Color(0xFF3A4054)
                                              : _softBorder,
                                    ),
                                  ),
                                  child: Text(
                                    'No cashback activity yet. Start using PTS DATA services to earn rewards.',
                                    style: TextStyle(
                                      color: mutedText,
                                      fontSize: 11.2,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                )
                              else
                                ..._activities.map((_CashbackActivity item) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom: item == _activities.last ? 0 : 12,
                                    ),
                                    child: _CashbackActivityCard(
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

class _CashbackMetricTile extends StatelessWidget {
  const _CashbackMetricTile({
    required this.label,
    required this.value,
    required this.isDark,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final bool isDark;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedText,
              fontSize: 10.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
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
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final String amountLabel;
  final bool isDark;
  final bool selected;
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
        textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      child: Text(amountLabel),
    );
  }
}

class _CashbackConfirmationSheet extends StatelessWidget {
  const _CashbackConfirmationSheet({
    required this.amount,
    required this.availableBalance,
  });

  final String amount;
  final String availableBalance;

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
                      'Convert Cashback',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
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
                'Review this cashback conversion before entering your payment PIN.',
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
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Source',
                      value: 'Cashback Wallet',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _CompactSummaryTile(
                      label: 'Destination',
                      value: 'Main Wallet',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _CompactSummaryTile(
                label: 'Available',
                value: availableBalance,
                isDark: isDark,
              ),
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
                    fontWeight: FontWeight.w800,
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashbackPinSheet extends StatefulWidget {
  const _CashbackPinSheet({
    required this.onSubmit,
    required this.canUseBiometric,
  });

  final Future<_CashbackResult> Function(String pin) onSubmit;
  final bool canUseBiometric;

  @override
  State<_CashbackPinSheet> createState() => _CashbackPinSheetState();
}

class _CashbackPinSheetState extends State<_CashbackPinSheet> {
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
    _CashbackResult? submitResult;

    setState(() {
      _processing = true;
      _errorText = null;
    });

    showPtsDataLoaderDialog<void>(
      context,
      text: 'Converting cashback...',
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
        _errorText =
            'We could not complete this cashback conversion right now.';
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
    _CashbackResult? submitResult;

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
                                ? 'Converting cashback...'
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
                                fontWeight: FontWeight.w700,
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

enum _CashbackResultAction { close, retry }

class _CashbackResultSheet extends StatelessWidget {
  const _CashbackResultSheet({required this.result, required this.formatter});

  final _CashbackResult result;
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
    final Widget actionSection =
        result.isSuccessful
            ? FilledButton.icon(
              onPressed:
                  () => Navigator.of(context).pop(_CashbackResultAction.close),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Done'),
            )
            : Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pop(_CashbackResultAction.close),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: titleColor,
                      side: BorderSide(
                        color:
                            isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFC7CDDC),
                      ),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed:
                        () => Navigator.of(
                          context,
                        ).pop(_CashbackResultAction.retry),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Again'),
                  ),
                ),
              ],
            );

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
                        ).pop(_CashbackResultAction.close),
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
                      fontWeight: FontWeight.w800,
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
                      ? 'Conversion Successful!'
                      : 'Conversion Failed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
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
                        label: 'Source',
                        value: 'Cashback Wallet',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Destination',
                        value: 'Main Wallet',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Reference',
                        value: result.reference,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 10),
                      _ResultSummaryRow(
                        label: 'Balance Left',
                        value: formatter(result.availableBalance),
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
                                'Converted Amount',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              formatter(result.amount),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                actionSection,
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
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _CashbackActivityCard extends StatelessWidget {
  const _CashbackActivityCard({
    required this.item,
    required this.isDark,
    required this.formatter,
    required this.dateFormatter,
  });

  final _CashbackActivity item;
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
            backgroundColor: item.type.color.withValues(alpha: 0.12),
            child: Icon(item.type.icon, color: item.type.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.subtitle} - ${dateFormatter(item.createdAt)}',
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
            '${item.type.prefix}${formatter(item.amount)}',
            style: TextStyle(
              color: item.type.color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CashbackRule {
  const _CashbackRule({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

enum _CashbackType {
  earned(
    icon: Icons.trending_up_rounded,
    color: Color(0xFF16A34A),
    prefix: '+',
  ),
  converted(
    icon: Icons.account_balance_wallet_rounded,
    color: _primary,
    prefix: '-',
  ),
  bonus(
    icon: Icons.workspace_premium_rounded,
    color: Color(0xFFF59E0B),
    prefix: '+',
  );

  const _CashbackType({
    required this.icon,
    required this.color,
    required this.prefix,
  });

  final IconData icon;
  final Color color;
  final String prefix;

  static _CashbackType fromApi(String value) {
    switch (value.toLowerCase()) {
      case 'converted':
        return _CashbackType.converted;
      case 'bonus':
        return _CashbackType.bonus;
      case 'earned':
      default:
        return _CashbackType.earned;
    }
  }

  static String titleForApi(_CashbackType type) {
    switch (type) {
      case _CashbackType.converted:
        return 'Cashback converted';
      case _CashbackType.bonus:
        return 'Cashback bonus';
      case _CashbackType.earned:
        return 'Cashback earned';
    }
  }
}

class _CashbackActivity {
  const _CashbackActivity({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  factory _CashbackActivity.fromApi(CashbackApiTransaction transaction) {
    final _CashbackType type = _CashbackType.fromApi(transaction.type);
    final String transactionType = transaction.transactionType.trim();
    final String description = transaction.description.trim();

    return _CashbackActivity(
      title: _CashbackType.titleForApi(type),
      subtitle:
          description.isNotEmpty
              ? description
              : (transactionType.isNotEmpty
                  ? transactionType
                  : 'Cashback activity'),
      amount: transaction.amount,
      type: type,
      createdAt: transaction.createdAt ?? DateTime.now(),
    );
  }

  final String title;
  final String subtitle;
  final double amount;
  final _CashbackType type;
  final DateTime createdAt;
}

class _CashbackResult {
  const _CashbackResult({
    required this.isSuccessful,
    required this.amount,
    required this.availableBalance,
    required this.reference,
    required this.message,
  });

  final bool isSuccessful;
  final double amount;
  final double availableBalance;
  final String reference;
  final String message;
}
