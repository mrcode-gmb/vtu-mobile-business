import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

const Color _navPrimary = Color(0xFFB89CFF);
const Color _navDarkSurface = Color(0xFF22263A);

enum AppBottomNavDestination { home, airtime, data, wallet, me }

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.isDark,
    required this.selectedDestination,
    required this.onSelect,
    super.key,
  });

  final bool isDark;
  final AppBottomNavDestination selectedDestination;
  final ValueChanged<AppBottomNavDestination> onSelect;

  @override
  Widget build(BuildContext context) {
    const List<_BottomNavItem> items = <_BottomNavItem>[
      _BottomNavItem(
        label: 'Home',
        icon: Icons.home_filled,
        destination: AppBottomNavDestination.home,
      ),
      _BottomNavItem(
        label: 'Airtime',
        icon: Icons.call_rounded,
        destination: AppBottomNavDestination.airtime,
      ),
      _BottomNavItem(
        label: 'Data',
        icon: Icons.wifi_rounded,
        destination: AppBottomNavDestination.data,
      ),
      _BottomNavItem(
        label: 'Wallet',
        icon: Icons.account_balance_wallet_rounded,
        destination: AppBottomNavDestination.wallet,
      ),
      _BottomNavItem(
        label: 'Me',
        icon: Icons.person_outline_rounded,
        destination: AppBottomNavDestination.me,
      ),
    ];

    return SafeArea(
      top: false,
      minimum: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 6),
        decoration: BoxDecoration(
          color: isDark ? _navDarkSurface : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
            ),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(
                0xFF111827,
              ).withValues(alpha: isDark ? 0.24 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children:
              items
                  .map(
                    (_BottomNavItem item) => Expanded(
                      child: _BottomNavTile(
                        item: item,
                        isDark: isDark,
                        active: item.destination == selectedDestination,
                        onTap: () => onSelect(item.destination),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

Future<void> handleAppBottomNavigationTap(
  BuildContext context, {
  required AppBottomNavDestination destination,
  required AppBottomNavDestination currentDestination,
}) async {
  if (destination == currentDestination) {
    return;
  }

  final NavigatorState navigator = Navigator.of(context);

  switch (destination) {
    case AppBottomNavDestination.home:
      await navigator.pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (Route<dynamic> route) => false,
      );
      return;
    case AppBottomNavDestination.airtime:
      if (currentDestination == AppBottomNavDestination.home) {
        await navigator.pushNamed(AppRoutes.buyAirtime);
      } else {
        await navigator.pushReplacementNamed(AppRoutes.buyAirtime);
      }
      return;
    case AppBottomNavDestination.data:
      if (currentDestination == AppBottomNavDestination.home) {
        await navigator.pushNamed(AppRoutes.buyData);
      } else {
        await navigator.pushReplacementNamed(AppRoutes.buyData);
      }
      return;
    case AppBottomNavDestination.wallet:
      if (currentDestination == AppBottomNavDestination.home) {
        await navigator.pushNamed(AppRoutes.fundWallet);
      } else {
        await navigator.pushReplacementNamed(AppRoutes.fundWallet);
      }
      return;
    case AppBottomNavDestination.me:
      if (currentDestination == AppBottomNavDestination.home) {
        await navigator.pushNamed(AppRoutes.me);
      } else {
        await navigator.pushReplacementNamed(AppRoutes.me);
      }
      return;
  }
}

Future<void> handleUtilityBottomNavigationTap(
  BuildContext context, {
  required AppBottomNavDestination destination,
}) async {
  final NavigatorState navigator = Navigator.of(context);

  switch (destination) {
    case AppBottomNavDestination.home:
      await navigator.pushNamedAndRemoveUntil(
        AppRoutes.dashboard,
        (Route<dynamic> route) => false,
      );
      return;
    case AppBottomNavDestination.airtime:
      await navigator.pushReplacementNamed(AppRoutes.buyAirtime);
      return;
    case AppBottomNavDestination.data:
      await navigator.pushReplacementNamed(AppRoutes.buyData);
      return;
    case AppBottomNavDestination.wallet:
      await navigator.pushReplacementNamed(AppRoutes.fundWallet);
      return;
    case AppBottomNavDestination.me:
      await navigator.pushReplacementNamed(AppRoutes.me);
      return;
  }
}

class _BottomNavTile extends StatelessWidget {
  const _BottomNavTile({
    required this.item,
    required this.isDark,
    required this.active,
    required this.onTap,
  });

  final _BottomNavItem item;
  final bool isDark;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color inactiveColor =
        isDark ? const Color(0xFFE5E7EB) : const Color(0xFF111827);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color:
                      active
                          ? _navPrimary.withValues(alpha: isDark ? 0.18 : 0.14)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  item.icon,
                  size: 17,
                  color: active ? _navPrimary : inactiveColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? _navPrimary : inactiveColor,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.destination,
  });

  final String label;
  final IconData icon;
  final AppBottomNavDestination destination;
}
