import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../../core/auth/app_session_service.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';
import '../../data/news_api_service.dart';

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  State<NewsPage> createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<NewsItem> _items = const <NewsItem>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    final String? token = await AppSessionService.instance.getApiToken();
    if (token == null || token.isEmpty) {
      await _handleUnauthorized();
      return;
    }

    final NewsApiResult result = await NewsApiService.instance.fetchNews(
      token: token,
      limit: 20,
    );
    if (!mounted) {
      return;
    }

    if (result.isUnauthorized) {
      await _handleUnauthorized();
      return;
    }

    if (result.isSuccess) {
      setState(() {
        _items = result.items;
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

  Future<void> _handleBottomNavigation(
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return PtsDataPageScaffold(
      title: 'News & Updates',
      onRefresh: _loadNews,
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
            'Latest announcements, service changes, and important updates from PTS DATA.',
            style: TextStyle(
              color: mutedText,
              fontSize: 12.2,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          PtsDataSectionHeader(
            title: 'Latest News',
            subtitle:
                'Fresh updates are shown here as soon as they are published.',
          ),
          const SizedBox(height: 12),
          if (!_isLoading && _items.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? ptsDataDarkSurface : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
                ),
              ),
              child: Text(
                'No news items are available right now.',
                style: TextStyle(
                  color: mutedText,
                  fontSize: 11.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
          else
            ..._items.map(
              (NewsItem item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _NewsCard(item: item, isDark: isDark),
              ),
            ),
        ],
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.item, required this.isDark});

  final NewsItem item;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? ptsDataPrimary.withValues(alpha: 0.16)
                          : ptsDataSoftTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.campaign_rounded,
                  color: ptsDataPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.message,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item.createdLabel.isNotEmpty
                ? item.createdLabel
                : formatPtsDataDate(item.createdAt),
            style: TextStyle(
              color: mutedText,
              fontSize: 10.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
