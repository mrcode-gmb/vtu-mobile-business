// features/dashboard/presentation/pages/dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../auth/data/auth_api_service.dart';
import '../../data/dashboard_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../notifications/data/notification_api_service.dart';
import '../../../shared/presentation/widgets/fingerprint_pin_sheet.dart';

const Color _ptsDataPrimary = Color(0xFFB89CFF);
const Color _ptsDataPrimaryDark = Color(0xFF7FA0F5);
const Color _ptsDataSecondary = Color(0xFFC9B5FF);
const Color _ptsDataAccent = Color(0xFF7FA0F5);
const Color _ptsDataSky = Color(0xFF9AA7FF);
const Color _ptsDataTint = Color(0xFFF3F4F6);
const Color _ptsDataSoftTint = Color(0xFFF8FAFC);
const Color _ptsDataSurface = Color(0xFFFFFFFF);
const Color _ptsDataDarkBackground = Color(0xFF171925);
const Color _ptsDataDarkPanel = Color(0xFF252A42);
const Color _ptsDataDarkMuted = Color(0xFFC7CDDC);

class DashboardPage extends StatefulWidget {
  const DashboardPage({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const String _fingerprintPromptSeenKeyPrefix =
      'dashboard.fingerprint_prompt_seen.';

  static const _UserDashboardData _placeholderDashboardData =
      _UserDashboardData(
        userName: 'USER',
        walletBalance: 0,
        accountNumber: '803-785-8023',
        cashbackBalance: 12750,
        totalCashbackEarned: 38100,
        totalSales: 915400,
        successfulTransactions: 128,
        failedTransactions: 4,
        pendingTransactions: 2,
        monthlySpent: 186200,
        recentTransactions: <_DashboardRecentTransaction>[],
        virtualAccounts: <_VirtualAccount>[],
      );

  static const List<_QuickAction> _quickActions = <_QuickAction>[
    _QuickAction(
      label: 'Fund Wallet',
      icon: Icons.account_balance_rounded,
      color: _ptsDataPrimary,
    ),
    _QuickAction(
      label: 'Cashback',
      icon: Icons.savings_rounded,
      color: _ptsDataSecondary,
    ),
    _QuickAction(
      label: 'Cards',
      icon: Icons.credit_card_rounded,
      color: _ptsDataAccent,
    ),
  ];

  static const List<_ServiceItem> _services = <_ServiceItem>[
    _ServiceItem(
      label: 'Airtime',
      icon: Icons.call_rounded,
      color: _ptsDataPrimary,
    ),
    _ServiceItem(
      label: 'Data',
      icon: Icons.wifi_rounded,
      color: _ptsDataSecondary,
    ),
    _ServiceItem(
      label: 'Cable TV',
      icon: Icons.tv_rounded,
      color: _ptsDataAccent,
    ),
    _ServiceItem(
      label: 'Electricity',
      icon: Icons.bolt_rounded,
      color: _ptsDataSky,
    ),
    _ServiceItem(
      label: 'Refer & Earn',
      icon: Icons.card_giftcard_rounded,
      color: _ptsDataPrimaryDark,
    ),
    _ServiceItem(
      label: 'Transfer',
      icon: Icons.send_rounded,
      color: _ptsDataAccent,
    ),
    _ServiceItem(
      label: 'More',
      icon: Icons.grid_view_rounded,
      color: _ptsDataPrimaryDark,
    ),
  ];

  _UserDashboardData _dashboardData = _placeholderDashboardData;
  bool _balanceVisible = true;
  bool _hasTransactionPin = true;
  bool _isLoadingOverview = true;
  bool _isShowingFingerprintPrompt = false;
  int _unreadNotificationCount = 0;
  String? _copiedAccountNumber;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadSecurityState();
    _loadDashboardOverview();
    _loadUnreadNotificationCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybePromptForFingerprintSetup();
    });
  }

  Future<void> _loadPreferences() async {
    final AppSettings settings = await AppSettingsService.instance.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _balanceVisible = !settings.hideBalanceEnabled;
    });
  }

  Future<void> _loadSecurityState() async {
    final RememberedUser? rememberedUser =
        await AppSessionService.instance.getRememberedUser();
    if (!mounted) {
      return;
    }

    setState(() {
      _hasTransactionPin = rememberedUser?.hasTransactionPin ?? false;
    });
  }

  Future<void> _loadDashboardOverview() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() => _isLoadingOverview = false);
      return;
    }

    final DashboardOverviewApiResult result = await DashboardApiService.instance
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
      final DashboardOverview overview = result.overview!;
      setState(() {
        _dashboardData = _dashboardData.copyWith(
          userName: overview.userName,
          walletBalance: overview.walletBalance,
          cashbackBalance: overview.cashbackBalance,
          totalCashbackEarned: overview.totalCashbackEarned,
          monthlySpent: overview.monthlySpend,
          recentTransactions: overview.recentTransactions
              .map(_DashboardRecentTransaction.fromApi)
              .toList(growable: false),
          virtualAccounts: _mapVirtualAccounts(overview.virtualAccounts),
        );
        _isLoadingOverview = false;
      });
      return;
    }

    setState(() => _isLoadingOverview = false);
  }

  Future<void> _refreshDashboard() async {
    await Future.wait<void>(<Future<void>>[
      _loadPreferences(),
      _loadSecurityState(),
      _loadDashboardOverview(),
      _loadUnreadNotificationCount(),
    ]);
  }

  Future<void> _loadUnreadNotificationCount() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (!mounted) {
        return;
      }

      setState(() => _unreadNotificationCount = 0);
      return;
    }

    final NotificationsApiResult result = await NotificationApiService.instance
        .fetchNotifications(token: token);

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await AppSessionService.instance.clear();
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (Route<dynamic> route) => false,
      );
      return;
    }

    if (result.isSuccess) {
      setState(() => _unreadNotificationCount = result.unreadCount);
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).pushNamed(AppRoutes.notifications);
    if (!mounted) {
      return;
    }

    await _loadUnreadNotificationCount();
  }

  Future<void> _maybePromptForFingerprintSetup() async {
    if (_isShowingFingerprintPrompt || !mounted) {
      return;
    }

    final RememberedUser? rememberedUser =
        await AppSessionService.instance.getRememberedUser();
    if (rememberedUser == null || !rememberedUser.hasTransactionPin) {
      return;
    }

    final AppSettings settings = await AppSettingsService.instance.load();
    if (settings.biometricUnlockEnabled) {
      return;
    }

    final bool canUseBiometric =
        await BiometricAuthService.instance.canUseFingerprintLogin();
    if (!mounted || !canUseBiometric) {
      return;
    }

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final String promptSeenKey =
        '$_fingerprintPromptSeenKeyPrefix${rememberedUser.identifier.toLowerCase()}';
    if (preferences.getBool(promptSeenKey) ?? false) {
      return;
    }
    await preferences.setBool(promptSeenKey, true);

    if (!mounted) {
      return;
    }

    setState(() => _isShowingFingerprintPrompt = true);
    final bool? wantsFingerprint = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _FingerprintSetupPromptSheet(
          isDark: Theme.of(context).brightness == Brightness.dark,
        );
      },
    );

    if (!mounted) {
      return;
    }

    setState(() => _isShowingFingerprintPrompt = false);
    if (wantsFingerprint == true) {
      final bool enabled = await _promptEnableFingerprint();
      if (!mounted || !enabled) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fingerprint login enabled.')),
      );
    }
  }

  Future<bool> _promptEnableFingerprint() async {
    final String? verifiedPin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FingerprintPinSheet(onVerifyPin: _verifyPinForFingerprint);
      },
    );

    if (verifiedPin == null || verifiedPin.isEmpty) {
      return false;
    }

    final bool stored = await SecureTransactionPinService.instance.savePin(
      verifiedPin,
    );
    if (!stored) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Fingerprint setup could not be secured on this device. Try again.',
            ),
          ),
        );
      }
      return false;
    }

    await AppSettingsService.instance.setBiometricUnlockEnabled(true);
    return true;
  }

  Future<String?> _verifyPinForFingerprint(String pin) async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return 'Your session has expired. Please sign in again.';
    }

    final VerifyTransactionPinApiResult result = await AuthApiService.instance
        .verifyTransactionPin(token: token, pin: pin);

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return result.message ??
          'Your session has expired. Please sign in again.';
    }

    if (result.isSuccess) {
      return null;
    }

    return result.fieldErrors['pin'] ??
        result.message ??
        'We could not verify your transaction PIN right now.';
  }

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  List<_VirtualAccount> _mapVirtualAccounts(
    List<DashboardVirtualAccount> accounts,
  ) {
    const List<Color> cardColors = <Color>[
      _ptsDataPrimary,
      _ptsDataSecondary,
      Color(0xFFA78BFA),
      Color(0xFF8B5CF6),
    ];
    const List<Color> accentColors = <Color>[
      _ptsDataSoftTint,
      Color(0xFFF3E8FF),
      _ptsDataTint,
      _ptsDataSoftTint,
    ];

    return accounts
        .asMap()
        .entries
        .map((MapEntry<int, DashboardVirtualAccount> entry) {
          final int index = entry.key;
          final DashboardVirtualAccount account = entry.value;

          return _VirtualAccount(
            bankName: account.bankName,
            accountName:
                account.accountName.isNotEmpty
                    ? account.accountName.toUpperCase()
                    : 'PTS DATA ${_dashboardData.userName}',
            accountNumber: account.accountNumber,
            isActive: account.isActive,
            chargeLabel: '1% charge',
            cardColor: cardColors[index % cardColors.length],
            accentColor: accentColors[index % accentColors.length],
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        isDark ? _ptsDataDarkBackground : _ptsDataSurface;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBody: true,
      body: SafeArea(
        child: RefreshIndicator.adaptive(
          color: _ptsDataPrimary,
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              18,
              10,
              18,
              108 + MediaQuery.paddingOf(context).bottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _TopHeader(
                  isDark: isDark,
                  userName: _dashboardData.userName,
                  onSupportTap:
                      () => Navigator.of(context).pushNamed(AppRoutes.support),
                  unreadNotificationCount: _unreadNotificationCount,
                  onNotificationTap: _openNotifications,
                ),
                const SizedBox(height: 14),
                _BalanceCard(
                  isDark: isDark,
                  isLoading: _isLoadingOverview,
                  balanceVisible: _balanceVisible,
                  walletBalance: _dashboardData.walletBalance,
                  onToggleBalance: () {
                    setState(() => _balanceVisible = !_balanceVisible);
                  },
                  onAddMoneyTap:
                      () => _handleDestination(_DrawerDestination.wallet),
                  onHistoryTap:
                      () => _handleDestination(_DrawerDestination.transactions),
                ),
                const SizedBox(height: 12),
                _CompactSurface(
                  isDark: isDark,
                  child: Row(
                    children:
                        _quickActions
                            .map(
                              (_QuickAction item) => Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: item == _quickActions.last ? 0 : 8,
                                  ),
                                  child: _QuickActionTile(
                                    item: item,
                                    isDark: isDark,
                                    onTap: () {
                                      if (item.label == 'Fund Wallet') {
                                        _handleDestination(
                                          _DrawerDestination.wallet,
                                        );
                                        return;
                                      }
                                      if (item.label == 'Cashback') {
                                        Navigator.of(
                                          context,
                                        ).pushNamed(AppRoutes.cashback);
                                        return;
                                      }
                                      if (item.label == 'Cards') {
                                        Navigator.of(
                                          context,
                                        ).pushNamed(AppRoutes.cards);
                                        return;
                                      }
                                      _showPendingFeature(item.label);
                                    },
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 12),
                _FundingAccountStrip(
                  isDark: isDark,
                  isLoading: _isLoadingOverview,
                  accounts: _dashboardData.virtualAccounts,
                  copiedAccountNumber: _copiedAccountNumber,
                  onCopyAccount: _copyAccountNumber,
                ),
                const SizedBox(height: 12),
                _CompactSurface(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _InlineSectionTitle(title: 'Services', isDark: isDark),
                      const SizedBox(height: 14),
                      _ServiceGrid(
                        items: _services,
                        isDark: isDark,
                        onTap: (_ServiceItem item) {
                          if (item.label == 'Airtime') {
                            _handleDestination(_DrawerDestination.airtime);
                            return;
                          }
                          if (item.label == 'Data') {
                            _handleDestination(_DrawerDestination.data);
                            return;
                          }
                          if (item.label == 'Cable TV') {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.tvSubscription);
                            return;
                          }
                          if (item.label == 'Electricity') {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.billPayment);
                            return;
                          }
                          if (item.label == 'Refer & Earn') {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.referrals);
                            return;
                          }
                          if (item.label == 'Transfer') {
                            Navigator.of(context).pushNamed(AppRoutes.transfer);
                            return;
                          }
                          if (item.label == 'More') {
                            Navigator.of(
                              context,
                            ).pushNamed(AppRoutes.moreServices);
                            return;
                          }
                          _showPendingFeature(item.label);
                        },
                      ),
                    ],
                  ),
                ),
                if (!_hasTransactionPin) ...<Widget>[
                  const SizedBox(height: 12),
                  _TransactionPinReminderCard(
                    isDark: isDark,
                    onTap: () async {
                      await Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.transactionPin);
                      if (!mounted) {
                        return;
                      }
                      await _loadSecurityState();
                    },
                  ),
                ],
                const SizedBox(height: 12),
                _CompactSurface(
                  isDark: isDark,
                  child: _RecentActivityPreviewCard(
                    isDark: isDark,
                    items: _dashboardData.recentTransactions,
                    onTap:
                        () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.transactionHistory),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _FeatureCard(
                        isDark: isDark,
                        title: 'Cashback Hub',
                        subtitle: 'Earn as you use daily services',
                        value: _formatCurrency(_dashboardData.cashbackBalance),
                        helper:
                            'Total earned ${_formatCurrency(_dashboardData.totalCashbackEarned)}',
                        accent: _ptsDataPrimary,
                        badge: 'ACTIVE',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _FeatureCard(
                        isDark: isDark,
                        title: 'Monthly Spend',
                        subtitle: 'Track what you have spent this month',
                        value: _formatCurrency(_dashboardData.monthlySpent),
                        helper: 'Live from your wallet record',
                        accent: _ptsDataSecondary,
                        badge: 'TRACK',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        isDark: isDark,
        selectedDestination: AppBottomNavDestination.home,
        onSelect: _handleBottomNavigationSelection,
      ),
    );
  }

  Future<void> _handleBottomNavigationSelection(
    AppBottomNavDestination destination,
  ) async {
    await handleAppBottomNavigationTap(
      context,
      destination: destination,
      currentDestination: AppBottomNavDestination.home,
    );
  }

  Future<void> _handleDestination(_DrawerDestination destination) async {
    switch (destination) {
      case _DrawerDestination.home:
        return;
      case _DrawerDestination.airtime:
        await Navigator.of(context).pushNamed(AppRoutes.buyAirtime);
        return;
      case _DrawerDestination.data:
        await Navigator.of(context).pushNamed(AppRoutes.buyData);
        return;
      case _DrawerDestination.wallet:
        await Navigator.of(context).pushNamed(AppRoutes.fundWallet);
        return;
      case _DrawerDestination.transactions:
        await Navigator.of(context).pushNamed(AppRoutes.transactionHistory);
        return;
      case _DrawerDestination.transfer:
        await Navigator.of(context).pushNamed(AppRoutes.transfer);
        return;
      case _DrawerDestination.tv:
        await Navigator.of(context).pushNamed(AppRoutes.tvSubscription);
        return;
      case _DrawerDestination.bill:
        await Navigator.of(context).pushNamed(AppRoutes.billPayment);
        return;
      case _DrawerDestination.cards:
        await Navigator.of(context).pushNamed(AppRoutes.cards);
        return;
      case _DrawerDestination.rewards:
        await Navigator.of(context).pushNamed(AppRoutes.referrals);
        return;
      case _DrawerDestination.support:
        await Navigator.of(context).pushNamed(AppRoutes.support);
        return;
      case _DrawerDestination.settings:
        await Navigator.of(context).pushNamed(AppRoutes.settings);
        if (!mounted) {
          return;
        }
        await _loadPreferences();
        return;
    }
  }

  Future<void> _copyAccountNumber(String accountNumber) async {
    await Clipboard.setData(ClipboardData(text: accountNumber));
    if (!mounted) {
      return;
    }

    setState(() => _copiedAccountNumber = accountNumber);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Account number copied.')));

    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted || _copiedAccountNumber != accountNumber) {
      return;
    }

    setState(() => _copiedAccountNumber = null);
  }

  void _showPendingFeature(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label flow is not connected yet.')),
    );
  }

  static String _formatCurrency(num amount) {
    final bool isNegative = amount < 0;
    final String fixed = amount.abs().toStringAsFixed(2);
    final List<String> parts = fixed.split('.');

    return '${isNegative ? '-' : ''}\u20A6${_withThousands(parts.first)}.${parts.last}';
  }

  static String _withThousands(String value) {
    return value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );
  }

  static String _formatDashboardDate(DateTime? value) {
    if (value == null) {
      return 'Just now';
    }

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

    final int monthIndex = value.month.clamp(1, 12) - 1;
    final int hour =
        value.hour == 0 ? 12 : (value.hour > 12 ? value.hour - 12 : value.hour);
    final String minute = value.minute.toString().padLeft(2, '0');
    final String meridiem = value.hour >= 12 ? 'PM' : 'AM';

    return '${months[monthIndex]} ${value.day}, $hour:$minute $meridiem';
  }
}

