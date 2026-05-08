// app/app.dart
import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/auth/app_session_service.dart';
import '../core/settings/app_settings_service.dart';
import '../features/airtime/presentation/pages/buy_airtime_page.dart';
import '../features/account/presentation/pages/change_password_page.dart';
import '../features/account/presentation/pages/personal_information_page.dart';
import '../features/account/presentation/pages/transaction_pin_page.dart';
import '../features/account/presentation/pages/verification_limits_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/quick_login_page.dart';
import '../features/auth/presentation/pages/register_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/bills/presentation/pages/bill_payment_page.dart';
import '../features/cards/presentation/pages/cards_page.dart';
import '../features/cashback/presentation/pages/cashback_page.dart';
import '../features/data/presentation/pages/buy_data_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/me/presentation/pages/me_page.dart';
import '../features/more/presentation/pages/more_services_page.dart';
import '../features/news/presentation/pages/news_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/referrals/presentation/pages/referrals_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/support/presentation/pages/support_page.dart';
import '../features/transactions/presentation/pages/transaction_history_page.dart';
import '../features/transfer/presentation/pages/transfer_page.dart';
import '../features/tv/presentation/pages/tv_subscription_page.dart';
import '../features/virtual_accounts/presentation/pages/virtual_accounts_page.dart';
import '../features/wallet/presentation/pages/fund_wallet_page.dart';
import '../features/welcome/presentation/welcome_page.dart';
import 'app_routes.dart';

class PtsDataApp extends StatefulWidget {
  const PtsDataApp({super.key});

  @override
  State<PtsDataApp> createState() => _PtsDataAppState();
}

class _PtsDataAppState extends State<PtsDataApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  static const Duration _startupSplashDuration = Duration(seconds: 3);

  ThemeMode _themeMode = ThemeMode.dark;
  String? _pendingLaunchRoute;
  bool _didHandleLaunchRoute = false;
  bool _showStartupSplash = true;
  Timer? _startupSplashTimer;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _resolveLaunchRoute();
    _startStartupSplash();
  }

  @override
  void dispose() {
    _startupSplashTimer?.cancel();
    super.dispose();
  }

  void _toggleTheme() {
    _setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  void _setThemeMode(ThemeMode mode) {
    final ThemeMode effectiveMode =
        mode == ThemeMode.system ? ThemeMode.dark : mode;

    if (_themeMode == effectiveMode) {
      return;
    }

    setState(() {
      _themeMode = effectiveMode;
    });
    AppSettingsService.instance.setThemeMode(effectiveMode);
  }

  Future<void> _resolveLaunchRoute() async {
    final String routeName = await AppSessionService.instance.getLaunchRoute();
    if (!mounted || routeName == AppRoutes.welcome) {
      return;
    }

    setState(() {
      _pendingLaunchRoute = routeName;
      _didHandleLaunchRoute = false;
    });
  }

  Future<void> _loadThemeMode() async {
    final ThemeMode themeMode =
        await AppSettingsService.instance.getThemeMode();
    if (!mounted) {
      return;
    }

    setState(() {
      _themeMode = themeMode;
    });
  }

  void _startStartupSplash() {
    _startupSplashTimer?.cancel();
    _startupSplashTimer = Timer(_startupSplashDuration, () {
      if (!mounted) {
        return;
      }

      setState(() {
        _showStartupSplash = false;
      });
    });
  }

  void _scheduleLaunchRedirect() {
    if (_didHandleLaunchRoute || _pendingLaunchRoute == null) {
      return;
    }

    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    _didHandleLaunchRoute = true;
    final String routeName = _pendingLaunchRoute!;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      navigator.pushReplacementNamed(routeName);
      _pendingLaunchRoute = null;
    });
  }

  ThemeData _buildTheme(Brightness brightness) {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFFB89CFF),
      brightness: brightness,
    );

    // Use a bundled text font so web builds can render currency symbols reliably.
    final Typography typography = Typography.material2021(
      platform: defaultTargetPlatform,
    );
    final TextTheme baseTextTheme =
        brightness == Brightness.dark ? typography.white : typography.black;

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          brightness == Brightness.dark
              ? const Color(0xFF171925)
              : const Color(0xFFF9FAFB),
      fontFamily: 'NotoSans',
      useMaterial3: true,
      typography: typography,
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.15,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 14, height: 1.4),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 12.5,
          height: 1.35,
        ),
        labelLarge: baseTextTheme.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
        labelSmall: baseTextTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          height: 1.2,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            brightness == Brightness.dark
                ? const Color(0xFF252A42)
                : const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dividerColor:
          brightness == Brightness.dark
              ? const Color(0xFF46517A)
              : const Color(0xFFE5E7EB),
    );
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLaunchRedirect();

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'PTS DATA',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      scrollBehavior: const _PtsDataScrollBehavior(),
      builder: (BuildContext context, Widget? child) {
        return Stack(
          children: <Widget>[
            Positioned.fill(child: child ?? const SizedBox.shrink()),
            IgnorePointer(
              ignoring: true,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child:
                    _showStartupSplash
                        ? const _StartupSplashOverlay()
                        : const SizedBox.shrink(),
              ),
            ),
          ],
        );
      },
      initialRoute: AppRoutes.welcome,
      onGenerateRoute: (RouteSettings settings) {
        final Widget page;

        switch (settings.name) {
          case AppRoutes.login:
            page = LoginPage(onToggleTheme: _toggleTheme);
            break;
          case AppRoutes.quickLogin:
            page = QuickLoginPage(onToggleTheme: _toggleTheme);
            break;
          case AppRoutes.register:
            page = RegisterPage(onToggleTheme: _toggleTheme);
            break;
          case AppRoutes.forgotPassword:
            page = ForgotPasswordPage(onToggleTheme: _toggleTheme);
            break;
          case AppRoutes.resetPassword:
            page = ResetPasswordPage(
              onToggleTheme: _toggleTheme,
              routeArguments: settings.arguments,
            );
            break;
          case AppRoutes.dashboard:
            page = DashboardPage(onToggleTheme: _toggleTheme);
            break;
          case AppRoutes.buyAirtime:
            page = const BuyAirtimePage();
            break;
          case AppRoutes.buyData:
            page = const BuyDataPage();
            break;
          case AppRoutes.fundWallet:
            page = const FundWalletPage();
            break;
          case AppRoutes.transactionHistory:
            page = const TransactionHistoryPage();
            break;
          case AppRoutes.tvSubscription:
            page = const TvSubscriptionPage();
            break;
          case AppRoutes.billPayment:
            page = const BillPaymentPage();
            break;
          case AppRoutes.transfer:
            page = const TransferPage();
            break;
          case AppRoutes.referrals:
            page = const ReferralsPage();
            break;
          case AppRoutes.cashback:
            page = const CashbackPage();
            break;
          case AppRoutes.cards:
            page = const CardsPage();
            break;
          case AppRoutes.moreServices:
            page = const MoreServicesPage();
            break;
          case AppRoutes.notifications:
            page = const NotificationsPage();
            break;
          case AppRoutes.support:
            page = const SupportPage();
            break;
          case AppRoutes.news:
            page = const NewsPage();
            break;
          case AppRoutes.virtualAccounts:
            page = const VirtualAccountsPage();
            break;
          case AppRoutes.settings:
            page = SettingsPage(
              themeMode: _themeMode,
              onThemeModeChanged: _setThemeMode,
            );
            break;
          case AppRoutes.me:
            page = const MePage();
            break;
          case AppRoutes.personalInformation:
            page = const PersonalInformationPage();
            break;
          case AppRoutes.verificationLimits:
            page = const VerificationLimitsPage();
            break;
          case AppRoutes.changePassword:
            page = const ChangePasswordPage();
            break;
          case AppRoutes.transactionPin:
            page = const TransactionPinPage();
            break;
          case AppRoutes.welcome:
          default:
            page = WelcomePage(onToggleTheme: _toggleTheme);
            break;
        }

        return MaterialPageRoute<void>(
          builder: (_) => page,
          settings: settings,
        );
      },
    );
  }
}

