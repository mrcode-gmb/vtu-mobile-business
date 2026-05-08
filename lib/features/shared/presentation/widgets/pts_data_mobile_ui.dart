import 'package:flutter/material.dart';

import '../../../navigation/presentation/widgets/app_bottom_navigation.dart';

const Color ptsDataPrimary = Color(0xFFB89CFF);
const Color ptsDataPrimaryDark = Color(0xFF7FA0F5);
const Color ptsDataSecondary = Color(0xFFC9B5FF);
const Color ptsDataAccent = Color(0xFF7FA0F5);
const Color ptsDataSky = Color(0xFF9AA7FF);
const Color ptsDataTint = Color(0xFFF3F4F6);
const Color ptsDataSoftTint = Color(0xFFF8FAFC);
const Color ptsDataSurface = Color(0xFFFFFFFF);
const Color ptsDataSoftBorder = Color(0xFFE5E7EB);
const Color ptsDataDarkBackground = Color(0xFF171925);
const Color ptsDataDarkSurface = Color(0xFF22263A);
const Color ptsDataDarkPanel = Color(0xFF252A42);
const Color ptsDataDarkMuted = Color(0xFFC7CDDC);

class PtsDataPageScaffold extends StatelessWidget {
  const PtsDataPageScaffold({
    required this.title,
    required this.child,
    required this.selectedBottomNav,
    required this.onBottomNavigation,
    this.contentPadding = const EdgeInsets.fromLTRB(18, 10, 18, 24),
    this.onRefresh,
    super.key,
  });

  final String title;
  final Widget child;
  final AppBottomNavDestination selectedBottomNav;
  final ValueChanged<AppBottomNavDestination> onBottomNavigation;
  final EdgeInsetsGeometry contentPadding;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? ptsDataDarkBackground : Colors.white;
    final Color pageSurface = isDark ? ptsDataDarkSurface : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);

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
          title,
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double bottomPadding =
                100 + MediaQuery.paddingOf(context).bottom;

            final Widget scrollView = SingleChildScrollView(
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
                  child: Padding(padding: contentPadding, child: child),
                ),
              ),
            );

            if (onRefresh == null) {
              return scrollView;
            }

            return RefreshIndicator.adaptive(
              color: ptsDataPrimary,
              onRefresh: onRefresh!,
              child: scrollView,
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        isDark: isDark,
        selectedDestination: selectedBottomNav,
        onSelect: onBottomNavigation,
      ),
    );
  }
}

class PtsDataSurfaceCard extends StatelessWidget {
  const PtsDataSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? ptsDataDarkSurface : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF3A4054) : const Color(0xFFE5E7EB),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(
              0xFF171925,
            ).withValues(alpha: isDark ? 0.32 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PtsDataSectionHeader extends StatelessWidget {
  const PtsDataSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color subtitleColor =
        isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: TextStyle(
                  color: titleColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

InputDecoration buildPtsDataFieldDecoration({
  required BuildContext context,
  required String hintText,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  final bool isDark = Theme.of(context).brightness == Brightness.dark;
  final Color mutedText = isDark ? ptsDataDarkMuted : const Color(0xFF4B5563);

  return InputDecoration(
    hintText: hintText,
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: isDark ? ptsDataDarkPanel : const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: isDark ? const Color(0xFF3A4054) : ptsDataSoftBorder,
      ),
    ),
    focusedBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
      borderSide: BorderSide(color: ptsDataPrimary, width: 1.3),
    ),
    hintStyle: TextStyle(color: mutedText, fontSize: 12.5),
  );
}

String formatPtsDataCurrency(num amount) {
  final bool isNegative = amount < 0;
  final String fixed = amount.abs().toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String whole = parts.first.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match match) => ',',
  );
  return '${isNegative ? '-' : ''}\u20A6$whole.${parts.last}';
}

String formatPtsDataDate(DateTime value) {
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

  final String month = months[value.month - 1];
  final int hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final String minute = value.minute.toString().padLeft(2, '0');
  final String suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$month ${value.day}, ${value.year}, $hour:$minute $suffix';
}
