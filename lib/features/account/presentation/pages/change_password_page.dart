import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../data/account_security_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isSaving = false;
  String? _currentPasswordError;
  String? _newPasswordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isSaving = true;
      _currentPasswordError = null;
      _newPasswordError = null;
      _confirmPasswordError = null;
    });

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      await _handleUnauthorized();
      return;
    }

    final AccountSecurityResult result = await AccountSecurityApiService
        .instance
        .changePassword(
          token: token,
          currentPassword: _currentPasswordController.text,
          password: _newPasswordController.text,
          passwordConfirmation: _confirmPasswordController.text,
        );

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() => _isSaving = false);
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() => _isSaving = false);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Password updated successfully.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = false;
      _currentPasswordError = result.fieldErrors['current_password'];
      _newPasswordError = result.fieldErrors['password'];
      _confirmPasswordError = result.fieldErrors['password_confirmation'];
    });

    if ((result.message ?? '').isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    String? errorText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ptsDataSoftBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ptsDataSoftBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: ptsDataPrimary, width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return PtsDataPageScaffold(
      title: 'Change Password',
      selectedBottomNav: AppBottomNavDestination.me,
      onBottomNavigation: _handleBottomNavigation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Use a strong password so account recovery and sign-in stay secure.',
            style: TextStyle(
              color: mutedText,
              fontSize: 12.2,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _CardShell(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: _decoration(
                    label: 'Current Password',
                    hint: 'Enter your current password',
                    errorText: _currentPasswordError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: _decoration(
                    label: 'New Password',
                    hint: 'Enter your new password',
                    errorText: _newPasswordError,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _decoration(
                    label: 'Confirm Password',
                    hint: 'Confirm your new password',
                    errorText: _confirmPasswordError,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: ptsDataPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(_isSaving ? 'Updating...' : 'Update Password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.isDark, required this.child});

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
