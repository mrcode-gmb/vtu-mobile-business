import 'package:flutter/material.dart';

class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    required this.onToggleTheme,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    super.key,
    this.topActionLabel,
    this.onTopActionTap,
    this.progressTitle,
    this.progressLabel,
    this.progressValue,
  });

  final VoidCallback onToggleTheme;
  final String title;
  final String subtitle;
  final String? progressTitle;
  final String? progressLabel;
  final double? progressValue;
  final Widget child;
  final Widget footer;
  final String? topActionLabel;
  final VoidCallback? onTopActionTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor =
        isDark ? const Color(0xFF171925) : const Color(0xFFF8FAFC);
    final Color panelColor = isDark ? const Color(0xFF202331) : Colors.white;
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF111827);
    final Color subtitleColor =
        isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: <Widget>[
            Positioned(
              top: -30,
              right: -40,
              child: Container(
                width: 210,
                height: 170,
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? const Color(0xFF252A42)
                          : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(72),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
                    child: Row(
                      children: <Widget>[
                        _TopCircleButton(
                          isDark: isDark,
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            final NavigatorState navigator = Navigator.of(
                              context,
                            );
                            if (navigator.canPop()) {
                              navigator.pop();
                            }
                          },
                        ),
                        const Spacer(),
                        if (topActionLabel != null && onTopActionTap != null)
                          TextButton(
                            onPressed: onTopActionTap,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              backgroundColor:
                                  isDark
                                      ? const Color(0xFF252A42)
                                      : const Color(0xFFF8FAFC),
                              foregroundColor:
                                  isDark
                                      ? const Color(0xFFD1D5DB)
                                      : const Color(0xFF7FA0F5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              topActionLabel!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: panelColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(34),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 18,
                            offset: const Offset(0, -4),
                          ),
                        ],
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              title,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                height: 1.15,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                            ),
                            if (progressTitle != null &&
                                progressLabel != null &&
                                progressValue != null) ...<Widget>[
                              const SizedBox(height: 26),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                runSpacing: 4,
                                children: <Widget>[
                                  Text(
                                    progressTitle!,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    progressLabel!,
                                    style: TextStyle(
                                      color: subtitleColor,
                                      fontSize: 13.2,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 7,
                                    child: _ProgressBarSegment(
                                      isDark: isDark,
                                      active: true,
                                      fill: progressValue!.clamp(0.0, 1.0),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    flex: 3,
                                    child: _ProgressBarSegment(
                                      isDark: isDark,
                                      active: false,
                                      fill: 0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ] else ...<Widget>[const SizedBox(height: 24)],
                            child,
                            const SizedBox(height: 22),
                            DefaultTextStyle(
                              style: TextStyle(
                                color: subtitleColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.45,
                              ),
                              textAlign: TextAlign.center,
                              child: footer,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopCircleButton extends StatelessWidget {
  const _TopCircleButton({
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark ? const Color(0xFF252A42) : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: isDark ? const Color(0xFFF8FAFC) : const Color(0xFF252A42),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ProgressBarSegment extends StatelessWidget {
  const _ProgressBarSegment({
    required this.isDark,
    required this.active,
    required this.fill,
  });

  final bool isDark;
  final bool active;
  final double fill;

  @override
  Widget build(BuildContext context) {
    final Color background =
        active
            ? (isDark ? const Color(0xFF252A42) : const Color(0xFFE5E7EB))
            : (isDark ? const Color(0xFF252A42) : const Color(0xFFF3F4F6));
    final Color fillColor =
        isDark ? const Color(0xFF9AA7FF) : const Color(0xFFB89CFF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 6,
        color: background,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: active ? fill.clamp(0.0, 1.0) : 0,
          child: Container(color: fillColor),
        ),
      ),
    );
  }
}
