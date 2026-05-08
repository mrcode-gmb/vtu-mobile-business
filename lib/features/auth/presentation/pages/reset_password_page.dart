import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../data/auth_api_service.dart';
import '../widgets/auth_screen_shell.dart';
import '../widgets/auth_widgets.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({
    required this.onToggleTheme,
    this.routeArguments,
    super.key,
  });

  final VoidCallback onToggleTheme;
  final Object? routeArguments;

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _tokenController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isSubmitting = false;
  final Map<String, String> _errors = <String, String>{};

  @override
  void initState() {
    super.initState();
    final _ResetPasswordSeed seed = _resolveSeed();
    _tokenController.text = seed.token;
    _emailController.text = seed.email;
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  _ResetPasswordSeed _resolveSeed() {
    String token = '';
    String email = '';

    final Object? rawArguments = widget.routeArguments;
    if (rawArguments is Map) {
      token = rawArguments['token']?.toString() ?? token;
      email = rawArguments['email']?.toString() ?? email;
    }

    final Map<String, String> baseQuery = Uri.base.queryParameters;
    token = baseQuery['token'] ?? token;
    email = baseQuery['email'] ?? email;

    final String fragment = Uri.base.fragment;
    if (fragment.contains('?')) {
      final String query = fragment.split('?').last;
      final Map<String, String> fragmentQuery = Uri.splitQueryString(query);
      token = fragmentQuery['token'] ?? token;
      email = fragmentQuery['email'] ?? email;
    }

    return _ResetPasswordSeed(token: token.trim(), email: email.trim());
  }

  Future<void> _submit() async {
    final String token = _tokenController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String passwordConfirmation = _confirmController.text;

    setState(() {
      _errors
        ..clear()
        ..addAll(<String, String>{
          if (token.isEmpty) 'token': 'Reset token is required.',
          if (email.isEmpty) 'email': 'Email address is required.',
          if (password.isEmpty) 'password': 'New password is required.',
          if (passwordConfirmation.isEmpty)
            'password_confirmation': 'Confirm your new password.',
          if (password.isNotEmpty &&
              passwordConfirmation.isNotEmpty &&
              password != passwordConfirmation)
            'password_confirmation': 'Passwords do not match.',
        });
    });

    if (_errors.isNotEmpty) {
      return;
    }

    setState(() => _isSubmitting = true);
    final ResetPasswordApiResult result = await AuthApiService.instance
        .resetPassword(
          token: token,
          email: email,
          password: password,
          passwordConfirmation: passwordConfirmation,
        );
    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ?? 'Password reset successful. Please sign in.',
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (!mounted) {
        return;
      }

      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.login,
        (Route<dynamic> route) => false,
      );
      return;
    }

    if (result.isValidationError) {
      setState(() {
        _errors
          ..clear()
          ..addAll(result.fieldErrors);
      });
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message ?? 'We could not reset your password right now.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthScreenShell(
      onToggleTheme: widget.onToggleTheme,
      title: 'Create a new password',
      subtitle:
          'Set a new password for your PTS DATA account and continue with your normal login.',
      progressTitle: 'Step 2 of 2',
      progressLabel: 'New Password',
      progressValue: 1,
      topActionLabel: 'Back to login',
      onTopActionTap: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      },
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          const Text('Remember your password? '),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacementNamed(AppRoutes.login);
            },
            child: const Text(
              'Sign in',
              style: TextStyle(
                color: Color(0xFFB89CFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthTextField(
            label: 'Reset Token',
            controller: _tokenController,
            placeholder: 'Paste the reset token from your email link',
            errorText: _errors['token'],
            prefixIcon: Icons.key_rounded,
            textInputAction: TextInputAction.next,
          ),
          AuthTextField(
            label: 'Email Address',
            controller: _emailController,
            placeholder: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            errorText: _errors['email'],
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.next,
          ),
          AuthTextField(
            label: 'New Password',
            controller: _passwordController,
            placeholder: 'Enter your new password',
            errorText: _errors['password'],
            obscureText: !_showPassword,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.next,
            suffix: IconButton(
              onPressed: () => setState(() => _showPassword = !_showPassword),
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color:
                    isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563),
              ),
            ),
          ),
          AuthTextField(
            label: 'Confirm New Password',
            controller: _confirmController,
            placeholder: 'Confirm your new password',
            errorText: _errors['password_confirmation'],
            obscureText: !_showConfirmPassword,
            prefixIcon: Icons.lock_reset_rounded,
            textInputAction: TextInputAction.done,
            suffix: IconButton(
              onPressed: () {
                setState(() => _showConfirmPassword = !_showConfirmPassword);
              },
              icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color:
                    isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563),
              ),
            ),
          ),
          AuthGradientButton(
            label: 'Continue with New Password',
            loading: _isSubmitting,
            loadingLabel: 'Processing...',
            icon: Icons.arrow_forward_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _ResetPasswordSeed {
  const _ResetPasswordSeed({required this.token, required this.email});

  final String token;
  final String email;
}
