import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../auth/data/auth_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/fingerprint_pin_sheet.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    required this.themeMode,
    required this.onThemeModeChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  AppSettings _settings = const AppSettings.defaults();
  RememberedUser? _rememberedUser;
  bool _isLoading = true;

  bool get _canUsePinUnlock => (_rememberedUser?.hasTransactionPin ?? false);

  bool get _canUseAnyQuickUnlock =>
      _settings.biometricUnlockEnabled ||
      (_settings.pinQuickUnlockEnabled && _canUsePinUnlock);

  @override
  void initState() {
    super.initState();
    _settings = _settings.copyWith(themeMode: widget.themeMode);
    _loadState();
  }

  Future<void> _loadState() async {
    final AppSettings settings = await AppSettingsService.instance.load();
    final RememberedUser? rememberedUser =
        await AppSessionService.instance.getRememberedUser();
    if (!mounted) {
      return;
    }

    setState(() {
      _settings = settings;
      _rememberedUser = rememberedUser;
      _isLoading = false;
    });
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  Future<void> _openAccountRoute(String routeName) async {
    await Navigator.of(context).pushNamed(routeName);
    if (!mounted) {
      return;
    }

    await _loadState();
  }

  Future<void> _updateThemeMode(ThemeMode mode) async {
    setState(() {
      _settings = _settings.copyWith(themeMode: mode);
    });
    widget.onThemeModeChanged(mode);
  }

  Future<void> _updateBiometricUnlock(bool value) async {
    if (!value) {
      setState(() {
        _settings = _settings.copyWith(biometricUnlockEnabled: false);
      });
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
      return;
    }

    final bool enabled = await _promptEnableFingerprint();
    if (!enabled || !mounted) {
      return;
    }

    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Fingerprint login was enabled. Test it on Android or iPhone app builds.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fingerprint login enabled.')),
      );
    }
  }

  Future<void> _updatePinUnlock(bool value) async {
    if (value && !_canUsePinUnlock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Set your transaction PIN first before enabling PIN quick unlock.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _settings = _settings.copyWith(pinQuickUnlockEnabled: value);
    });
    await AppSettingsService.instance.setPinQuickUnlockEnabled(value);
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

  Future<bool> _promptEnableFingerprint() async {
    final String? verifiedPin = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FingerprintPinSheet(onVerifyPin: _verifyPinForFingerprint);
      },
    );

    if (verifiedPin != null && verifiedPin.isNotEmpty) {
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

      setState(() {
        _settings = _settings.copyWith(biometricUnlockEnabled: true);
      });
      await AppSettingsService.instance.setBiometricUnlockEnabled(true);
      return true;
    }

    return false;
  }

  Future<void> _updateHideBalance(bool value) async {
    setState(() {
      _settings = _settings.copyWith(hideBalanceEnabled: value);
    });
    await AppSettingsService.instance.setHideBalanceEnabled(value);
  }

  Future<void> _updateTransactionAlerts(bool value) async {
    setState(() {
      _settings = _settings.copyWith(transactionAlertsEnabled: value);
    });
    await AppSettingsService.instance.setTransactionAlertsEnabled(value);
  }

  Future<void> _updateMarketingUpdates(bool value) async {
    setState(() {
      _settings = _settings.copyWith(marketingUpdatesEnabled: value);
    });
    await AppSettingsService.instance.setMarketingUpdatesEnabled(value);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return PtsDataPageScaffold(
      title: 'Settings',
      contentPadding: EdgeInsets.zero,
      selectedBottomNav: AppBottomNavDestination.me,
      onBottomNavigation: _handleBottomNavigation,
      child: Container(
        color: isDark ? ptsDataDarkBackground : const Color(0xFFF6F7FB),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
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
            _SettingsHeroCard(
              isDark: isDark,
              rememberedUser: _rememberedUser,
              canUseAnyQuickUnlock: _canUseAnyQuickUnlock,
              settings: _settings,
            ),
            const SizedBox(height: 16),
            PtsDataSectionHeader(
              title: 'Security & Login',
              subtitle: 'Choose how PTS DATA unlocks after the 1-hour lock.',
            ),
            const SizedBox(height: 10),
            _SettingsGroupCard(
              isDark: isDark,
              child: Column(
                children: <Widget>[
                  _SettingsSwitchTile(
                    title: 'Fingerprint Login',
                    subtitle: 'Use biometrics after the session locks.',
                    icon: Icons.fingerprint_rounded,
                    value: _settings.biometricUnlockEnabled,
                    isDark: isDark,
                    onChanged: _updateBiometricUnlock,
                  ),
                  _SettingsDivider(isDark: isDark),
                  _SettingsSwitchTile(
                    title: 'Quick Login with PIN',
                    subtitle:
                        _canUsePinUnlock
                            ? 'Use your 4-digit transaction PIN to unlock faster.'
                            : 'Create your transaction PIN first.',
                    icon: Icons.lock_rounded,
                    value: _settings.pinQuickUnlockEnabled && _canUsePinUnlock,
                    isDark: isDark,
                    enabled: _canUsePinUnlock,
                    onChanged: _updatePinUnlock,
                  ),
                  _SettingsDivider(isDark: isDark),
                  _InfoTile(
                    title: 'Session Lock Window',
                    subtitle:
                        'Direct access lasts 1 hour before quick unlock starts.',
                    value: '1 Hour',
                    icon: Icons.timer_outlined,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PtsDataSectionHeader(
              title: 'Account Security',
              subtitle: 'Manage the credentials used for protected actions.',
            ),
            const SizedBox(height: 10),
            _SettingsGroupCard(
              isDark: isDark,
              child: Column(
                children: <Widget>[
                  _SettingsActionTile(
                    title: 'Transaction PIN',
                    subtitle:
                        _canUsePinUnlock
                            ? 'Change the 4-digit PIN used for payments and quick unlock.'
                            : 'Create your 4-digit PIN for protected payments.',
                    icon: Icons.lock_reset_rounded,
                    value: _canUsePinUnlock ? 'Manage' : 'Create',
                    isDark: isDark,
                    onTap: () => _openAccountRoute(AppRoutes.transactionPin),
                  ),
                  _SettingsDivider(isDark: isDark),
                  _SettingsActionTile(
                    title: 'Change Password',
                    subtitle: 'Update your PTS DATA account password.',
                    icon: Icons.password_rounded,
                    value: 'Open',
                    isDark: isDark,
                    onTap: () => _openAccountRoute(AppRoutes.changePassword),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PtsDataSectionHeader(
              title: 'Appearance & Privacy',
              subtitle: 'Choose the look and default privacy of the app.',
            ),
            const SizedBox(height: 10),
            _SettingsGroupCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ThemeModeSelector(
                    isDark: isDark,
                    selectedMode: _settings.themeMode,
                    onChanged: _updateThemeMode,
                  ),
                  const SizedBox(height: 10),
                  _SettingsSwitchTile(
                    title: 'Hide Wallet Balance by Default',
                    subtitle: 'Mask your balance when the dashboard opens.',
                    icon: Icons.visibility_off_rounded,
                    value: _settings.hideBalanceEnabled,
                    isDark: isDark,
                    onChanged: _updateHideBalance,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PtsDataSectionHeader(
              title: 'Notifications',
              subtitle: 'Choose which reminders and updates you want.',
            ),
            const SizedBox(height: 10),
            _SettingsGroupCard(
              isDark: isDark,
              child: Column(
                children: <Widget>[
                  _SettingsSwitchTile(
                    title: 'Transaction Alerts',
                    subtitle: 'Get wallet, payment, and transfer alerts.',
                    icon: Icons.notifications_active_rounded,
                    value: _settings.transactionAlertsEnabled,
                    isDark: isDark,
                    onChanged: _updateTransactionAlerts,
                  ),
                  _SettingsDivider(isDark: isDark),
                  _SettingsSwitchTile(
                    title: 'Product Updates & Tips',
                    subtitle: 'Receive feature tips and service updates.',
                    icon: Icons.campaign_rounded,
                    value: _settings.marketingUpdatesEnabled,
                    isDark: isDark,
                    onChanged: _updateMarketingUpdates,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? ptsDataPrimary.withValues(alpha: 0.18)
                              : ptsDataSoftTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: ptsDataPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'How these settings work',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 13.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fingerprint and PIN quick unlock apply after the 1-hour lock window. Balance privacy is saved on this device.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 11.4,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.isDark,
    required this.rememberedUser,
    required this.canUseAnyQuickUnlock,
    required this.settings,
  });

  final bool isDark;
  final RememberedUser? rememberedUser;
  final bool canUseAnyQuickUnlock;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[ptsDataPrimary, ptsDataSecondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.settings_suggest_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Account Preferences',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 16.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      rememberedUser?.displayName ?? 'PTS DATA User',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 12.2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Manage app unlock and balance privacy preferences.',
            style: TextStyle(
              color: mutedText,
              fontSize: 11.7,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _HeroStatChip(
                  label: 'Fingerprint',
                  value: settings.biometricUnlockEnabled ? 'On' : 'Off',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStatChip(
                  label: 'PIN Unlock',
                  value:
                      settings.pinQuickUnlockEnabled &&
                              (rememberedUser?.hasTransactionPin ?? false)
                          ? 'On'
                          : 'Off',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeroStatChip(
                  label: 'Session Lock',
                  value: canUseAnyQuickUnlock ? 'Ready' : 'Manual',
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatChip extends StatelessWidget {
  const _HeroStatChip({
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
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: TextStyle(
              color: titleColor,
              fontSize: 12.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 9.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final bool isDark;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Opacity(
      opacity: enabled ? 1 : 0.65,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  isDark
                      ? ptsDataPrimary.withValues(alpha: 0.16)
                      : ptsDataSoftTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 19, color: ptsDataPrimary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: mutedText,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: enabled ? value : false,
            onChanged: enabled ? onChanged : null,
            activeColor: ptsDataPrimary,
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? ptsDataPrimary.withValues(alpha: 0.16)
                          : ptsDataSoftTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 19, color: ptsDataPrimary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    value,
                    style: TextStyle(
                      color: ptsDataPrimary,
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: ptsDataPrimary,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color:
                isDark
                    ? ptsDataPrimary.withValues(alpha: 0.16)
                    : ptsDataSoftTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 19, color: ptsDataPrimary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: titleColor,
              fontSize: 10.6,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(
        height: 1,
        thickness: 1,
        color: isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.isDark,
    required this.selectedMode,
    required this.onChanged,
  });

  final bool isDark;
  final ThemeMode selectedMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Theme Mode',
          style: TextStyle(
            color: titleColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Choose the app appearance.',
          style: TextStyle(
            color: mutedText,
            fontSize: 11.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: _ThemeChoiceChip(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                selected: selectedMode == ThemeMode.light,
                isDark: isDark,
                onTap: () => onChanged(ThemeMode.light),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ThemeChoiceChip(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                selected: selectedMode == ThemeMode.dark,
                isDark: isDark,
                onTap: () => onChanged(ThemeMode.dark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeChoiceChip extends StatelessWidget {
  const _ThemeChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        selected
            ? Colors.white
            : (isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151));

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color:
                selected
                    ? ptsDataPrimary
                    : (isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, size: 18, color: textColor),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 10.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
