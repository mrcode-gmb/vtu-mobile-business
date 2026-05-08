import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../data/auth_api_service.dart';
import '../widgets/auth_screen_shell.dart';
import '../widgets/auth_widgets.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _loginController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _canUseQuickLogin = false;
  bool _showPassword = false;
  bool _isSubmitting = false;
  String? _loginError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _loadQuickLoginAvailability();
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadQuickLoginAvailability() async {
    final bool canUseQuickLogin =
        await AppSessionService.instance.canUseQuickLogin();
    final String? apiToken = await AppSessionService.instance.getApiToken();
    if (!mounted) {
      return;
    }

    setState(() => _canUseQuickLogin = canUseQuickLogin);

    if (canUseQuickLogin && (apiToken == null || apiToken.isEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pushReplacementNamed(AppRoutes.quickLogin);
      });
    }
  }

  Future<void> _submit() async {
    setState(() {
      _loginError =
          _loginController.text.trim().isEmpty
              ? 'Email or username is required.'
              : null;
      _passwordError =
          _passwordController.text.isEmpty ? 'Password is required.' : null;
    });

    if (_loginError != null || _passwordError != null) {
      return;
    }

    setState(() => _isSubmitting = true);

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(context, text: 'Signing you in...');

    late final LoginApiResult result;
    try {
      result = await AuthApiService.instance.login(
        login: _loginController.text.trim(),
        password: _passwordController.text,
        remember: false,
      );
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!result.isSuccess) {
      setState(() {
        _loginError = result.fieldErrors['login'];
        _passwordError = result.fieldErrors['password'];
      });

      if ((_loginError == null && _passwordError == null) &&
          result.message != null &&
          result.message!.isNotEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result.message!)));
      }
      return;
    }

    await AppSessionService.instance.recordFullAuth(
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthScreenShell(
      onToggleTheme: widget.onToggleTheme,
      title: 'Sign in to your account',
      subtitle:
          'Access your wallet balance, recent payments, and account settings from one secure screen.',
      topActionLabel: 'Create account',
      onTopActionTap: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.register);
      },
      footer: Column(
        children: <Widget>[
          Wrap(
            alignment: WrapAlignment.center,
            children: <Widget>[
              const Text('New here? '),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.register);
                },
                child: const Text(
                  'Start registration',
                  style: TextStyle(
                    color: Color(0xFFB89CFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (_canUseQuickLogin) ...<Widget>[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.quickLogin);
              },
              child: Text(
                'Use Quick Login',
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF252A42),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthTextField(
            label: 'Email or Username',
            controller: _loginController,
            placeholder: 'example@email.com',
            errorText: _loginError,
            prefixIcon: Icons.alternate_email_rounded,
            textInputAction: TextInputAction.next,
          ),
          AuthTextField(
            label: 'Password',
            controller: _passwordController,
            placeholder: 'Enter your password',
            errorText: _passwordError,
            obscureText: !_showPassword,
            prefixIcon: Icons.lock_outline_rounded,
            textInputAction: TextInputAction.done,
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.forgotPassword);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  color: Color(0xFFB89CFF),
                  fontSize: 13.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AuthGradientButton(
            label: 'Sign In',
            loading: _isSubmitting,
            loadingLabel: 'Signing in...',
            icon: Icons.arrow_forward_rounded,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
