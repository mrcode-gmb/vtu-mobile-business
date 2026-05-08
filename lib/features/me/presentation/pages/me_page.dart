import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../../features/me/data/profile_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';

class MePage extends StatefulWidget {
  const MePage({super.key});

  @override
  State<MePage> createState() => _MePageState();
}

class _MePageState extends State<MePage> {
  ProfileDetails _profile = const ProfileDetails.empty();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
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
      setState(() {
        _profile = result.profile!;
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = false);
    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  void _showPending(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label is coming soon.')));
  }

  Future<void> _copyReferralCode() async {
    if (!_profile.hasReferralCode) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _profile.referralCode));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  Future<void> _openRoute(String routeName) async {
    await Navigator.of(context).pushNamed(routeName);
    if (!mounted) {
      return;
    }

    switch (routeName) {
      case AppRoutes.personalInformation:
      case AppRoutes.verificationLimits:
      case AppRoutes.transactionPin:
      case AppRoutes.changePassword:
      case AppRoutes.settings:
        await _loadProfile();
        return;
      default:
        return;
    }
  }

  Future<void> _handleUnauthorized() async {
    await AppSessionService.instance.clear();
    if (!mounted) {
      return;
    }

    setState(() => _isLoading = false);
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  Future<void> _logout() async {
    await AppSessionService.instance.signOut();
    if (!mounted) {
      return;
    }

    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (Route<dynamic> route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    final List<_ProfileMenuItem> accountItems = <_ProfileMenuItem>[
      const _ProfileMenuItem(
        title: 'Personal Information',
        subtitle: 'Name, email, phone number, and account identity',
        icon: Icons.badge_rounded,
        routeName: AppRoutes.personalInformation,
      ),
      _ProfileMenuItem(
        title: 'Verification & Limits',
        subtitle:
            _profile.isEmailVerified
                ? 'Your email is verified and account checks are active'
                : 'Complete email verification and account checks',
        icon: Icons.verified_user_rounded,
        routeName: AppRoutes.verificationLimits,
      ),
      _ProfileMenuItem(
        title: 'Transaction PIN',
        subtitle:
            _profile.hasTransactionPin
                ? 'Protect transfers, airtime, and bill payments'
                : 'Set your 4-digit payment PIN for protected transactions',
        icon: Icons.lock_rounded,
        routeName: AppRoutes.transactionPin,
      ),
      const _ProfileMenuItem(
        title: 'Change Password',
        subtitle: 'Update your account password and recovery strength',
        icon: Icons.password_rounded,
        routeName: AppRoutes.changePassword,
      ),
      const _ProfileMenuItem(
        title: 'Notifications',
        subtitle: 'Alerts, reminders, and transaction updates',
        icon: Icons.notifications_active_rounded,
        routeName: AppRoutes.notifications,
      ),
    ];

    const List<_ProfileMenuItem> serviceItems = <_ProfileMenuItem>[
      _ProfileMenuItem(
        title: 'Transaction History',
        subtitle: 'Statements, filters, and recent wallet activity',
        icon: Icons.receipt_long_rounded,
        routeName: AppRoutes.transactionHistory,
      ),
      _ProfileMenuItem(
        title: 'Virtual Accounts',
        subtitle: 'Assigned wallet funding accounts and account details',
        icon: Icons.account_balance_wallet_outlined,
        routeName: AppRoutes.virtualAccounts,
      ),
      _ProfileMenuItem(
        title: 'Referrals',
        subtitle: 'Invite friends and track signup rewards',
        icon: Icons.people_alt_rounded,
        routeName: AppRoutes.referrals,
      ),
      _ProfileMenuItem(
        title: 'Cashback',
        subtitle: 'Review earnings and convert them into wallet cash',
        icon: Icons.card_giftcard_rounded,
        routeName: AppRoutes.cashback,
      ),
      _ProfileMenuItem(
        title: 'Cards & E-PIN',
        subtitle: 'Generate airtime cards, data cards, and exam pins',
        icon: Icons.credit_card_rounded,
        routeName: AppRoutes.cards,
      ),
    ];

    const List<_ProfileMenuItem> supportItems = <_ProfileMenuItem>[
      _ProfileMenuItem(
        title: 'News & Updates',
        subtitle: 'Announcements, service messages, and platform updates',
        icon: Icons.campaign_outlined,
        routeName: AppRoutes.news,
      ),
      _ProfileMenuItem(
        title: 'Support Center',
        subtitle: 'Chat, WhatsApp, and issue escalation options',
        icon: Icons.support_agent_rounded,
        routeName: AppRoutes.support,
      ),
      _ProfileMenuItem(
        title: 'More Services',
        subtitle: 'Browse extra utilities and account tools',
        icon: Icons.grid_view_rounded,
        routeName: AppRoutes.moreServices,
      ),
      _ProfileMenuItem(
        title: 'Settings',
        subtitle: 'Fingerprint, appearance, privacy, and app behavior',
        icon: Icons.tune_rounded,
        routeName: AppRoutes.settings,
      ),
      _ProfileMenuItem(
        title: 'About PTS DATA',
        subtitle: 'App version, policies, and service information',
        icon: Icons.info_outline_rounded,
      ),
    ];

    return PtsDataPageScaffold(
      title: 'Me',
      onRefresh: _loadProfile,
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
            'Manage your profile, rewards, security, and support from one place.',
            style: TextStyle(
              color: mutedText,
              fontSize: 12.2,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _ProfileIdentityPanel(
            isDark: isDark,
            profile: _profile,
            onCopyReferral: _copyReferralCode,
          ),
          if (!_isLoading && !_profile.hasTransactionPin) ...<Widget>[
            const SizedBox(height: 14),
            _PinReminderBanner(
              isDark: isDark,
              onCreatePin: () => _openRoute(AppRoutes.transactionPin),
            ),
          ],
          const SizedBox(height: 16),
          _ProfileSectionPanel(
            isDark: isDark,
            title: 'Quick Access',
            subtitle: 'Jump straight into the parts of PTS DATA you use most.',
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double itemWidth = (constraints.maxWidth - 8) / 2;

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    SizedBox(
                      width: itemWidth,
                      child: _QuickProfileActionTile(
                        title: 'Transaction History',
                        subtitle: 'Statement',
                        icon: Icons.history_rounded,
                        accent: ptsDataPrimary,
                        isDark: isDark,
                        onTap: () => _openRoute(AppRoutes.transactionHistory),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _QuickProfileActionTile(
                        title: 'Cashback',
                        subtitle: formatPtsDataCurrency(
                          _profile.cashbackBalance,
                        ),
                        icon: Icons.card_giftcard_rounded,
                        accent: ptsDataSecondary,
                        isDark: isDark,
                        onTap: () => _openRoute(AppRoutes.cashback),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _QuickProfileActionTile(
                        title: 'Referrals',
                        subtitle: 'Invite & earn',
                        icon: Icons.people_alt_rounded,
                        accent: ptsDataAccent,
                        isDark: isDark,
                        onTap: () => _openRoute(AppRoutes.referrals),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _QuickProfileActionTile(
                        title: 'Support',
                        subtitle: 'Get help',
                        icon: Icons.headset_mic_rounded,
                        accent: ptsDataSky,
                        isDark: isDark,
                        onTap: () => _openRoute(AppRoutes.support),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          _ProfileSectionPanel(
            isDark: isDark,
            title: 'Account & Security',
            subtitle:
                'Manage who you are, how you sign in, and how your account stays protected.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...accountItems.map(
                  (_ProfileMenuItem item) => Padding(
                    padding: EdgeInsets.only(
                      bottom: item == accountItems.last ? 0 : 8,
                    ),
                    child: _ProfileListTile(
                      item: item,
                      isDark: isDark,
                      onTap: () {
                        if (item.routeName != null) {
                          _openRoute(item.routeName!);
                          return;
                        }
                        _showPending(item.title);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileSectionPanel(
            isDark: isDark,
            title: 'Rewards & Services',
            subtitle:
                'Open the parts of PTS DATA you use most from one tidy section.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...serviceItems.map(
                  (_ProfileMenuItem item) => Padding(
                    padding: EdgeInsets.only(
                      bottom: item == serviceItems.last ? 0 : 8,
                    ),
                    child: _ProfileListTile(
                      item: item,
                      isDark: isDark,
                      onTap: () => _openRoute(item.routeName ?? AppRoutes.me),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileSectionPanel(
            isDark: isDark,
            title: 'Preferences & Support',
            subtitle:
                'Get help quickly and adjust how the PTS DATA app works for you.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ...supportItems.map(
                  (_ProfileMenuItem item) => Padding(
                    padding: EdgeInsets.only(
                      bottom: item == supportItems.last ? 0 : 8,
                    ),
                    child: _ProfileListTile(
                      item: item,
                      isDark: isDark,
                      onTap: () {
                        if (item.routeName != null) {
                          _openRoute(item.routeName!);
                          return;
                        }
                        _showPending(item.title);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: _logout,
            style: OutlinedButton.styleFrom(
              foregroundColor: titleColor,
              side: BorderSide(
                color:
                    isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
              ),
              minimumSize: const Size.fromHeight(46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: Text(
              'Sign Out',
              style: TextStyle(
                color: titleColor,
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              'PTS DATA v1.0.0',
              style: TextStyle(
                color: mutedText,
                fontSize: 10.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMetricTile extends StatelessWidget {
  const _ProfileMetricTile({
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
        color: isDark ? ptsDataDarkPanel : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 12.4,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedText,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentityPanel extends StatelessWidget {
  const _ProfileIdentityPanel({
    required this.isDark,
    required this.profile,
    required this.onCopyReferral,
  });

  final bool isDark;
  final ProfileDetails profile;
  final VoidCallback onCopyReferral;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);
    final Color badgeBackground =
        profile.isEmailVerified
            ? ptsDataPrimary.withValues(alpha: 0.10)
            : const Color(0xFFF59E0B).withValues(alpha: 0.14);
    final Color badgeText =
        profile.isEmailVerified ? ptsDataPrimary : const Color(0xFFB45309);
    final List<String> contactParts = <String>[
      profile.email.trim(),
      profile.mobileNumber.trim(),
    ].where((String value) => value.isNotEmpty).toList(growable: false);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? ptsDataPrimary.withValues(alpha: 0.16)
                          : ptsDataSoftTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/images/logo-removebg-preview.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14.2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.username.trim().isNotEmpty
                          ? '@${profile.username}'
                          : '@pending',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 10.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      contactParts.isEmpty
                          ? 'No contact details yet'
                          : contactParts.join('  •  '),
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      profile.joinedLabel,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 9.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  profile.verificationLabel,
                  style: TextStyle(
                    color: badgeText,
                    fontSize: 9.8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            decoration: BoxDecoration(
              color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Referral Code',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        profile.hasReferralCode
                            ? profile.referralCode
                            : 'Not available',
                        style: TextStyle(
                          color: titleColor,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: profile.hasReferralCode ? onCopyReferral : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: ptsDataPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 15),
                  label: const Text(
                    'Copy',
                    style: TextStyle(
                      fontSize: 10.6,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double itemWidth = (constraints.maxWidth - 16) / 3;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  SizedBox(
                    width: itemWidth,
                    child: _ProfileMetricTile(
                      label: 'Tier',
                      value: profile.tierLabel,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ProfileMetricTile(
                      label: 'Verification',
                      value: profile.verificationLabel,
                      isDark: isDark,
                    ),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _ProfileMetricTile(
                      label: 'PIN',
                      value: profile.pinStatusLabel,
                      isDark: isDark,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PinReminderBanner extends StatelessWidget {
  const _PinReminderBanner({required this.isDark, required this.onCreatePin});

  final bool isDark;
  final VoidCallback onCreatePin;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color:
            isDark
                ? ptsDataPrimary.withValues(alpha: 0.12)
                : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark
                  ? ptsDataPrimary.withValues(alpha: 0.34)
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
                      ? ptsDataPrimary.withValues(alpha: 0.18)
                      : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: ptsDataPrimary,
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
                    fontSize: 13.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You will need a 4-digit PIN before using transfers, bills, airtime, data, and other protected payments.',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11.3,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: onCreatePin,
                  style: FilledButton.styleFrom(
                    backgroundColor: ptsDataPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 0,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Create PIN',
                    style: TextStyle(
                      fontSize: 11.2,
                      fontWeight: FontWeight.w600,
                    ),
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

class _ProfileSectionPanel extends StatelessWidget {
  const _ProfileSectionPanel({
    required this.isDark,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final bool isDark;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PtsDataSectionHeader(title: title, subtitle: subtitle),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _QuickProfileActionTile extends StatelessWidget {
  const _QuickProfileActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
          decoration: BoxDecoration(
            color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 14),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: mutedText,
                  fontSize: 9.8,
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

class _ProfileListTile extends StatelessWidget {
  const _ProfileListTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final _ProfileMenuItem item;
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
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.fromLTRB(11, 11, 11, 11),
          decoration: BoxDecoration(
            color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: ptsDataPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: ptsDataPrimary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.title,
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 11.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 9.9,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 16, color: mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuItem {
  const _ProfileMenuItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.routeName,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String? routeName;
}
