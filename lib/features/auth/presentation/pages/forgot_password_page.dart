// features/auth/presentation/pages/forgot_password_page.dart
import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../data/auth_api_service.dart';
import '../widgets/auth_screen_shell.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  bool _isSubmitting = false;
  String? _statusMessage;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _statusMessage = null;
      _emailError =
          _emailController.text.trim().isEmpty
              ? 'Email address is required.'
              : null;
    });

    if (_emailError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(context, text: 'Sending reset link...');

    late final ForgotPasswordApiResult result;
    try {
      result = await AuthApiService.instance.forgotPassword(
        email: _emailController.text.trim(),
      );
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSubmitting = false;
      _emailError = result.fieldErrors['email'];
      _statusMessage = result.isSuccess ? result.message : null;
    });

    if (!result.isSuccess &&
        _emailError == null &&
        result.message != null &&
        result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      onToggleTheme: widget.onToggleTheme,
      title: 'Reset your password',
      subtitle:
          'Enter your email address and we will send a secure reset link to help you back in.',
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
          if (_statusMessage != null)
            AuthAlertCard(
              message: _statusMessage!,
              backgroundColor: const Color(0xFFECFDF5),
              borderColor: const Color(0xFFA7F3D0),
              textColor: const Color(0xFF047857),
            ),
          AuthTextField(
            controller: _emailController,
            label: 'Email Address',
            placeholder: 'Email Address',
            keyboardType: TextInputType.emailAddress,
            errorText: _emailError,
            prefixIcon: Icons.email_outlined,
            textInputAction: TextInputAction.done,
          ),
          AuthGradientButton(
            label: 'Send Reset Link',
            loading: _isSubmitting,
            loadingLabel: 'Sending link...',
            icon: Icons.send_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