class _TopHeader extends StatelessWidget {
  const _TopHeader({
    required this.isDark,
    required this.userName,
    required this.onSupportTap,
    required this.unreadNotificationCount,
    required this.onNotificationTap,
  });

  final bool isDark;
  final String userName;
  final VoidCallback onSupportTap;
  final int unreadNotificationCount;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color iconColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);

    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 18,
          backgroundColor: _ptsDataTint,
          child: Icon(
            Icons.person_rounded,
            size: 20,
            color: _ptsDataPrimaryDark,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Hi, $userName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ),
        _HeaderIconButton(
          icon: Icons.headset_mic_rounded,
          color: iconColor,
          onTap: onSupportTap,
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onNotificationTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Icon(
                  Icons.notifications_none_rounded,
                  size: 20,
                  color: iconColor,
                ),
                if (unreadNotificationCount > 0)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color:
                              isDark ? _ptsDataDarkBackground : _ptsDataSurface,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        '$unreadNotificationCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 18,
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _FingerprintSetupPromptSheet extends StatelessWidget {
  const _FingerprintSetupPromptSheet({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color sheetColor = isDark ? const Color(0xFF22263A) : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText =
        isDark ? _ptsDataDarkMuted : const Color(0xFF4B5563);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: sheetColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            18 + MediaQuery.paddingOf(context).bottom,
          ),
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
                            ? const Color(0xFF3A4054)
                            : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: _ptsDataPrimary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: _ptsDataPrimary,
                  size: 31,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Enable Fingerprint Login?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use your fingerprint to unlock PTS DATA quickly after your session locks.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 12.4,
                  fontWeight: FontWeight.w500,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: _ptsDataPrimary,
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
                icon: const Icon(Icons.fingerprint_rounded, size: 19),
                label: const Text('Enable Fingerprint'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: mutedText,
                  minimumSize: const Size.fromHeight(44),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Not now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.isDark,
    required this.isLoading,
    required this.balanceVisible,
    required this.walletBalance,
    required this.onToggleBalance,
    required this.onAddMoneyTap,
    required this.onHistoryTap,
  });

  final bool isDark;
  final bool isLoading;
  final bool balanceVisible;
  final double walletBalance;
  final VoidCallback onToggleBalance;
  final VoidCallback onAddMoneyTap;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final Color strongText =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText =
        isDark ? _ptsDataDarkMuted : const Color(0xFF4B5563);
    final Color panelColor =
        isDark ? const Color(0xFF22263A) : const Color(0xFFFFFFFF);
    final Color accentPanel =
        isDark ? _ptsDataPrimary.withValues(alpha: 0.16) : _ptsDataSoftTint;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool isCompact = constraints.maxWidth < 410;

        return Container(
          clipBehavior: Clip.antiAlias,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            color: panelColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(
                  0xFF111827,
                ).withValues(alpha: isDark ? 0.20 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: <Widget>[
              Positioned(
                right: -44,
                top: -52,
                child: Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    color: _ptsDataPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 24,
                bottom: -42,
                child: Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    color: _ptsDataSecondary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentPanel,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: _ptsDataPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'PTS Wallet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: strongText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Main spending account',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: onToggleBalance,
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark
                                      ? const Color(0xFF252A42)
                                      : const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color:
                                    isDark
                                        ? const Color(0xFF3A4054)
                                        : _ptsDataTint,
                              ),
                            ),
                            child: Icon(
                              balanceVisible
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              size: 17,
                              color: mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Wallet balance',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    isLoading
                        ? Row(
                          children: <Widget>[
                            SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: strongText,
                              ),
                            ),
                            const SizedBox(width: 9),
                            Text(
                              'Loading wallet...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: mutedText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                        : Text(
                          balanceVisible
                              ? _DashboardPageState._formatCurrency(
                                walletBalance,
                              )
                              : '\u20A6****',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: strongText,
                            fontSize: isCompact ? 26 : 29,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _WalletActionPill(
                            label: 'Fund wallet',
                            icon: Icons.add_rounded,
                            primary: true,
                            isDark: isDark,
                            onTap: onAddMoneyTap,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _WalletActionPill(
                            label: 'History',
                            icon: Icons.receipt_long_rounded,
                            primary: false,
                            isDark: isDark,
                            onTap: onHistoryTap,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WalletActionPill extends StatelessWidget {
  const _WalletActionPill({
    required this.label,
    required this.icon,
    required this.primary,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool primary;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor =
        primary
            ? _ptsDataPrimary
            : (isDark ? const Color(0xFF252A42) : const Color(0xFFF3F4F6));
    final Color foregroundColor =
        primary
            ? Colors.white
            : (isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border:
                primary
                    ? null
                    : Border.all(
                      color: isDark ? const Color(0xFF3A4054) : _ptsDataTint,
                    ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: foregroundColor, size: 17),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FundingAccountStrip extends StatelessWidget {
  const _FundingAccountStrip({
    required this.isDark,
    required this.isLoading,
    required this.accounts,
    required this.copiedAccountNumber,
    required this.onCopyAccount,
  });

  final bool isDark;
  final bool isLoading;
  final List<_VirtualAccount> accounts;
  final String? copiedAccountNumber;
  final ValueChanged<String> onCopyAccount;

  @override
  Widget build(BuildContext context) {
    final Color surface = isDark ? _ptsDataDarkPanel : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText =
        isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563);

    if (isLoading) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (accounts.isEmpty) {
      return Container(
        height: 100,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Funding Accounts',
              style: TextStyle(
                color: titleColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              'No active bank accounts were found for this wallet yet.',
              style: TextStyle(
                color: mutedText,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    final List<_VirtualAccount> visibleAccounts = accounts.reversed.toList(
      growable: false,
    );

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: visibleAccounts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (BuildContext context, int index) {
          final _VirtualAccount account = visibleAccounts[index];

          return _FundingAccountCard(
            account: account,
            isDark: isDark,
            copied: copiedAccountNumber == account.accountNumber,
            onCopy: () => onCopyAccount(account.accountNumber),
          );
        },
      ),
    );
  }
}

class _TransactionPinReminderCard extends StatelessWidget {
  const _TransactionPinReminderCard({
    required this.isDark,
    required this.onTap,
  });

  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText =
        isDark ? _ptsDataDarkMuted : const Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            color:
                isDark
                    ? _ptsDataPrimary.withValues(alpha: 0.10)
                    : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  isDark
                      ? _ptsDataPrimary.withValues(alpha: 0.28)
                      : const Color(0xFFD1D5DB),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? _ptsDataPrimary.withValues(alpha: 0.18)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: _ptsDataPrimary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Create your transaction PIN',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 12.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set your 4-digit PIN to protect airtime, data, bills, and transfers.',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: _ptsDataPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Create PIN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _CompactSurface extends StatelessWidget {
  const _CompactSurface({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202331) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(
              0xFF111827,
            ).withValues(alpha: isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final _QuickAction item;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        isDark ? const Color(0xFFF4F6FB) : const Color(0xFF111827);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF202331) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 17, color: item.color),
              ),
              const SizedBox(height: 8),
              Text(
                item.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineSectionTitle extends StatelessWidget {
  const _InlineSectionTitle({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ServiceGrid extends StatelessWidget {
  const _ServiceGrid({
    required this.items,
    required this.isDark,
    required this.onTap,
  });

  final List<_ServiceItem> items;
  final bool isDark;
  final ValueChanged<_ServiceItem> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _ServiceItem item = items[index];

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(item),
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, size: 16, color: item.color),
                ),
                const SizedBox(height: 8),
                Text(
                  item.label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color:
                        isDark
                            ? const Color(0xFFF4F6FB)
                            : const Color(0xFF111827),
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RecentActivityPreviewCard extends StatelessWidget {
  const _RecentActivityPreviewCard({
    required this.isDark,
    required this.items,
    required this.onTap,
  });

  final bool isDark;
  final List<_DashboardRecentTransaction> items;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF252A42);
    final Color mutedText =
        isDark ? _ptsDataDarkMuted : const Color(0xFF6B7280);
    final List<_DashboardRecentTransaction> previewItems = items
        .take(2)
        .toList(growable: false);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ptsDataTint,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 22,
                  color: _ptsDataPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Recent Activity',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      previewItems.isEmpty
                          ? 'Your latest transactions will appear here.'
                          : 'Your latest 2 records at a glance.',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 10.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _ptsDataPrimary,
                  side: const BorderSide(color: _ptsDataPrimary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  minimumSize: const Size(0, 34),
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('View all'),
              ),
            ],
          ),
          if (previewItems.isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            ...previewItems.map(
              (_DashboardRecentTransaction item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecentActivityRow(isDark: isDark, item: item),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.isDark, required this.item});

  final bool isDark;
  final _DashboardRecentTransaction item;

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = item.status == 'successful';
    final bool isFailed = item.status == 'failed';
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF252A42);
    final Color mutedText =
        isDark ? _ptsDataDarkMuted : const Color(0xFF6B7280);
    final Color amountColor =
        isFailed
            ? const Color(0xFFEF4444)
            : (isSuccess ? _ptsDataPrimary : const Color(0xFFF59E0B));
    final Color rowColor = isDark ? _ptsDataDarkPanel : const Color(0xFFF8FAFC);

    final IconData leadingIcon = switch (item.type) {
      'airtime' => Icons.call_rounded,
      'data' => Icons.wifi_rounded,
      'cable' => Icons.tv_rounded,
      'electricity' => Icons.bolt_rounded,
      'funding' => Icons.account_balance_wallet_rounded,
      'transfer' => Icons.send_rounded,
      _ => Icons.receipt_long_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rowColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _ptsDataPrimary.withValues(alpha: isDark ? 0.18 : 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(leadingIcon, size: 18, color: _ptsDataPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _DashboardPageState._formatDashboardDate(item.date),
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                '${item.direction == 'incoming' ? '+' : ''}${_DashboardPageState._formatCurrency(item.amount)}',
                style: TextStyle(
                  color: amountColor,
                  fontSize: 11.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.statusLabel,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 9.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.helper,
    required this.accent,
    required this.badge,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final String value;
  final String helper;
  final Color accent;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? _ptsDataDarkPanel : _ptsDataSoftTint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: accent,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : _ptsDataPrimaryDark,
              fontSize: 11.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? _ptsDataDarkMuted : const Color(0xFF4B5563),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            style: TextStyle(
              color: isDark ? _ptsDataDarkMuted : const Color(0xFF6B7280),
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FundingAccountCard extends StatelessWidget {
  const _FundingAccountCard({
    required this.account,
    required this.isDark,
    required this.copied,
    required this.onCopy,
  });

  final _VirtualAccount account;
  final bool isDark;
  final bool copied;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 270,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: account.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: account.cardColor.withValues(alpha: isDark ? 0.32 : 0.24),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  account.accountNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onCopy,
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    copied ? Icons.check_rounded : Icons.copy_rounded,
                    size: 15,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (account.chargeLabel.isNotEmpty)
                Text(
                  account.chargeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'ACCOUNT NAMES',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 9.6,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  account.accountName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                account.bankName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserDashboardData {
  const _UserDashboardData({
    required this.userName,
    required this.walletBalance,
    required this.accountNumber,
    required this.cashbackBalance,
    required this.totalCashbackEarned,
    required this.totalSales,
    required this.successfulTransactions,
    required this.failedTransactions,
    required this.pendingTransactions,
    required this.monthlySpent,
    required this.recentTransactions,
    required this.virtualAccounts,
  });

  final String userName;
  final double walletBalance;
  final String accountNumber;
  final double cashbackBalance;
  final double totalCashbackEarned;
  final double totalSales;
  final int successfulTransactions;
  final int failedTransactions;
  final int pendingTransactions;
  final double monthlySpent;
  final List<_DashboardRecentTransaction> recentTransactions;
  final List<_VirtualAccount> virtualAccounts;

  _UserDashboardData copyWith({
    String? userName,
    double? walletBalance,
    String? accountNumber,
    double? cashbackBalance,
    double? totalCashbackEarned,
    double? totalSales,
    int? successfulTransactions,
    int? failedTransactions,
    int? pendingTransactions,
    double? monthlySpent,
    List<_DashboardRecentTransaction>? recentTransactions,
    List<_VirtualAccount>? virtualAccounts,
  }) {
    return _UserDashboardData(
      userName: userName ?? this.userName,
      walletBalance: walletBalance ?? this.walletBalance,
      accountNumber: accountNumber ?? this.accountNumber,
      cashbackBalance: cashbackBalance ?? this.cashbackBalance,
      totalCashbackEarned: totalCashbackEarned ?? this.totalCashbackEarned,
      totalSales: totalSales ?? this.totalSales,
      successfulTransactions:
          successfulTransactions ?? this.successfulTransactions,
      failedTransactions: failedTransactions ?? this.failedTransactions,
      pendingTransactions: pendingTransactions ?? this.pendingTransactions,
      monthlySpent: monthlySpent ?? this.monthlySpent,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      virtualAccounts: virtualAccounts ?? this.virtualAccounts,
    );
  }
}

class _DashboardRecentTransaction {
  const _DashboardRecentTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.status,
    required this.direction,
    required this.description,
    required this.reference,
    this.date,
  });

  factory _DashboardRecentTransaction.fromApi(
    DashboardRecentTransaction transaction,
  ) {
    return _DashboardRecentTransaction(
      id: transaction.id,
      type: transaction.type,
      amount: transaction.amount,
      status: transaction.status,
      direction: transaction.direction,
      description: transaction.description,
      reference: transaction.reference,
      date: transaction.date,
    );
  }

  final String id;
  final String type;
  final double amount;
  final String status;
  final String direction;
  final String description;
  final String reference;
  final DateTime? date;

  String get statusLabel {
    switch (status) {
      case 'successful':
        return 'Successful';
      case 'failed':
        return 'Failed';
      case 'pending':
        return 'Pending';
      default:
        return status.isEmpty
            ? 'Processing'
            : '${status[0].toUpperCase()}${status.substring(1)}';
    }
  }
}

class _VirtualAccount {
  const _VirtualAccount({
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
    required this.isActive,
    required this.chargeLabel,
    required this.cardColor,
    required this.accentColor,
  });

  final String bankName;
  final String accountName;
  final String accountNumber;
  final bool isActive;
  final String chargeLabel;
  final Color cardColor;
  final Color accentColor;
}

class _QuickAction {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

class _ServiceItem {
  const _ServiceItem({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;
}

enum _DrawerDestination {
  home,
  airtime,
  data,
  wallet,
  transactions,
  transfer,
  tv,
  bill,
  cards,
  rewards,
  support,
  settings,
}
