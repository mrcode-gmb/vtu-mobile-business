import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../me/data/profile_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';

class VerificationLimitsPage extends StatefulWidget {
  const VerificationLimitsPage({super.key});

  @override
  State<VerificationLimitsPage> createState() => _VerificationLimitsPageState();
}

class _VerificationLimitsPageState extends State<VerificationLimitsPage> {
  ProfileDetails _profile = const ProfileDetails.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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

    setState(() {
      _isLoading = false;
      if (result.isSuccess && result.profile != null) {
        _profile = result.profile!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return PtsDataPageScaffold(
      title: 'Verification & Limits',
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
            'See your current account status, verification state, and protection setup.',
            style: TextStyle(
              color: mutedText,
              fontSize: 12.2,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            isDark: isDark,
            child: Column(
              children: <Widget>[
                _StatusRow(
                  label: 'Email Verification',
                  value: _profile.verificationLabel,
                  valueColor:
                      _profile.isEmailVerified
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFB45309),
                ),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Transaction PIN',
                  value: _profile.pinStatusLabel,
                  valueColor:
                      _profile.hasTransactionPin
                          ? ptsDataPrimary
                          : const Color(0xFFDC2626),
                ),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Account Tier',
                  value: _profile.tierLabel,
                  valueColor: titleColor,
                ),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Status',
                  value: _profile.statusLabel,
                  valueColor: titleColor,
                ),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Joined',
                  value: _profile.joinedLabel,
                  valueColor: titleColor,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Account Notes',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _profile.isEmailVerified
                      ? 'Your email is verified. You can continue using protected features.'
                      : 'Verify your email on the web flow if you need stricter account protection and recovery support.',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _profile.hasTransactionPin
                      ? 'Your 4-digit transaction PIN is already protecting transfers and bill payments.'
                      : 'Set your transaction PIN next so money actions stay protected.',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11.6,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.isDark, required this.child});

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

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
