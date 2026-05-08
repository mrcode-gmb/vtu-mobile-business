import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../data/account_security_api_service.dart';
import '../../../me/data/profile_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';

class TransactionPinPage extends StatefulWidget {
  const TransactionPinPage({super.key});

  @override
  State<TransactionPinPage> createState() => _TransactionPinPageState();
}

class _TransactionPinPageState extends State<TransactionPinPage> {
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  final TextEditingController _resetPasswordController =
      TextEditingController();
  final TextEditingController _resetNewPinController = TextEditingController();
  final TextEditingController _resetConfirmPinController =
      TextEditingController();

  ProfileDetails _profile = const ProfileDetails.empty();
  bool _isLoading = true;
  bool _isSavingChange = false;
  bool _isSavingReset = false;
  bool _showResetForm = false;

  String? _oldPinError;
  String? _newPinError;
  String? _confirmPinError;
  String? _resetPasswordError;
  String? _resetNewPinError;
  String? _resetConfirmPinError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    _resetPasswordController.dispose();
    _resetNewPinController.dispose();
    _resetConfirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
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

  Future<void> _loadProfile() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    final ProfileApiResult result = await ProfileApiService.instance
        .fetchProfile(token: token);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess && result.profile != null) {
      await AppSessionService.instance.updateTransactionPinStatus(
        result.profile!.hasTransactionPin,
      );
    }

    setState(() {
      _isLoading = false;
      if (result.isSuccess && result.profile != null) {
        _profile = result.profile!;
      }
    });
  }

  Future<void> _submitPinForm() async {
    FocusScope.of(context).unfocus();
    final String? oldPinError =
        _profile.hasTransactionPin
            ? _pinFieldError(
              _oldPinController.text.trim(),
              label: 'Current PIN',
            )
            : null;
    final String? newPinError = _pinFieldError(
      _newPinController.text.trim(),
      label: 'New PIN',
    );
    final String? confirmPinError = _pinFieldError(
      _confirmPinController.text.trim(),
      label: 'Confirm PIN',
    );

    if (oldPinError != null || newPinError != null || confirmPinError != null) {
      setState(() {
        _oldPinError = oldPinError;
        _newPinError = newPinError;
        _confirmPinError = confirmPinError;
      });
      return;
    }

    setState(() {
      _isSavingChange = true;
      _oldPinError = null;
      _newPinError = null;
      _confirmPinError = null;
    });

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _isSavingChange = false);
      }
      await _handleUnauthorized();
      return;
    }

    final AccountSecurityResult result =
        _profile.hasTransactionPin
            ? await AccountSecurityApiService.instance.changeTransactionPin(
              token: token,
              oldPin: _oldPinController.text.trim(),
              newPin: _newPinController.text.trim(),
              confirmPin: _confirmPinController.text.trim(),
            )
            : await AccountSecurityApiService.instance.createTransactionPin(
              token: token,
              newPin: _newPinController.text.trim(),
              confirmPin: _confirmPinController.text.trim(),
            );

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() => _isSavingChange = false);
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      await AppSessionService.instance.updateTransactionPinStatus(true);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingChange = false;
        _oldPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
        if (result.profile != null) {
          _profile = result.profile!;
        } else {
          _profile = ProfileDetails(
            name: _profile.name,
            email: _profile.email,
            mobileNumber: _profile.mobileNumber,
            username: _profile.username,
            referralCode: _profile.referralCode,
            referralUsername: _profile.referralUsername,
            role: _profile.role,
            roleLabel: _profile.roleLabel,
            accountType: _profile.accountType,
            tierLabel: _profile.tierLabel,
            status: _profile.status,
            statusLabel: _profile.statusLabel,
            verificationLabel: _profile.verificationLabel,
            pinStatusLabel: 'Enabled',
            profileCompleted: _profile.profileCompleted,
            isEmailVerified: _profile.isEmailVerified,
            hasTransactionPin: true,
            walletBalance: _profile.walletBalance,
            cashbackBalance: _profile.cashbackBalance,
            joinedAt: _profile.joinedAt,
            joinedLabel: _profile.joinedLabel,
          );
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                (_profile.hasTransactionPin
                    ? 'Transaction PIN updated successfully.'
                    : 'Transaction PIN created successfully.'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSavingChange = false;
      _oldPinError = result.fieldErrors['old_pin'];
      _newPinError = result.fieldErrors['new_pin'];
      _confirmPinError = result.fieldErrors['confirm_pin'];
    });

    if ((result.message ?? '').isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _submitResetForm() async {
    FocusScope.of(context).unfocus();
    final String? resetNewPinError = _pinFieldError(
      _resetNewPinController.text.trim(),
      label: 'New PIN',
    );
    final String? resetConfirmPinError = _pinFieldError(
      _resetConfirmPinController.text.trim(),
      label: 'Confirm PIN',
    );

    if (resetNewPinError != null || resetConfirmPinError != null) {
      setState(() {
        _resetNewPinError = resetNewPinError;
        _resetConfirmPinError = resetConfirmPinError;
      });
      return;
    }

    setState(() {
      _isSavingReset = true;
      _resetPasswordError = null;
      _resetNewPinError = null;
      _resetConfirmPinError = null;
    });

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _isSavingReset = false);
      }
      await _handleUnauthorized();
      return;
    }

    final AccountSecurityResult result = await AccountSecurityApiService
        .instance
        .resetTransactionPin(
          token: token,
          password: _resetPasswordController.text,
          newPin: _resetNewPinController.text.trim(),
          confirmPin: _resetConfirmPinController.text.trim(),
        );

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() => _isSavingReset = false);
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      await AppSessionService.instance.updateTransactionPinStatus(true);
      if (!mounted) {
        return;
      }
      setState(() {
        _isSavingReset = false;
        _showResetForm = false;
        _resetPasswordController.clear();
        _resetNewPinController.clear();
        _resetConfirmPinController.clear();
        if (result.profile != null) {
          _profile = result.profile!;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Transaction PIN reset successfully.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isSavingReset = false;
      _resetPasswordError = result.fieldErrors['your_password'];
      _resetNewPinError = result.fieldErrors['new_pin'];
      _resetConfirmPinError = result.fieldErrors['confirm_pin'];
    });

    if ((result.message ?? '').isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  InputDecoration _decoration({
    required String label,
    required bool isDark,
    String? errorText,
    String? hint,
  }) {
    final Color fillColor = isDark ? const Color(0xFF171B2B) : Colors.white;
    final Color borderColor =
        isDark ? const Color(0xFF4A5168) : const Color(0xFFD1D5DB);
    final Color labelColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF4B5563);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(
        color: labelColor,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(
        color: labelColor.withValues(alpha: 0.58),
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ptsDataPrimary, width: 1.2),
      ),
    );
  }

  String? _pinFieldError(String value, {required String label}) {
    if (value.isEmpty) {
      return '$label is required.';
    }

    if (!RegExp(r'^\d{4}$').hasMatch(value)) {
      return '$label must be exactly 4 digits.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return PtsDataPageScaffold(
      title: 'Transaction PIN',
      selectedBottomNav: AppBottomNavDestination.me,
      onBottomNavigation: _handleBottomNavigation,
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
            'Protect transfers, airtime, bills, and other money actions with your 4-digit PIN.',
            style: TextStyle(
              color: mutedText,
              fontSize: 12.2,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _PinCard(
            isDark: isDark,
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      _profile.hasTransactionPin
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                  child: Icon(
                    _profile.hasTransactionPin
                        ? Icons.verified_user_rounded
                        : Icons.lock_outline_rounded,
                    color:
                        _profile.hasTransactionPin
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _profile.hasTransactionPin
                            ? 'PIN is active'
                            : 'PIN not set yet',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _profile.hasTransactionPin
                            ? 'You can change it below or reset it with your password.'
                            : 'Create your 4-digit transaction PIN to protect payments.',
                        style: TextStyle(
                          color: mutedText,
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
          const SizedBox(height: 16),
          _PinCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  _profile.hasTransactionPin ? 'Change PIN' : 'Create PIN',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (_profile.hasTransactionPin) ...<Widget>[
                  _PinBoxInput(
                    controller: _oldPinController,
                    label: 'Current PIN',
                    errorText: _oldPinError,
                    isDark: isDark,
                    onChanged: () => setState(() => _oldPinError = null),
                  ),
                  const SizedBox(height: 12),
                ],
                _PinBoxInput(
                  controller: _newPinController,
                  label: 'New PIN',
                  errorText: _newPinError,
                  isDark: isDark,
                  onChanged: () => setState(() => _newPinError = null),
                ),
                const SizedBox(height: 12),
                _PinBoxInput(
                  controller: _confirmPinController,
                  label: 'Confirm PIN',
                  errorText: _confirmPinError,
                  isDark: isDark,
                  onChanged: () => setState(() => _confirmPinError = null),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSavingChange ? null : _submitPinForm,
                  style: FilledButton.styleFrom(
                    backgroundColor: ptsDataPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _isSavingChange
                        ? 'Saving...'
                        : (_profile.hasTransactionPin
                            ? 'Update PIN'
                            : 'Create PIN'),
                  ),
                ),
              ],
            ),
          ),
          if (_profile.hasTransactionPin) ...<Widget>[
            const SizedBox(height: 16),
            _PinCard(
              isDark: isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Forgot PIN?',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showResetForm = !_showResetForm;
                          });
                        },
                        child: Text(
                          _showResetForm ? 'Hide' : 'Reset with Password',
                        ),
                      ),
                    ],
                  ),
                  if (_showResetForm) ...<Widget>[
                    const SizedBox(height: 10),
                    TextField(
                      controller: _resetPasswordController,
                      obscureText: true,
                      onChanged:
                          (_) => setState(() => _resetPasswordError = null),
                      style: TextStyle(
                        color:
                            isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF111827),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: _decoration(
                        label: 'Account Password',
                        isDark: isDark,
                        hint: 'Enter your account password',
                        errorText: _resetPasswordError,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PinBoxInput(
                      controller: _resetNewPinController,
                      label: 'New PIN',
                      errorText: _resetNewPinError,
                      isDark: isDark,
                      onChanged: () => setState(() => _resetNewPinError = null),
                    ),
                    const SizedBox(height: 12),
                    _PinBoxInput(
                      controller: _resetConfirmPinController,
                      label: 'Confirm PIN',
                      errorText: _resetConfirmPinError,
                      isDark: isDark,
                      onChanged:
                          () => setState(() => _resetConfirmPinError = null),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isSavingReset ? null : _submitResetForm,
                      style: FilledButton.styleFrom(
                        backgroundColor: ptsDataSecondary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _isSavingReset ? 'Resetting...' : 'Reset PIN',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PinBoxInput extends StatefulWidget {
  const _PinBoxInput({
    required this.controller,
    required this.label,
    required this.isDark,
    this.errorText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool isDark;
  final String? errorText;
  final VoidCallback? onChanged;

  @override
  State<_PinBoxInput> createState() => _PinBoxInputState();
}

class _PinBoxInputState extends State<_PinBoxInput> {
  static final List<TextInputFormatter> _inputFormatters = <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    LengthLimitingTextInputFormatter(4),
  ];

  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant _PinBoxInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final String value = widget.controller.text;
    final bool hasError = widget.errorText != null;
    final Color labelColor =
        widget.isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText =
        widget.isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: TextStyle(
            color: labelColor,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          children: <Widget>[
            Row(
              children: List<Widget>.generate(4, (int index) {
                final bool filled = index < value.length;
                final bool active =
                    _focusNode.hasFocus &&
                    (index == value.length.clamp(0, 3) ||
                        (filled && index == 3));

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: index == 3 ? 0 : 9),
                    child: _PinDigitBox(
                      filled: filled,
                      active: active,
                      hasError: hasError,
                      isDark: widget.isDark,
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: _inputFormatters,
                maxLength: 4,
                obscureText: true,
                showCursor: false,
                enableInteractiveSelection: false,
                onChanged: (_) => widget.onChanged?.call(),
                style: const TextStyle(color: Colors.transparent, fontSize: 1),
                cursorColor: Colors.transparent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  counterText: '',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
        if (hasError) ...<Widget>[
          const SizedBox(height: 7),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else ...<Widget>[
          const SizedBox(height: 7),
          Text(
            'Enter 4 digits',
            style: TextStyle(
              color: mutedText,
              fontSize: 10.8,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class _PinDigitBox extends StatelessWidget {
  const _PinDigitBox({
    required this.filled,
    required this.active,
    required this.hasError,
    required this.isDark,
  });

  final bool filled;
  final bool active;
  final bool hasError;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        hasError
            ? const Color(0xFFDC2626)
            : (active
                ? ptsDataPrimary
                : (isDark ? const Color(0xFF4A5168) : const Color(0xFFD1D5DB)));
    final Color fillColor = isDark ? const Color(0xFF171B2B) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      height: 52,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: active ? 1.4 : 1),
      ),
      child: Center(
        child: AnimatedOpacity(
          opacity: filled ? 1 : 0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: ptsDataPrimary,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _PinCard extends StatelessWidget {
  const _PinCard({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
        ),
      ),
      child: child,
    );
  }
}
