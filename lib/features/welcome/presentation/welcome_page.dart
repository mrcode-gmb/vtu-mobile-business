import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({required this.onToggleTheme, super.key});

  final VoidCallback onToggleTheme;

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  static const Duration _slideDuration = Duration(milliseconds: 4500);

  final List<_WelcomeSlide> _slides = const <_WelcomeSlide>[
    _WelcomeSlide(
      id: 1,
      title: 'Welcome to PTS DATA',
      description:
          'Buy airtime, buy data, and handle daily utility payments in one fast mobile flow.',
      primaryIcon: Icons.mobile_friendly_rounded,
      accents: <_WelcomeAccent>[
        _WelcomeAccent(
          icon: Icons.wifi_rounded,
          left: 10,
          top: 46,
          lightBackground: Color(0xFFE5E7EB),
          lightForeground: Color(0xFFB89CFF),
          darkBackground: Color(0x33B89CFF),
          darkForeground: Color(0xFFB89CFF),
        ),
        _WelcomeAccent(
          icon: Icons.bolt_rounded,
          right: 12,
          top: 62,
          lightBackground: Color(0xFFF3F4F6),
          lightForeground: Color(0xFFC9B5FF),
          darkBackground: Color(0x33C9B5FF),
          darkForeground: Color(0xFF86EFAC),
        ),
        _WelcomeAccent(
          icon: Icons.tv_rounded,
          left: 16,
          bottom: 66,
          lightBackground: Color(0xFFE5E7EB),
          lightForeground: Color(0xFFB89CFF),
          darkBackground: Color(0x33B89CFF),
          darkForeground: Color(0xFFB89CFF),
        ),
        _WelcomeAccent(
          icon: Icons.payments_rounded,
          right: 10,
          bottom: 52,
          lightBackground: Color(0xFFF3F4F6),
          lightForeground: Color(0xFF7FA0F5),
          darkBackground: Color(0x337FA0F5),
          darkForeground: Color(0xFF86EFAC),
        ),
      ],
    ),
    _WelcomeSlide(
      id: 2,
      title: 'Simplify Your Payments',
      description:
          'Fund wallet, pay electricity bills, and manage transactions with a clean banking-style experience.',
      primaryIcon: Icons.account_balance_wallet_rounded,
      accents: <_WelcomeAccent>[
        _WelcomeAccent(
          icon: Icons.shield_rounded,
          left: 10,
          top: 46,
          lightBackground: Color(0xFFE5E7EB),
          lightForeground: Color(0xFFB89CFF),
          darkBackground: Color(0x33B89CFF),
          darkForeground: Color(0xFFB89CFF),
        ),
        _WelcomeAccent(
          icon: Icons.credit_card_rounded,
          right: 12,
          top: 62,
          lightBackground: Color(0xFFF3F4F6),
          lightForeground: Color(0xFF7FA0F5),
          darkBackground: Color(0x337FA0F5),
          darkForeground: Color(0xFF86EFAC),
        ),
        _WelcomeAccent(
          icon: Icons.receipt_long_rounded,
          left: 20,
          bottom: 58,
          lightBackground: Color(0xFFF3F4F6),
          lightForeground: Color(0xFFC9B5FF),
          darkBackground: Color(0x33C9B5FF),
          darkForeground: Color(0xFF86EFAC),
        ),
        _WelcomeAccent(
          icon: Icons.account_balance_rounded,
          right: 12,
          bottom: 50,
          lightBackground: Color(0xFFE5E7EB),
          lightForeground: Color(0xFFB89CFF),
          darkBackground: Color(0x33B89CFF),
          darkForeground: Color(0xFFB89CFF),
        ),
      ],
    ),
    _WelcomeSlide(
      id: 3,
      title: 'Stay Ready Everywhere',
      description:
          'Track pricing, check recent services, and move from onboarding to action in a few taps.',
      primaryIcon: Icons.show_chart_rounded,
      accents: <_WelcomeAccent>[
        _WelcomeAccent(
          icon: Icons.signal_cellular_alt_rounded,
          left: 10,
          top: 46,
          lightBackground: Color(0xFFE5E7EB),
          lightForeground: Color(0xFFB89CFF),
          darkBackground: Color(0x33B89CFF),
          darkForeground: Color(0xFFB89CFF),
        ),
        _WelcomeAccent(
          icon: Icons.notifications_rounded,
          right: 12,
          top: 54,
          lightBackground: Color(0xFFF3F4F6),
          lightForeground: Color(0xFFC9B5FF),
          darkBackground: Color(0x33C9B5FF),
          darkForeground: Color(0xFF86EFAC),
        ),
        _WelcomeAccent(
          icon: Icons.receipt_long_rounded,
          left: 20,
          bottom: 58,
          lightBackground: Color(0xFFE5E7EB),
          lightForeground: Color(0xFFB89CFF),
          darkBackground: Color(0x33B89CFF),
          darkForeground: Color(0xFFB89CFF),
        ),
        _WelcomeAccent(
          icon: Icons.verified_user_rounded,
          right: 12,
          bottom: 50,
          lightBackground: Color(0xFFF3F4F6),
          lightForeground: Color(0xFF7FA0F5),
          darkBackground: Color(0x337FA0F5),
          darkForeground: Color(0xFF86EFAC),
        ),
      ],
    ),
  ];

  Timer? _autoPlayTimer;
  int _activeSlideIndex = 0;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = Timer.periodic(_slideDuration, (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _activeSlideIndex = (_activeSlideIndex + 1) % _slides.length;
      });
    });
  }

  void _setActiveSlide(int index) {
    setState(() {
      _activeSlideIndex = index;
    });
    _startAutoPlay();
  }

  void _openLogin() {
    Navigator.of(context).pushNamed(AppRoutes.login);
  }

  void _openRegister() {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    final _WelcomeSlide activeSlide = _slides[_activeSlideIndex];
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF171925) : const Color(0xFFF8FAFC),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double screenWidth = constraints.maxWidth;
              final double screenHeight = constraints.maxHeight;
              final double widthScale = (screenWidth / 390).clamp(0.82, 1.18);
              final double heightScale = (screenHeight / 844).clamp(0.66, 1.0);
              final double horizontalPadding = (16 * widthScale).clamp(
                14.0,
                24.0,
              );
              final double topPadding = (16 * heightScale).clamp(12.0, 18.0);
              final double bottomPadding = (18 * heightScale).clamp(14.0, 22.0);
              final double buttonHeight = (52 * heightScale).clamp(46.0, 52.0);
              final double baseSlideWidth =
                  (screenWidth - (horizontalPadding * 2)).clamp(250.0, 340.0);
              final double buttonGap = (12 * widthScale).clamp(10.0, 14.0);
              final double sectionGap = (12 * heightScale).clamp(10.0, 16.0);

              return ColoredBox(
                color: isDark ? const Color(0xFF22263A) : Colors.white,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    topPadding,
                    horizontalPadding,
                    bottomPadding,
                  ),
                  child: Column(
                    children: <Widget>[
                      _Header(
                        isDark: isDark,
                        onToggleTheme: widget.onToggleTheme,
                        scale: widthScale,
                      ),
                      SizedBox(height: sectionGap),
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: baseSlideWidth,
                              height: 520,
                              child: Column(
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 350,
                                          ),
                                          switchInCurve: Curves.easeOut,
                                          switchOutCurve: Curves.easeIn,
                                          child: _HeroPanel(
                                            key: ValueKey<int>(activeSlide.id),
                                            slide: activeSlide,
                                            isDark: isDark,
                                            availableWidth: baseSlideWidth,
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                        AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          child: Column(
                                            key: ValueKey<int>(activeSlide.id),
                                            children: <Widget>[
                                              Text(
                                                activeSlide.title,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      isDark
                                                          ? const Color(
                                                            0xFFF8FAFC,
                                                          )
                                                          : const Color(
                                                            0xFF020617,
                                                          ),
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w800,
                                                  height: 1.1,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                activeSlide.description,
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color:
                                                      isDark
                                                          ? const Color(
                                                            0xFFC7CDDC,
                                                          )
                                                          : const Color(
                                                            0xFF374151,
                                                          ),
                                                  fontSize: 14,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List<Widget>.generate(
                                      _slides.length,
                                      (int index) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: GestureDetector(
                                          onTap: () => _setActiveSlide(index),
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 200,
                                            ),
                                            height: 8,
                                            width:
                                                _activeSlideIndex == index
                                                    ? 24
                                                    : 8,
                                            decoration: BoxDecoration(
                                              color:
                                                  _activeSlideIndex == index
                                                      ? const Color(0xFFB89CFF)
                                                      : isDark
                                                      ? const Color(0xFF374151)
                                                      : const Color(0xFFC7CDDC),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      SizedBox(
                        height: buttonHeight,
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: FilledButton(
                                onPressed: _openRegister,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFB89CFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: (15 * widthScale).clamp(
                                      14.0,
                                      15.0,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('Register'),
                              ),
                            ),
                            SizedBox(width: buttonGap),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _openLogin,
                                style: OutlinedButton.styleFrom(
                                  backgroundColor:
                                      isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF8FAFC),
                                  foregroundColor:
                                      isDark
                                          ? const Color(0xFFF8FAFC)
                                          : const Color(0xFF7FA0F5),
                                  side: BorderSide(
                                    color:
                                        isDark
                                            ? const Color(0xFF374151)
                                            : const Color(0xFFD1D5DB),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: (15 * widthScale).clamp(
                                      14.0,
                                      15.0,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: const Text('Log In'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.isDark,
    required this.onToggleTheme,
    required this.scale,
  });

  final bool isDark;
  final VoidCallback onToggleTheme;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Image.asset(
          'assets/images/logo-removebg-preview.png',
          height: (44 * scale).clamp(38.0, 46.0),
          width: (44 * scale).clamp(38.0, 46.0),
          fit: BoxFit.contain,
        ),
        SizedBox(width: (10 * scale).clamp(8.0, 10.0)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'PTS DATA',
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFF8FAFC)
                          : const Color(0xFF0F172A),
                  fontSize: (14 * scale).clamp(13.0, 14.5),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Quick payments, one wallet',
                style: TextStyle(
                  color:
                      isDark
                          ? const Color(0xFFC7CDDC)
                          : const Color(0xFF4B5563),
                  fontSize: (12 * scale).clamp(11.0, 12.5),
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: onToggleTheme,
          style: IconButton.styleFrom(
            backgroundColor:
                isDark ? const Color(0xFF3A4054) : const Color(0xFFF3F4F6),
            foregroundColor:
                isDark ? const Color(0xFFE5E7EB) : const Color(0xFF374151),
          ),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          ),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.slide,
    required this.isDark,
    required this.availableWidth,
    super.key,
  });

  final _WelcomeSlide slide;
  final bool isDark;
  final double availableWidth;

  @override
  Widget build(BuildContext context) {
    final double heroWidth = (availableWidth * 0.72).clamp(210.0, 270.0);
    final double heroHeight = heroWidth * 1.23;
    final double bubbleSize = 40;
    final double accentIconSize = 18;
    final double deviceWidth = heroWidth * 0.59;
    final double deviceHeight = heroHeight * 0.72;

    return SizedBox(
      height: heroHeight,
      width: heroWidth,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: heroHeight * 0.12,
            left: heroWidth * 0.12,
            right: heroWidth * 0.12,
            child: Container(
              height: heroHeight * 0.42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    const Color(
                      0xFFB89CFF,
                    ).withValues(alpha: isDark ? 0.20 : 0.16),
                    const Color(0xFFC9B5FF).withValues(alpha: 0.08),
                  ],
                ),
              ),
            ),
          ),
          for (final _WelcomeAccent accent in slide.accents)
            Positioned(
              left: accent.left,
              right: accent.right,
              top: accent.top,
              bottom: accent.bottom,
              child: _AccentBubble(
                accent: accent,
                isDark: isDark,
                size: bubbleSize,
                iconSize: accentIconSize,
              ),
            ),
          Container(
            width: deviceWidth,
            height: deviceHeight,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF22263A) : Colors.white,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF414868) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  left: 14,
                  right: 14,
                  top: 14,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0xFF3A4054)
                              : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 40,
                  child: Container(
                    height: 76,
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? const Color(0x26B89CFF)
                              : const Color(0x14B89CFF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  right: 18,
                  bottom: 28,
                  child: Column(
                    children: <Widget>[
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? const Color(0xFF3A4054)
                                  : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 78,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? const Color(0xFF3A4054)
                                    : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Container(
                    height: 66,
                    width: 66,
                    decoration: BoxDecoration(
                      color: const Color(0xFFB89CFF),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      slide.primaryIcon,
                      color: Colors.white,
                      size: 34,
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

class _AccentBubble extends StatelessWidget {
  const _AccentBubble({
    required this.accent,
    required this.isDark,
    required this.size,
    required this.iconSize,
  });

  final _WelcomeAccent accent;
  final bool isDark;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: isDark ? accent.darkBackground : accent.lightBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          accent.icon,
          color: isDark ? accent.darkForeground : accent.lightForeground,
          size: iconSize,
        ),
      ),
    );
  }
}

class _WelcomeSlide {
  const _WelcomeSlide({
    required this.id,
    required this.title,
    required this.description,
    required this.primaryIcon,
    required this.accents,
  });

  final int id;
  final String title;
  final String description;
  final IconData primaryIcon;
  final List<_WelcomeAccent> accents;
}

class _WelcomeAccent {
  const _WelcomeAccent({
    required this.icon,
    required this.lightBackground,
    required this.lightForeground,
    required this.darkBackground,
    required this.darkForeground,
    this.left,
    this.right,
    this.top,
    this.bottom,
  });

  final IconData icon;
  final Color lightBackground;
  final Color lightForeground;
  final Color darkBackground;
  final Color darkForeground;
  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
}
