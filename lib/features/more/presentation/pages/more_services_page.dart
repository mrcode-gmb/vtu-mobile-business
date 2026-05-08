import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';
import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';
import '../../../shared/presentation/widgets/pts_data_mobile_ui.dart';

class MoreServicesPage extends StatelessWidget {
  const MoreServicesPage({super.key});

  Future<void> _handleBottomNavigation(
    BuildContext context,
    AppBottomNavDestination destination,
  ) async {
    await handleUtilityBottomNavigationTap(context, destination: destination);
  }

  void _openRoute(BuildContext context, String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    const List<_MoreServiceSection> sections = <_MoreServiceSection>[
      _MoreServiceSection(
        title: 'Recommend',
        items: <_MoreServiceItem>[
          _MoreServiceItem(
            title: 'Fund Wallet',
            icon: Icons.account_balance_rounded,
            accent: ptsDataSecondary,
            routeName: AppRoutes.fundWallet,
          ),
          _MoreServiceItem(
            title: 'Transfer',
            icon: Icons.send_rounded,
            accent: ptsDataAccent,
            routeName: AppRoutes.transfer,
          ),
        ],
      ),
      _MoreServiceSection(
        title: 'Rewards & Tools',
        items: <_MoreServiceItem>[
          _MoreServiceItem(
            title: 'Cashback',
            icon: Icons.card_giftcard_rounded,
            accent: ptsDataPrimaryDark,
            routeName: AppRoutes.cashback,
          ),
          _MoreServiceItem(
            title: 'Referrals',
            icon: Icons.people_alt_rounded,
            accent: ptsDataPrimary,
            routeName: AppRoutes.referrals,
          ),
          _MoreServiceItem(
            title: 'Cards & E-PIN',
            icon: Icons.credit_card_rounded,
            accent: ptsDataAccent,
            routeName: AppRoutes.cards,
          ),
        ],
      ),
      _MoreServiceSection(
        title: 'Bill Payments',
        items: <_MoreServiceItem>[
          _MoreServiceItem(
            title: 'Airtime',
            icon: Icons.call_rounded,
            accent: ptsDataPrimary,
            routeName: AppRoutes.buyAirtime,
          ),
          _MoreServiceItem(
            title: 'Data',
            icon: Icons.wifi_rounded,
            accent: ptsDataAccent,
            routeName: AppRoutes.buyData,
          ),
          _MoreServiceItem(
            title: 'Cable TV',
            icon: Icons.tv_rounded,
            accent: ptsDataSecondary,
            routeName: AppRoutes.tvSubscription,
          ),
          _MoreServiceItem(
            title: 'Electricity',
            icon: Icons.bolt_rounded,
            accent: ptsDataSky,
            routeName: AppRoutes.billPayment,
          ),
        ],
      ),
      _MoreServiceSection(
        title: 'Account',
        items: <_MoreServiceItem>[
          _MoreServiceItem(
            title: 'Dashboard',
            icon: Icons.dashboard_rounded,
            accent: ptsDataPrimaryDark,
            routeName: AppRoutes.dashboard,
          ),
          _MoreServiceItem(
            title: 'Transactions',
            icon: Icons.receipt_long_rounded,
            accent: ptsDataPrimary,
            routeName: AppRoutes.transactionHistory,
          ),
          _MoreServiceItem(
            title: 'Virtual Accounts',
            icon: Icons.account_balance_wallet_outlined,
            accent: ptsDataPrimaryDark,
            routeName: AppRoutes.virtualAccounts,
          ),
          _MoreServiceItem(
            title: 'Notifications',
            icon: Icons.notifications_none_rounded,
            accent: ptsDataAccent,
            routeName: AppRoutes.notifications,
          ),
          _MoreServiceItem(
            title: 'News',
            icon: Icons.campaign_outlined,
            accent: ptsDataPrimary,
            routeName: AppRoutes.news,
          ),
          _MoreServiceItem(
            title: 'Support',
            icon: Icons.headset_mic_rounded,
            accent: ptsDataSecondary,
            routeName: AppRoutes.support,
          ),
          _MoreServiceItem(
            title: 'Settings',
            icon: Icons.settings_outlined,
            accent: ptsDataSky,
            routeName: AppRoutes.settings,
          ),
        ],
      ),
    ];

    return PtsDataPageScaffold(
      title: 'My Service',
      contentPadding: EdgeInsets.zero,
      selectedBottomNav: AppBottomNavDestination.home,
      onBottomNavigation:
          (AppBottomNavDestination destination) =>
              _handleBottomNavigation(context, destination),
      child: Container(
        color: isDark ? ptsDataDarkBackground : const Color(0xFFF6F7FB),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:
              sections
                  .map(
                    (_MoreServiceSection section) => Padding(
                      padding: EdgeInsets.only(
                        bottom: section == sections.last ? 0 : 12,
                      ),
                      child: _MoreServiceSectionCard(
                        section: section,
                        onSelect:
                            (String routeName) =>
                                _openRoute(context, routeName),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _MoreServiceSectionCard extends StatelessWidget {
  const _MoreServiceSectionCard({
    required this.section,
    required this.onSelect,
  });

  final _MoreServiceSection section;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: TextStyle(
              color: titleColor,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              int crossAxisCount =
                  section.items.length <= 3 ? section.items.length : 4;
              if (constraints.maxWidth < 320 && crossAxisCount == 4) {
                crossAxisCount = 3;
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: section.items.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 10,
                  childAspectRatio: crossAxisCount == 3 ? 1.16 : 0.94,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final _MoreServiceItem item = section.items[index];
                  return _MoreServiceTile(
                    item: item,
                    onTap: () => onSelect(item.routeName),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MoreServiceTile extends StatelessWidget {
  const _MoreServiceTile({required this.item, required this.onTap});

  final _MoreServiceItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF252A42);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, size: 18, color: item.accent),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: titleColor,
                fontSize: 11.3,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreServiceSection {
  const _MoreServiceSection({required this.title, required this.items});

  final String title;
  final List<_MoreServiceItem> items;
}

class _MoreServiceItem {
  const _MoreServiceItem({
    required this.title,
    required this.icon,
    required this.accent,
    required this.routeName,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String routeName;
}
