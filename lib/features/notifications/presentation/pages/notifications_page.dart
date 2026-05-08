import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../data/notification_api_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final TextEditingController _searchController = TextEditingController();

  List<_NotificationItem> _items = <_NotificationItem>[];
  bool _isLoading = true;
  bool _isMarkingAllRead = false;

  _NotificationCategoryFilter _selectedFilter = _NotificationCategoryFilter.all;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
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

  Future<void> _loadNotifications() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    final NotificationsApiResult result = await NotificationApiService.instance
        .fetchNotifications(token: token);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _items = result.notifications
            .map(_NotificationItem.fromApi)
            .toList(growable: true);
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

  List<_NotificationItem> get _filteredItems {
    final String query = _searchController.text.trim().toLowerCase();

    return _items.where((_NotificationItem item) {
      final bool matchesFilter =
          _selectedFilter == _NotificationCategoryFilter.all ||
          item.category.filter == _selectedFilter;

      if (!matchesFilter) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      return item.title.toLowerCase().contains(query) ||
          item.message.toLowerCase().contains(query) ||
          item.category.label.toLowerCase().contains(query);
    }).toList();
  }

  int get _unreadCount =>
      _items.where((_NotificationItem item) => !item.isRead).length;

  int get _transactionCount =>
      _items
          .where(
            (_NotificationItem item) =>
                item.category == _NotificationCategory.transaction,
          )
          .length;

  int get _supportCount =>
      _items
          .where(
            (_NotificationItem item) =>
                item.category == _NotificationCategory.support,
          )
          .length;

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0 || _isMarkingAllRead) {
      return;
    }

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    setState(() {
      _isMarkingAllRead = true;
    });

    final NotificationMutationApiResult result = await NotificationApiService
        .instance
        .markAllAsRead(token: token);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    setState(() {
      _isMarkingAllRead = false;
      if (result.isSuccess) {
        for (final _NotificationItem item in _items) {
          item.isRead = true;
        }
      }
    });

    if (!result.isSuccess &&
        result.message != null &&
        result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _markNotificationAsRead(_NotificationItem item) async {
    if (item.isRead) {
      return;
    }

    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    final NotificationMutationApiResult result = await NotificationApiService
        .instance
        .markAsRead(token: token, notificationId: item.id);
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() => item.isRead = true);
      return;
    }

    if (result.message != null && result.message!.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message!)));
    }
  }

  Future<void> _openNotification(_NotificationItem item) async {
    if (!item.isRead) {
      await _markNotificationAsRead(item);
      if (!mounted) {
        return;
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _NotificationDetailSheet(item: item);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);
    final List<_NotificationItem> visibleItems = _filteredItems;

    return PtsDataPageScaffold(
      title: 'Notifications',
      contentPadding: EdgeInsets.zero,
      onRefresh: _loadNotifications,
      selectedBottomNav: AppBottomNavDestination.me,
      onBottomNavigation:
          (AppBottomNavDestination destination) =>
              _handleBottomNavigation(destination),
      child: Container(
        color: isDark ? ptsDataDarkBackground : const Color(0xFFF6F7FB),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _NotificationsHeroPanel(
              isDark: isDark,
              unreadCount: _unreadCount,
              transactionCount: _transactionCount,
              supportCount: _supportCount,
              isBusy: _isLoading || _isMarkingAllRead,
              searchController: _searchController,
              selectedFilter: _selectedFilter,
              onSearchChanged: () => setState(() {}),
              onSelectFilter:
                  (_NotificationCategoryFilter filter) =>
                      setState(() => _selectedFilter = filter),
              onMarkAllRead: _unreadCount == 0 ? null : _markAllAsRead,
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PtsDataSectionHeader(
                title: 'Recent Alerts',
                subtitle: 'Tap any alert to read the full details.',
              ),
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                decoration: BoxDecoration(
                  color: isDark ? ptsDataDarkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              )
            else if (visibleItems.isEmpty)
              Container(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                decoration: BoxDecoration(
                  color: isDark ? ptsDataDarkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: <Widget>[
                    Icon(
                      Icons.notifications_off_rounded,
                      size: 28,
                      color: mutedText,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No notifications found',
                      style: TextStyle(
                        color:
                            isDark
                                ? const Color(0xFFF8FAFC)
                                : const Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try another filter or search keyword.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...visibleItems.map(
                (_NotificationItem item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NotificationTile(
                    item: item,
                    isDark: isDark,
                    onTap: () => _openNotification(item),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsHeroPanel extends StatelessWidget {
  const _NotificationsHeroPanel({
    required this.isDark,
    required this.unreadCount,
    required this.transactionCount,
    required this.supportCount,
    required this.isBusy,
    required this.searchController,
    required this.selectedFilter,
    required this.onSearchChanged,
    required this.onSelectFilter,
    required this.onMarkAllRead,
  });

  final bool isDark;
  final int unreadCount;
  final int transactionCount;
  final int supportCount;
  final bool isBusy;
  final TextEditingController searchController;
  final _NotificationCategoryFilter selectedFilter;
  final VoidCallback onSearchChanged;
  final ValueChanged<_NotificationCategoryFilter> onSelectFilter;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Inbox Summary',
                      style: TextStyle(
                        color: titleColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Track payments, security updates, promos, and support replies from one clean inbox.',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11.3,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: isBusy ? null : onMarkAllRead,
                style: TextButton.styleFrom(
                  foregroundColor: ptsDataPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(isBusy ? 'Syncing...' : 'Mark all read'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: _NotificationMetricTile(
                  label: 'Unread',
                  value: '$unreadCount',
                  icon: Icons.mark_email_unread_rounded,
                  accent: ptsDataPrimary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NotificationMetricTile(
                  label: 'Payments',
                  value: '$transactionCount',
                  icon: Icons.receipt_long_rounded,
                  accent: ptsDataSecondary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NotificationMetricTile(
                  label: 'Support',
                  value: '$supportCount',
                  icon: Icons.support_agent_rounded,
                  accent: ptsDataAccent,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: (_) => onSearchChanged(),
            decoration: buildPtsDataFieldDecoration(
              context: context,
              hintText: 'Search notifications',
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 18,
                color: Color(0xFF4B5563),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  _NotificationCategoryFilter.values
                      .map(
                        (_NotificationCategoryFilter filter) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _NotificationFilterChip(
                            label: filter.label,
                            selected: filter == selectedFilter,
                            onTap: () => onSelectFilter(filter),
                            isDark: isDark,
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationMetricTile extends StatelessWidget {
  const _NotificationMetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.isDark,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 14, color: accent),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A),
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: isDark ? ptsDataDarkMuted : const Color(0xFF4B5563),
              fontSize: 10.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationFilterChip extends StatelessWidget {
  const _NotificationFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              selected
                  ? ptsDataPrimary
                  : (isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC)),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                selected
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFFE5E7EB)
                        : const Color(0xFF374151)),
            fontSize: 11.2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final _NotificationItem item;
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: isDark ? ptsDataDarkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.category.accent.withValues(
                    alpha: isDark ? 0.18 : 0.12,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  item.category.icon,
                  size: 19,
                  color: item.category.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12.8,
                              fontWeight:
                                  item.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.isRead) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: ptsDataPrimary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: item.category.accent.withValues(
                              alpha: isDark ? 0.16 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.category.label,
                            style: TextStyle(
                              color: item.category.accent,
                              fontSize: 10.2,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formatPtsDataDate(item.createdAt),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: mutedText,
                              fontSize: 10.6,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationDetailSheet extends StatelessWidget {
  const _NotificationDetailSheet({required this.item});

  final _NotificationItem item;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color surfaceColor = isDark ? ptsDataDarkSurface : Colors.white;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFD6E3F5),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.category.accent.withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    item.category.icon,
                    size: 22,
                    color: item.category.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        item.title,
                        style: TextStyle(
                          color:
                              isDark
                                  ? const Color(0xFFF8FAFC)
                                  : const Color(0xFF0F172A),
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${item.category.label}  •  ${formatPtsDataDate(item.createdAt)}',
                        style: TextStyle(
                          color: mutedText,
                          fontSize: 11.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
                ),
              ),
              child: Text(
                item.message,
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFE5E7EB)
                          : const Color(0xFF374151),
                  fontSize: 12.6,
                  fontWeight: FontWeight.w500,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: ptsDataPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NotificationCategoryFilter {
  all('All'),
  transaction('Transactions'),
  security('Security'),
  reward('Rewards'),
  support('Support'),
  promo('Promos');

  const _NotificationCategoryFilter(this.label);

  final String label;
}

enum _NotificationCategory {
  transaction(
    label: 'Transaction',
    icon: Icons.receipt_long_rounded,
    accent: ptsDataPrimary,
    filter: _NotificationCategoryFilter.transaction,
  ),
  security(
    label: 'Security',
    icon: Icons.verified_user_rounded,
    accent: ptsDataAccent,
    filter: _NotificationCategoryFilter.security,
  ),
  reward(
    label: 'Reward',
    icon: Icons.card_giftcard_rounded,
    accent: ptsDataSecondary,
    filter: _NotificationCategoryFilter.reward,
  ),
  support(
    label: 'Support',
    icon: Icons.support_agent_rounded,
    accent: Color(0xFF0EA5E9),
    filter: _NotificationCategoryFilter.support,
  ),
  promo(
    label: 'Promo',
    icon: Icons.local_offer_rounded,
    accent: Color(0xFF14B8A6),
    filter: _NotificationCategoryFilter.promo,
  );

  const _NotificationCategory({
    required this.label,
    required this.icon,
    required this.accent,
    required this.filter,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final _NotificationCategoryFilter filter;

  static _NotificationCategory fromApi({
    required String category,
    required String title,
    required String message,
  }) {
    final String raw = category.trim().toLowerCase();
    final String content = '$title $message'.toLowerCase();

    if (raw.contains('security') ||
        content.contains('login') ||
        content.contains('password') ||
        content.contains('security')) {
      return _NotificationCategory.security;
    }

    if (raw.contains('support') ||
        content.contains('support') ||
        content.contains('ticket')) {
      return _NotificationCategory.support;
    }

    if (raw.contains('reward') ||
        raw.contains('bonus') ||
        content.contains('cashback') ||
        content.contains('bonus') ||
        content.contains('referral')) {
      return _NotificationCategory.reward;
    }

    if (raw.contains('promo') ||
        raw.contains('info') ||
        content.contains('promo') ||
        content.contains('discount') ||
        content.contains('announcement')) {
      return _NotificationCategory.promo;
    }

    return _NotificationCategory.transaction;
  }
}

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String message;
  final _NotificationCategory category;
  final DateTime createdAt;
  bool isRead;

  factory _NotificationItem.fromApi(NotificationApiItem item) {
    return _NotificationItem(
      id: item.id,
      title: item.title,
      message: item.message,
      category: _NotificationCategory.fromApi(
        category: item.category,
        title: item.title,
        message: item.message,
      ),
      createdAt: item.createdAt,
      isRead: item.isRead,
    );
  }
}