class _PtsDataScrollBehavior extends MaterialScrollBehavior {
  const _PtsDataScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const <PointerDeviceKind>{
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class _StartupSplashOverlay extends StatefulWidget {
  const _StartupSplashOverlay();

  @override
  State<_StartupSplashOverlay> createState() => _StartupSplashOverlayState();
}

class _StartupSplashOverlayState extends State<_StartupSplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color background =
        isDark ? const Color(0xFF171925) : const Color(0xFFF8FAFC);
    final Color titleColor =
        isDark ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);
    final Color subtitleColor =
        isDark ? const Color(0xFFC7CDDC) : const Color(0xFF4B5563);

    return ColoredBox(
      key: const ValueKey<String>('startup-splash'),
      color: background,
      child: SafeArea(
        child: Center(
          child: Semantics(
            label: 'PTS DATA loading. Quick payments, one wallet.',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 112,
                      height: 112,
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? const Color(0xFF202331)
                                : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Image.asset(
                        'assets/images/logo-removebg-preview.png',
                        fit: BoxFit.contain,
                        errorBuilder: (
                          BuildContext context,
                          Object error,
                          StackTrace? stackTrace,
                        ) {
                          return const Icon(
                            Icons.flutter_dash_rounded,
                            size: 58,
                            color: Color(0xFFB89CFF),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: 220,
                      height: 52,
                      child: CustomPaint(
                        painter: _SplashWordmarkPainter(
                          titleColor: titleColor,
                          subtitleColor: subtitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 52,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (BuildContext context, Widget? child) {
                          final double progress = _controller.value;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List<Widget>.generate(3, (int index) {
                              final double distance =
                                  (progress * 3 - index).abs();
                              final double opacity = (1 -
                                      distance.clamp(0.0, 1.0))
                                  .clamp(0.35, 1.0);
                              final double scale =
                                  0.85 +
                                  ((1 - distance.clamp(0.0, 1.0)) * 0.25);

                              return Transform.scale(
                                scale: scale,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFB89CFF,
                                    ).withValues(alpha: opacity),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplashWordmarkPainter extends CustomPainter {
  const _SplashWordmarkPainter({
    required this.titleColor,
    required this.subtitleColor,
  });

  final Color titleColor;
  final Color subtitleColor;

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter titlePainter = TextPainter(
      text: TextSpan(
        text: 'PTS DATA',
        style: TextStyle(
          color: titleColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);

    final TextPainter subtitlePainter = TextPainter(
      text: TextSpan(
        text: 'Quick payments, one wallet',
        style: TextStyle(
          color: subtitleColor,
          fontSize: 12.8,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width);

    final double titleX = (size.width - titlePainter.width) / 2;
    titlePainter.paint(canvas, Offset(titleX, 0));

    final double subtitleX = (size.width - subtitlePainter.width) / 2;
    subtitlePainter.paint(canvas, Offset(subtitleX, titlePainter.height + 6));
  }

  @override
  bool shouldRepaint(covariant _SplashWordmarkPainter oldDelegate) {
    return oldDelegate.titleColor != titleColor ||
        oldDelegate.subtitleColor != subtitleColor;
  }
}
