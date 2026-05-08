import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../data/referrals_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_loader_overlay.dart';

const Color _primary = Color(0xFFB89CFF);
const Color _softTint = Color(0xFFF3F4F6);
const Color _softBorder = Color(0xFFE5E7EB);
const Color _darkBackground = Color(0xFF171925);
const Color _darkSurface = Color(0xFF22263A);
const Color _darkPanel = Color(0xFF252A42);
const Color _darkMuted = Color(0xFFC7CDDC);

class ReferralsPage extends StatefulWidget {
  const ReferralsPage({super.key});

  @override
  State<ReferralsPage> createState() => _ReferralsPageState();
}

class _ReferralsPageState extends State<ReferralsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<_ReferralItem> _referrals = <_ReferralItem>[];
  _ReferralFilter _selectedFilter = _ReferralFilter.all;
  String _referralCode = '';
  String _inviteLink = '';
  double _rewardPerReferral = 50;
  int _totalReferrals = 0;
  int _claimableCount = 0;
  int _claimedCount = 0;
  double _totalEarned = 0;
  double _claimableAmount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  Future<void> _loadReferrals({bool showFailure = true}) async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      return;
    }

    final ReferralsOverviewApiResult result = await ReferralsApiService.instance
        .fetchOverview(token: token);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      setState(() {
        _loading = false;
      });
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess && result.overview != null) {
      setState(() {
        _applyOverview(result.overview!);
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = false;
    });
    if (showFailure && result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _refreshReferrals() async {
    await _loadReferrals(showFailure: false);
  }

  void _applyOverview(ReferralsOverview overview) {
    _referralCode = overview.referralCode;
    _inviteLink = overview.inviteLink;
    _rewardPerReferral = overview.rewardPerReferral;
    _totalReferrals = overview.totalReferrals;
    _claimableCount = overview.claimableCount;
    _claimedCount = overview.claimedCount;
    _totalEarned = overview.totalEarned;
    _claimableAmount = overview.claimableAmount;
    _referrals = _mapItems(overview.items);
  }

  Future<void> _copyReferralCode() async {
    if (_referralCode.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _referralCode));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Referral code copied.')));
  }

  Future<void> _copyInviteLink() async {
    if (_inviteLink.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _inviteLink));
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invite link copied.')));
  }

  Future<void> _claimReward(_ReferralItem item) async {
    if (item.status != _ReferralStatus.claimable || item.id.isEmpty) {
      return;
    }

    final NavigatorState rootNavigator = Navigator.of(
      context,
      rootNavigator: true,
    );
    showPtsDataLoaderDialog<void>(
      context,
      text: 'Claiming reward...',
      color: _primary,
    );

    final String? token = await AppSessionService.instance.getApiToken();
    ReferralsClaimApiResult result;
    try {
      if (token == null || token.isEmpty) {
        result = const ReferralsClaimApiResult.unauthorized(
          'Your session has expired. Please sign in again.',
        );
      } else {
        result = await ReferralsApiService.instance.claimReward(
          token: token,
          referralId: item.id,
        );
      }
    } finally {
      rootNavigator.pop();
    }

    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (!result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.message ??
                'We could not claim this referral reward right now.',
          ),
        ),
      );
      return;
    }

    if (result.overview != null) {
      setState(() {
        _applyOverview(result.overview!);
      });
    } else {
      setState(() {
        final int index = _referrals.indexWhere(
          (_ReferralItem current) => current.id == item.id,
        );
        if (index >= 0) {
          _referrals[index] = item.copyWith(status: _ReferralStatus.claimed);
        }
      });
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _ReferralClaimResultSheet(
          name: item.name,
          rewardAmount: _formatCurrency(
            result.claimedAmount > 0 ? result.claimedAmount : item.reward,
          ),
        );
      },
    );
  }

  List<_ReferralItem> get _filteredReferrals {
    final String query = _searchController.text.trim().toLowerCase();

    return _referrals.where((_ReferralItem item) {
      final bool matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.status.label.toLowerCase().contains(query);

      if (!matchesQuery) {
        return false;
      }

      switch (_selectedFilter) {
        case _ReferralFilter.all:
          return true;
        case _ReferralFilter.claimable:
          return item.status == _ReferralStatus.claimable;
        case _ReferralFilter.claimed:
          return item.status == _ReferralStatus.claimed;
        case _ReferralFilter.pending:
          return item.status == _ReferralStatus.pending;
      }
    }).toList();
  }

  List<_ReferralItem> _mapItems(List<ReferralApiItem> items) {
    return items
        .map(
          (ReferralApiItem item) => _ReferralItem(
            id: item.id,
            name: item.name,
            joinedAt: item.createdAt ?? DateTime.now(),
            reward: item.reward,
            status: _statusFromApi(item.status, item.statusLabel),
          ),
        )
        .toList(growable: false);
  }

  _ReferralStatus _statusFromApi(int status, String statusLabel) {
    switch (status) {
      case 1:
        return _ReferralStatus.claimable;
      case 2:
        return _ReferralStatus.claimed;
      default:
        final String normalizedLabel = statusLabel.toLowerCase();
        if (normalizedLabel.contains('used') ||
            normalizedLabel.contains('claimed')) {
          return _ReferralStatus.claimed;
        }
        if (normalizedLabel.contains('unused') ||
            normalizedLabel.contains('claim')) {
          return _ReferralStatus.claimable;
        }
        return _ReferralStatus.pending;
    }
  }

  String _formatCurrency(num amount) {
    final String fixed = amount.toStringAsFixed(2);
    final List<String> parts = fixed.split('.');
    final String whole = parts.first.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );
    return '\u20A6$whole.${parts.last}';
  }

  String _formatDate(DateTime value) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }

  InputDecoration _fieldDecoration({
    required bool isDark,
    required Color mutedText,
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: isDark ? _darkPanel : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: _primary, width: 1.3),
      ),
      hintStyle: TextStyle(color: mutedText, fontSize: 12.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? _darkBackground : Colors.white;
    final Color pageSurface = isDark ? _darkSurface : Colors.white;
    final Color panelColor = isDark ? _darkPanel : const Color(0xFFF8FAFC);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: titleColor,
          ),
        ),
        title: Text(
          'Referrals',
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double bottomPadding =
              112 + MediaQuery.paddingOf(context).bottom;

          return RefreshIndicator.adaptive(
            color: _primary,
            onRefresh: _refreshReferrals,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - bottomPadding + 24,
                ),
                child: Container(
                  color: pageSurface,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Text(
                          'Share your PTS DATA code, track invited users, and claim your referral rewards from one clean screen.',
                          style: TextStyle(
                            color: mutedText,
                            fontSize: 12.2,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (
                            BuildContext context,
                            BoxConstraints constraints,
                          ) {
                            final double itemWidth =
                                (constraints.maxWidth - 8) / 2;

                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                SizedBox(
                                  width: itemWidth,
                                  child: _ReferralMetricTile(
                                    label: 'Total Referrals',
                                    value: '$_totalReferrals',
                                    isDark: isDark,
                                    accent: _primary,
                                    icon: Icons.people_alt_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _ReferralMetricTile(
                                    label: 'Claimable',
                                    value: '$_claimableCount',
                                    isDark: isDark,
                                    accent: const Color(0xFFF59E0B),
                                    icon: Icons.card_giftcard_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _ReferralMetricTile(
                                    label: 'Claimed',
                                    value: '$_claimedCount',
                                    isDark: isDark,
                                    accent: const Color(0xFF16A34A),
                                    icon: Icons.check_circle_rounded,
                                  ),
                                ),
                                SizedBox(
                                  width: itemWidth,
                                  child: _ReferralMetricTile(
                                    label: 'Total Earned',
                                    value: _formatCurrency(_totalEarned),
                                    isDark: isDark,
                                    accent: const Color(0xFF7FA0F5),
                                    icon: Icons.account_balance_wallet_rounded,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  isDark
                                      ? const Color(0xFF3A4054)
                                      : _softBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Invite friends and earn instantly',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Every successful signup with your code unlocks a reward you can claim to wallet.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  14,
                                  14,
                                  14,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      isDark
                                          ? _primary.withValues(alpha: 0.12)
                                          : _softTint,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color:
                                        isDark
                                            ? _primary.withValues(alpha: 0.18)
                                            : _softBorder,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Referral Code',
                                      style: TextStyle(
                                        color: mutedText,
                                        fontSize: 10.8,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _referralCode,
                                      style: TextStyle(
                                        color: titleColor,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _inviteLink,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: mutedText,
                                        fontSize: 11.2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _copyReferralCode,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: titleColor,
                                        side: BorderSide(
                                          color:
                                              isDark
                                                  ? const Color(0xFF374151)
                                                  : const Color(0xFFC7CDDC),
                                        ),
                                        minimumSize: const Size.fromHeight(46),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.copy_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Copy Code'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: _copyInviteLink,
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _primary,
                                        foregroundColor: Colors.white,
                                        minimumSize: const Size.fromHeight(46),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.share_rounded,
                                        size: 16,
                                      ),
                                      label: const Text('Copy Link'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LayoutBuilder(
                                builder: (
                                  BuildContext context,
                                  BoxConstraints constraints,
                                ) {
                                  final double itemWidth =
                                      (constraints.maxWidth - 16) / 3;

                                  return Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: <Widget>[
                                      SizedBox(
                                        width: itemWidth,
                                        child: _ReferralInfoTile(
                                          label: 'Per User',
                                          value: _formatCurrency(
                                            _rewardPerReferral,
                                          ),
                                          isDark: isDark,
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: _ReferralInfoTile(
                                          label: 'Claimable',
                                          value: _formatCurrency(
                                            _claimableAmount,
                                          ),
                                          isDark: isDark,
                                        ),
                                      ),
                                      SizedBox(
                                        width: itemWidth,
                                        child: _ReferralInfoTile(
                                          label: 'Reward Type',
                                          value: 'Wallet',
                                          isDark: isDark,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: panelColor,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color:
                                  isDark
                                      ? const Color(0xFF3A4054)
                                      : _softBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: <Widget>[
                              Text(
                                'Referral Activity',
                                style: TextStyle(
                                  color: titleColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Track everyone that joined with your username and claim rewards when available.',
                                style: TextStyle(
                                  color: mutedText,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _searchController,
                                onChanged: (_) => setState(() {}),
                                decoration: _fieldDecoration(
                                  isDark: isDark,
                                  mutedText: mutedText,
                                  hintText: 'Search referrals',
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    size: 18,
                                    color: mutedText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    _ReferralFilter.values
                                        .map(
                                          (_ReferralFilter filter) =>
                                              _ReferralFilterChip(
                                                label: filter.label,
                                                isDark: isDark,
                                                selected:
                                                    filter == _selectedFilter,
                                                onTap: () {
                                                  setState(() {
                                                    _selectedFilter = filter;
                                                  });
                                                },
                                              ),
                                        )
                                        .toList(),
                              ),
                              const SizedBox(height: 16),
                              if (_loading)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 28,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: isDark ? Colors.white : _primary,
                                    ),
                                  ),
                                )
                              else if (_filteredReferrals.isEmpty)
                                _EmptyReferralState(isDark: isDark)
                              else
                                ..._filteredReferrals.map((_ReferralItem item) {
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      bottom:
                                          item == _filteredReferrals.last
                                              ? 0
                                              : 12,
                                    ),
                                    child: _ReferralActivityCard(
                                      item: item,
                                      isDark: isDark,
                                      formatter: _formatCurrency,
                                      dateFormatter: _formatDate,
                                      onClaim:
                                          item.status ==
                                                  _ReferralStatus.claimable
                                              ? () => _claimReward(item)
                                              : null,
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: AppBottomNavigation(
        isDark: isDark,
        selectedDestination: AppBottomNavDestination.home,
        onSelect: _handleBottomNavigation,
      ),
    );
  }
}

class _ReferralMetricTile extends StatelessWidget {
  const _ReferralMetricTile({
    required this.label,
    required this.value,
    required this.isDark,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final bool isDark;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: isDark ? _darkPanel : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(
            radius: 16,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, size: 16, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: mutedText,
              fontSize: 10.4,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralInfoTile extends StatelessWidget {
  const _ReferralInfoTile({
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
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: mutedText,
              fontSize: 9.8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: titleColor,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralFilterChip extends StatelessWidget {
  const _ReferralFilterChip({
    required this.label,
    required this.isDark,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool isDark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color textColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151);

    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        elevation: 0,
        backgroundColor:
            selected ? _primary : (isDark ? _darkPanel : Colors.white),
        foregroundColor: selected ? Colors.white : textColor,
        side: BorderSide(
          color:
              selected
                  ? Colors.transparent
                  : (isDark ? const Color(0xFF3A4054) : _softBorder),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 11.2, fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

class _ReferralActivityCard extends StatelessWidget {
  const _ReferralActivityCard({
    required this.item,
    required this.isDark,
    required this.formatter,
    required this.dateFormatter,
    required this.onClaim,
  });

  final _ReferralItem item;
  final bool isDark;
  final String Function(num amount) formatter;
  final String Function(DateTime value) dateFormatter;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final Color statusColor = item.status.color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: statusColor.withValues(alpha: 0.12),
            child: Icon(Icons.person_rounded, color: statusColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${dateFormatter(item.joinedAt)} - ${formatter(item.reward)}',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (item.status == _ReferralStatus.claimable)
            FilledButton(
              onPressed: onClaim,
              style: FilledButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 38),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 11.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Claim'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.status.label,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyReferralState extends StatelessWidget {
  const _EmptyReferralState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: isDark ? _darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : _softBorder,
        ),
      ),
      child: Column(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: _primary.withValues(alpha: 0.12),
            child: const Icon(
              Icons.group_off_rounded,
              color: _primary,
              size: 20,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No referrals found',
            style: TextStyle(
              color: titleColor,
              fontSize: 13.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try another search or filter to see your referral activity.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedText,
              fontSize: 11.2,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferralClaimResultSheet extends StatelessWidget {
  const _ReferralClaimResultSheet({
    required this.name,
    required this.rewardAmount,
  });

  final String name;
  final String rewardAmount;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? _darkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color mutedText = isDark ? _darkMuted : const Color(0xFF4B5563);
    final double sheetHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sheetHeight),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color:
                        isDark
                            ? const Color(0xFF374151)
                            : const Color(0xFFC7CDDC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    shape: BoxShape.circle,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.28),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Reward Claimed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$rewardAmount was claimed successfully for $name.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 12.2,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ReferralFilter {
  all('All'),
  claimable('Claimable'),
  claimed('Claimed'),
  pending('Pending');

  const _ReferralFilter(this.label);

  final String label;
}

enum _ReferralStatus {
  pending('Pending', Color(0xFFF59E0B)),
  claimable('Claimable', _primary),
  claimed('Claimed', Color(0xFF16A34A));

  const _ReferralStatus(this.label, this.color);

  final String label;
  final Color color;
}

class _ReferralItem {
  const _ReferralItem({
    required this.id,
    required this.name,
    required this.joinedAt,
    required this.reward,
    required this.status,
  });

  final String id;
  final String name;
  final DateTime joinedAt;
  final double reward;
  final _ReferralStatus status;

  _ReferralItem copyWith({_ReferralStatus? status}) {
    return _ReferralItem(
      id: id,
      name: name,
      joinedAt: joinedAt,
      reward: reward,
      status: status ?? this.status,
    );
  }
}
