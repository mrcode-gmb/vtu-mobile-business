import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/biometric_auth_service.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../core/auth/secure_transaction_pin_service.dart';
import '../../../../core/settings/app_settings_service.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../data/auth_api_service.dart';

class QuickLoginPage extends StatefulWidget {
  const QuickLoginPage({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<QuickLoginPage> createState() => _QuickLoginPageState();
}

class _QuickLoginPageState extends State<QuickLoginPage> {
  static const int _pinLength = 4;

  final List<String> _digits = <String>[];
  RememberedUser? _rememberedUser;
  AppSettings _settings = const AppSettings.defaults();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    final RememberedUser? rememberedUser =
        await AppSessionService.instance.getRememberedUser();
    final AppSettings settings = await AppSettingsService.instance.load();
    if (!mounted) {
      return;
    }

    setState(() {
      _rememberedUser = rememberedUser;
      _settings = settings;
    });
  }

  Future<void> _submitPin() async {
    if (_digits.length != _pinLength || _isSubmitting) {
      return;
    }

    final RememberedUser? rememberedUser = _rememberedUser;
    if (rememberedUser == null) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    if (!_settings.pinQuickUnlockEnabled) {
      setState(() {
        _digits.clear();
        _errorText = 'PIN quick login is turned off in Settings.';
      });
      return;
    }

    if (!rememberedUser.hasTransactionPin) {
      setState(() {
        _digits.clear();
        _errorText =
            'Set your transaction PIN on the dashboard before using quick login.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(context, text: 'Unlocking your account...');

    late final QuickUnlockApiResult result;
    try {
      result = await AuthApiService.instance.quickUnlock(
        identifier: rememberedUser.identifier,
        pin: _digits.join(),
      );
    } finally {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!result.isSuccess) {
      setState(() {
        _digits.clear();
        _errorText =
            result.fieldErrors['pin'] ??
            result.message ??
            'We could not unlock your account right now.';
      });
      return;
    }

    await AppSessionService.instance.recordQuickUnlock(
      displayName: result.session!.displayName,
      identifier: result.session!.identifier,
      apiToken: result.session!.token,
      hasTransactionPin: result.session!.hasTransactionPin,
    );

    if (!mounted) {
      return;
    }

    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  void _appendDigit(String digit) {
    if (_digits.length >= _pinLength || _isSubmitting) {
      return;
    }

    if (!_settings.pinQuickUnlockEnabled) {
      setState(() {
        _errorText = 'PIN quick login is turned off in Settings.';
      });
      return;
    }

    if (_rememberedUser != null && !_rememberedUser!.hasTransactionPin) {
      setState(() {
        _errorText =
            'Set your transaction PIN on the dashboard before using quick login.';
      });
      return;
    }

    setState(() {
      _errorText = null;
      _digits.add(digit);
    });

    if (_digits.length == _pinLength) {
      _submitPin();
    }
  }

  void _removeDigit() {
    if (_digits.isEmpty || _isSubmitting) {
      return;
    }

    setState(() {
      _errorText = null;
      _digits.removeLast();
    });
  }

  Future<void> _useBiometric() async {
    if (_isSubmitting) {
      return;
    }

    if (!_settings.biometricUnlockEnabled) {
      setState(() {
        _errorText = 'Fingerprint login is turned off in Settings.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    final BiometricAuthResult biometricResult =
        await BiometricAuthService.instance.authenticateQuickLogin();
    if (!mounted) {
      return;
    }

    if (!biometricResult.isSuccess) {
      setState(() {
        _isSubmitting = false;
        _errorText = biometricResult.message;
      });
      return;
    }

    final RememberedUser? rememberedUser = _rememberedUser;
    if (rememberedUser == null) {
      setState(() => _isSubmitting = false);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    final String? savedPin =
        await SecureTransactionPinService.instance.readPin();
    if (!mounted) {
      return;
    }

    if (savedPin == null || savedPin.length != _pinLength) {
      await AppSettingsService.instance.setBiometricUnlockEnabled(false);
      await SecureTransactionPinService.instance.clearPin();
      setState(() {
        _isSubmitting = false;
        _settings = _settings.copyWith(biometricUnlockEnabled: false);
        _errorText =
            'Fingerprint login needs to be enabled again in Settings on this device.';
      });
      return;
    }

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(context, text: 'Unlocking your account...');

    late final QuickUnlockApiResult result;
    try {
      result = await AuthApiService.instance.quickUnlock(
        identifier: rememberedUser.identifier,
        pin: savedPin,
      );
    } finally {
      if (rootNavigator.canPop()) {
        rootNavigator.pop();
      }
    }

    if (!mounted) {
      return;
    }

    if (!result.isSuccess) {
      if (result.fieldErrors['pin'] != null) {
        await AppSettingsService.instance.setBiometricUnlockEnabled(false);
        await SecureTransactionPinService.instance.clearPin();
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        if (result.fieldErrors['pin'] != null) {
          _settings = _settings.copyWith(biometricUnlockEnabled: false);
        }
        _errorText =
            result.fieldErrors['pin'] != null
                ? 'Your fingerprint login PIN is out of date. Sign in with PIN and enable fingerprint again in Settings.'
                : (result.message ??
                    'We could not unlock your account right now.');
      });
      return;
    }

    await AppSessionService.instance.recordQuickUnlock(
      displayName: result.session!.displayName,
      identifier: result.session!.identifier,
      apiToken: result.session!.token,
      hasTransactionPin: result.session!.hasTransactionPin,
    );

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  Future<void> _switchAccount() async {
    if (_isSubmitting) {
      return;
    }

    await SecureTransactionPinService.instance.clearPin();
    await AppSessionService.instance.signOut();
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.welcome,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        isDark ? const Color(0xFF171925) : Colors.white;
    final Color surfaceColor =
        isDark ? const Color(0xFF22263A) : const Color(0xFFF8FAFC);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color subtitleColor =
        isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563);
    final Color accentSurface =
        isDark ? const Color(0x1A7FA0F5) : const Color(0xFFF9FAFB);

    final RememberedUser user =
        _rememberedUser ??
        const RememberedUser(
          displayName: 'ABUBAKAR',
          identifier: 'ptsdata@wallet.ng',
          hasTransactionPin: true,
        );
    final bool canUseTransactionPin =
        user.hasTransactionPin && _settings.pinQuickUnlockEnabled;
    final bool canUseBiometric = _settings.biometricUnlockEnabled;
    final bool hasAnyQuickUnlock = canUseTransactionPin || canUseBiometric;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxHeight < 700;
              final double topSpacing = compact ? 12 : 22;
              final double sectionSpacing = compact ? 14 : 20;
              final double identitySpacing = compact ? 10 : 14;

              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          SizedBox(height: topSpacing),
                          Column(
                            children: <Widget>[
                              Container(
                                width: compact ? 58 : 68,
                                height: compact ? 58 : 68,
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? const Color(0xFF252A42)
                                          : Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFB89CFF,
                                    ).withValues(alpha: isDark ? 0.45 : 0.28),
                                  ),
                                  boxShadow: <BoxShadow>[
                                    BoxShadow(
                                      color: const Color(
                                        0xFFB89CFF,
                                      ).withValues(alpha: 0.18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Image.asset(
                                    'assets/images/logo-removebg-preview.png',
                                    fit: BoxFit.contain,
                                    filterQuality: FilterQuality.high,
                                    errorBuilder: (
                                      BuildContext context,
                                      Object error,
                                      StackTrace? stackTrace,
                                    ) {
                                      return const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Color(0xFFB89CFF),
                                        size: 30,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(height: identitySpacing),
                              Text(
                                'Welcome back, ${user.displayName}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: compact ? 20 : 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user.identifier,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 12.8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: compact ? 10 : 12),
                              Text(
                                hasAnyQuickUnlock
                                    ? 'Use your saved quick unlock method to continue after the 1-hour session lock.'
                                    : 'Quick unlock is turned off right now. Use your email and password to continue.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: subtitleColor,
                                  fontSize: 13.2,
                                  fontWeight: FontWeight.w500,
                                  height: 1.45,
                                ),
                              ),
                              if (!canUseTransactionPin) ...<Widget>[
                                const SizedBox(height: 8),
                                Text(
                                  user.hasTransactionPin
                                      ? 'PIN unlock is currently disabled in Settings.'
                                      : 'PIN unlock becomes available after you set your transaction PIN from the dashboard.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontSize: 11.8,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          SizedBox(height: sectionSpacing),
                          Container(
                            padding: EdgeInsets.fromLTRB(
                              compact ? 14 : 16,
                              compact ? 16 : 18,
                              compact ? 14 : 16,
                              compact ? 14 : 16,
                            ),
                            decoration: BoxDecoration(
                              color: surfaceColor,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: <Widget>[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List<Widget>.generate(_pinLength, (
                                    int index,
                                  ) {
                                    final bool isFilled =
                                        index < _digits.length;
                                    return Container(
                                      width: compact ? 52 : 58,
                                      height: compact ? 56 : 60,
                                      margin: EdgeInsets.only(
                                        right:
                                            index == _pinLength - 1
                                                ? 0
                                                : (compact ? 10 : 12),
                                      ),
                                      decoration: BoxDecoration(
                                        color:
                                            isFilled
                                                ? accentSurface
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color:
                                              isFilled
                                                  ? const Color(0xFFB89CFF)
                                                  : (isDark
                                                      ? const Color(0xFF374151)
                                                      : const Color(
                                                        0xFFE5E7EB,
                                                      )),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Center(
                                        child: AnimatedOpacity(
                                          duration: const Duration(
                                            milliseconds: 140,
                                          ),
                                          opacity: isFilled ? 1 : 0,
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFFB89CFF),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                                if (_errorText != null) ...<Widget>[
                                  const SizedBox(height: 10),
                                  Text(
                                    _errorText!,
                                    style: const TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                if (canUseBiometric) ...<Widget>[
                                  SizedBox(height: compact ? 14 : 16),
                                  SizedBox(
                                    height: 46,
                                    child: OutlinedButton.icon(
                                      onPressed:
                                          _isSubmitting ? null : _useBiometric,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(
                                          color:
                                              isDark
                                                  ? const Color(0xFF374151)
                                                  : const Color(0xFFE5E7EB),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                      ),
                                      icon:
                                          _isSubmitting
                                              ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              )
                                              : Icon(
                                                Icons.fingerprint_rounded,
                                                color:
                                                    isDark
                                                        ? const Color(
                                                          0xFFB89CFF,
                                                        )
                                                        : const Color(
                                                          0xFFB89CFF,
                                                        ),
                                              ),
                                      label: Text(
                                        _isSubmitting
                                            ? 'Checking...'
                                            : 'Use Fingerprint',
                                        style: TextStyle(
                                          color: titleColor,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 14 : 18),
                          Column(
                            children: <Widget>[
                              GestureDetector(
                                onTap:
                                    _isSubmitting
                                        ? null
                                        : () => Navigator.of(
                                          context,
                                        ).pushReplacementNamed(AppRoutes.login),
                                child: const Text(
                                  'Use email and password instead',
                                  style: TextStyle(
                                    color: Color(0xFFB89CFF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextButton(
                                key: const ValueKey<String>(
                                  'quick_login_switch_account',
                                ),
                                onPressed:
                                    _isSubmitting ? null : _switchAccount,
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: subtitleColor,
                                ),
                                child: Text(
                                  'Switch account',
                                  style: TextStyle(
                                    color: subtitleColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                    _QuickLoginKeypad(
                      isDark: isDark,
                      enabled:
                          hasAnyQuickUnlock &&
                          canUseTransactionPin &&
                          !_isSubmitting,
                      onDigit: _appendDigit,
                      onBackspace: _removeDigit,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _QuickLoginKeypad extends StatelessWidget {
  const _QuickLoginKeypad({
    required this.isDark,
    required this.enabled,
    required this.onDigit,
    required this.onBackspace,
  });

  final bool isDark;
  final bool enabled;
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Column(
        children: <Widget>[
          for (final List<String> row in const <List<String>>[
            <String>['1', '2', '3'],
            <String>['4', '5', '6'],
            <String>['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children:
                    row
                        .map(
                          (String digit) => Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: digit == row.last ? 0 : 8,
                              ),
                              child: _KeypadButton(
                                label: digit,
                                isDark: isDark,
                                onTap: enabled ? () => onDigit(digit) : () {},
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          Row(
            children: <Widget>[
              const Expanded(child: SizedBox.shrink()),
              Expanded(
                child: _KeypadButton(
                  label: '0',
                  isDark: isDark,
                  onTap: enabled ? () => onDigit('0') : () {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KeypadIconButton(
                  icon: Icons.backspace_outlined,
                  isDark: isDark,
                  onTap: enabled ? onBackspace : () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KeypadButton extends StatelessWidget {
  const _KeypadButton({
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color surface = isDark ? const Color(0xFF020B1E) : Colors.white;
    final Color border =
        isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:
                    isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
                fontSize: 19,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeypadIconButton extends StatelessWidget {
  const _KeypadIconButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color surface = isDark ? const Color(0xFF020B1E) : Colors.white;
    final Color border =
        isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 54,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
            ),
          ),
        ),
      ),
    );
  }
}
