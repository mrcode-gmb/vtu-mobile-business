import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';
import '../../data/auth_api_service.dart';
import '../widgets/auth_screen_shell.dart';
import '../widgets/auth_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  static const int _lastStep = 2;

  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _acceptTerms = false;
  bool _isSubmitting = false;
  int _currentStep = 0;

  final Map<String, String> _errors = <String, String>{};

  String get _progressLabel {
    switch (_currentStep) {
      case 0:
        return 'Personal Details';
      case 1:
        return 'Account Identity';
      default:
        return 'Security Setup';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _usernameController.dispose();
    _referralController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _clearErrors(List<String> keys) {
    for (final String key in keys) {
      _errors.remove(key);
    }
  }

  Map<String, String> _mapApiErrors(Map<String, String> apiErrors) {
    final Map<String, String> mapped = <String, String>{};

    apiErrors.forEach((String key, String value) {
      switch (key) {
        case 'mobile_number':
          mapped['mobile'] = value;
          break;
        case 'password_confirmation':
          mapped['confirm'] = value;
          break;
        default:
          mapped[key] = value;
      }
    });

    return mapped;
  }

  int _resolveStepFromErrors(Map<String, String> errors) {
    if (errors.containsKey('name') || errors.containsKey('email')) {
      return 0;
    }

    if (errors.containsKey('mobile') ||
        errors.containsKey('username') ||
        errors.containsKey('r_username')) {
      return 1;
    }

    return 2;
  }

  Map<String, String> _validateStep(int step) {
    switch (step) {
      case 0:
        return <String, String>{
          if (_nameController.text.trim().isEmpty)
            'name': 'Full name is required.',
          if (_emailController.text.trim().isEmpty)
            'email': 'Email address is required.',
        };
      case 1:
        return <String, String>{
          if (_mobileController.text.trim().isEmpty)
            'mobile': 'Mobile number is required.',
          if (_usernameController.text.trim().isEmpty)
            'username': 'Username is required.',
        };
      case 2:
        return <String, String>{
          if (_passwordController.text.isEmpty)
            'password': 'Password is required.',
          if (_confirmController.text.isEmpty)
            'confirm': 'Confirm your password.',
          if (_passwordController.text.isNotEmpty &&
              _confirmController.text.isNotEmpty &&
              _passwordController.text != _confirmController.text)
            'confirm': 'Passwords do not match.',
          if (!_acceptTerms)
            'terms': 'You must accept the terms and conditions to continue.',
        };
      default:
        return <String, String>{};
    }
  }

  Future<void> _goToNextStep() async {
    const List<List<String>> stepKeys = <List<String>>[
      <String>['name', 'email'],
      <String>['mobile', 'username', 'r_username'],
      <String>['password', 'confirm', 'terms'],
    ];

    final Map<String, String> stepErrors = _validateStep(_currentStep);

    setState(() {
      _clearErrors(stepKeys[_currentStep]);
      _errors.addAll(stepErrors);
    });

    if (stepErrors.isNotEmpty) {
      return;
    }

    if (_currentStep < _lastStep) {
      setState(() => _currentStep += 1);
      return;
    }

    await _submit();
  }

  void _goToPreviousStep() {
    if (_currentStep == 0) {
      return;
    }

    setState(() => _currentStep -= 1);
  }

  Future<void> _submit() async {
    setState(() {
      _errors
        ..clear()
        ..addAll(<String, String>{
          ..._validateStep(0),
          ..._validateStep(1),
          ..._validateStep(2),
        });
    });

    if (_errors.isNotEmpty) {
      if (_errors.containsKey('name') || _errors.containsKey('email')) {
        setState(() => _currentStep = 0);
      } else if (_errors.containsKey('mobile') ||
          _errors.containsKey('username')) {
        setState(() => _currentStep = 1);
      } else {
        setState(() => _currentStep = 2);
      }
      return;
    }

    setState(() => _isSubmitting = true);

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(context, text: 'Creating your account...');

    late final RegisterApiResult result;
    try {
      result = await AuthApiService.instance.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
        referralUsername: _referralController.text.trim(),
      );
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    if (!result.isSuccess) {
      final Map<String, String> mappedErrors = _mapApiErrors(
        result.fieldErrors,
      );
      if (mappedErrors.isNotEmpty) {
        setState(() {
          _errors
            ..clear()
            ..addAll(mappedErrors);
          _currentStep = _resolveStepFromErrors(mappedErrors);
        });
      }

      if (result.message != null && result.message!.isNotEmpty) {
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.session!.hasTransactionPin
              ? (result.message ??
                  'Account created successfully. Check your email to verify it.')
              : 'Account created successfully. Next, create your 4-digit transaction PIN from the dashboard, Me, or Settings.',
        ),
      ),
    );
    Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
  }

  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return Column(
          key: const ValueKey<int>(0),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _RegisterStepHeader(
              title: 'Personal details',
              description: 'Tell us who you are so we can open your wallet.',
            ),
            AuthTextField(
              controller: _nameController,
              placeholder: 'Full Name',
              errorText: _errors['name'],
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
            ),
            AuthTextField(
              controller: _emailController,
              placeholder: 'Email Address',
              keyboardType: TextInputType.emailAddress,
              errorText: _errors['email'],
              prefixIcon: Icons.email_outlined,
              textInputAction: TextInputAction.done,
            ),
          ],
        );
      case 1:
        return Column(
          key: const ValueKey<int>(1),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _RegisterStepHeader(
              title: 'Account identity',
              description:
                  'Choose the mobile number and username linked to your account.',
            ),
            AuthTextField(
              controller: _mobileController,
              placeholder: 'Mobile Number',
              keyboardType: TextInputType.phone,
              errorText: _errors['mobile'],
              prefixIcon: Icons.phone_iphone_rounded,
              textInputAction: TextInputAction.next,
            ),
            AuthTextField(
              controller: _usernameController,
              placeholder: 'Username',
              errorText: _errors['username'],
              prefixIcon: Icons.alternate_email_rounded,
              textInputAction: TextInputAction.next,
            ),
            AuthTextField(
              controller: _referralController,
              placeholder: 'Referral Username (Optional)',
              errorText: _errors['r_username'],
              prefixIcon: Icons.group_add_rounded,
              textInputAction: TextInputAction.done,
            ),
          ],
        );
      default:
        return Column(
          key: const ValueKey<int>(2),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const _RegisterStepHeader(
              title: 'Security setup',
              description:
                  'Create your password and confirm the account terms.',
            ),
            AuthTextField(
              controller: _passwordController,
              placeholder: 'Password',
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
                      isDark
                          ? const Color(0xFFC7CDDC)
                          : const Color(0xFF4B5563),
                ),
              ),
            ),
            AuthTextField(
              controller: _confirmController,
              placeholder: 'Confirm Password',
              errorText: _errors['confirm'],
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
                      isDark
                          ? const Color(0xFFC7CDDC)
                          : const Color(0xFF4B5563),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF171925) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color:
                      _errors['terms'] != null
                          ? const Color(0xFFFDA4AF)
                          : isDark
                          ? const Color(0xFF243146)
                          : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (bool? value) {
                          setState(() => _acceptTerms = value ?? false);
                        },
                        activeColor: const Color(0xFFB89CFF),
                        visualDensity: VisualDensity.compact,
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color:
                                    isDark
                                        ? const Color(0xFFC7CDDC)
                                        : const Color(0xFF374151),
                                fontSize: 12.4,
                                fontWeight: FontWeight.w500,
                                height: 1.45,
                              ),
                              children: const <InlineSpan>[
                                TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: TextStyle(
                                    color: Color(0xFFB89CFF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Color(0xFFB89CFF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errors['terms'] != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        _errors['terms']!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthScreenShell(
      onToggleTheme: widget.onToggleTheme,
      title: 'Create your account',
      subtitle:
          'Set up your PTS DATA profile and get ready to pay for services from one wallet.',
      progressTitle: 'Step ${_currentStep + 1} of 3',
      progressLabel: _progressLabel,
      progressValue: (_currentStep + 1) / 3,
      topActionLabel: 'Sign in',
      onTopActionTap: () {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      },
      footer: Wrap(
        alignment: WrapAlignment.center,
        children: <Widget>[
          const Text('Already have an account? '),
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
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _buildStepContent(isDark),
          ),
          Row(
            children: <Widget>[
              if (_currentStep > 0) ...<Widget>[
                Expanded(
                  child: AuthSecondaryButton(
                    label: 'Back',
                    onPressed: _isSubmitting ? null : _goToPreviousStep,
                    icon: Icons.arrow_back_rounded,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AuthGradientButton(
                  label:
                      _currentStep == _lastStep ? 'Create Account' : 'Continue',
                  loading: _isSubmitting,
                  loadingLabel: 'Creating account...',
                  icon:
                      _currentStep == _lastStep
                          ? Icons.person_add_alt_1_rounded
                          : Icons.arrow_forward_rounded,
                  onPressed: _goToNextStep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RegisterStepHeader extends StatelessWidget {
  const _RegisterStepHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563),
              fontSize: 13.4,
              fontWeight: FontWeight.w400,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
