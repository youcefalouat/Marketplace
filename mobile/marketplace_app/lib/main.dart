import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'services/api_service.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/annonces_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/reservation_provider.dart';
import 'providers/sellers_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init failed (likely missing config): $e');
  }
  runApp(const MarketplaceApp());
}

class MarketplaceApp extends StatefulWidget {
  const MarketplaceApp({super.key});

  @override
  State<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends State<MarketplaceApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initDeepLinks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Doze mode kills TCP sockets while the app is backgrounded.
      // Flush the HTTP connection pool so the first post-resume request
      // always opens a fresh connection instead of hanging on a dead socket.
      ApiService().flushHttpClient();
    }

    // Only "resumed" counts as actually visible to the user — inactive,
    // paused, hidden and detached should never auto-mark messages as read.
    final ctx = _navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      Provider.of<ChatProvider>(ctx, listen: false)
          .setForeground(state == AppLifecycleState.resumed);
    }
  }

  Future<void> _initDeepLinks() async {
    final appLinks = AppLinks();

    // Handle initial link (app launched from a deep link)
    try {
      final initialUri = await appLinks.getInitialLink();
      if (initialUri != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialUri);
        });
      }
    } catch (_) {}

    // Handle links while app is already running
    appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  Future<void> _handleDeepLink(Uri uri) async {
    if (uri.scheme == 'myapp' && uri.host == 'email-verified') {
      // Refresh user profile so emailVerified flag is up to date
      final ctx = _navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        try {
          await Provider.of<AuthProvider>(ctx, listen: false).refreshUser();
        } catch (_) {}
      }

      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );

      // Show a brief success message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navCtx = _navigatorKey.currentContext;
        if (navCtx != null && navCtx.mounted) {
          ScaffoldMessenger.of(navCtx).showSnackBar(
            const SnackBar(
              content: Text('Votre adresse email a été vérifiée avec succès.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AnnoncesProvider()),
        ChangeNotifierProvider(create: (_) => ReservationProvider()),
        ChangeNotifierProvider(create: (_) => SellersProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, authProvider, chatProvider) {
            final provider = chatProvider ?? ChatProvider();
            provider.setAuthSession(
              token: authProvider.token,
              userId: authProvider.user?.id,
            );
            return provider;
          },
        ),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'Marketplace',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: localeProvider.locale,
            theme: _buildTheme(Brightness.light),
            darkTheme: _buildTheme(Brightness.dark),
            themeMode: themeProvider.themeMode,
            home: HomeScreen(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final appColors = isDark ? AppColors.dark : AppColors.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: appColors.primary,
      onPrimary: appColors.textOnPrimary,
      secondary: appColors.accent,
      onSecondary: appColors.textOnPrimary,
      error: appColors.error,
      onError: appColors.textOnPrimary,
      surface: appColors.backgroundSecondary,
      onSurface: appColors.textPrimary,
      outline: appColors.border,
      outlineVariant: appColors.borderSubtle,
      surfaceContainerHighest: appColors.surfaceElevated2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamilyFallback: const ['Cairo'],
      extensions: [appColors],

      // ── Scaffold ──
      scaffoldBackgroundColor: appColors.backgroundPrimary,

      // ── App Bar ──
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appColors.backgroundPrimary,
        foregroundColor: appColors.textPrimary,
        surfaceTintColor: Colors.transparent,
      ),

      // ── Bottom Navigation ──
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: appColors.navBarBackground,
        selectedItemColor: appColors.primary,
        unselectedItemColor: appColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── Cards ──
      cardTheme: CardThemeData(
        elevation: 0,
        color: appColors.surfaceElevated1,
        shape: RoundedRectangleBorder(
          borderRadius: AppLayout.borderRadiusMedium,
          side: BorderSide(color: appColors.border, width: 1),
        ),
      ),

      // ── Input Fields ──
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: AppLayout.borderRadiusMedium,
          borderSide: BorderSide(color: appColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppLayout.borderRadiusMedium,
          borderSide: BorderSide(color: appColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppLayout.borderRadiusMedium,
          borderSide: BorderSide(color: appColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppLayout.borderRadiusMedium,
          borderSide: BorderSide(color: appColors.error),
        ),
        filled: true,
        fillColor: appColors.surface,
        hintStyle: TextStyle(color: appColors.textTertiary),
        labelStyle: TextStyle(color: appColors.textSecondary),
      ),

      // ── Elevated Buttons ──
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: appColors.primary,
          foregroundColor: appColors.textOnPrimary,
          disabledBackgroundColor: appColors.primaryDisabled,
          disabledForegroundColor: appColors.textTertiary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppLayout.borderRadiusMedium,
          ),
          elevation: 0,
        ),
      ),

      // ── Outlined Buttons ──
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: appColors.primary,
          side: BorderSide(color: appColors.primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: AppLayout.borderRadiusMedium,
          ),
        ),
      ),

      // ── Text Buttons ──
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: appColors.primary,
        ),
      ),

      // ── Dialogs ──
      dialogTheme: DialogThemeData(
        backgroundColor: appColors.surfaceElevated2,
        shape: RoundedRectangleBorder(
          borderRadius: AppLayout.borderRadiusLarge,
        ),
      ),

      // ── Bottom Sheets ──
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: appColors.surfaceElevated2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Divider ──
      dividerTheme: DividerThemeData(
        color: appColors.divider,
        thickness: 1,
        space: 1,
      ),

      // ── Chips ──
      chipTheme: ChipThemeData(
        backgroundColor: appColors.surface,
        selectedColor: appColors.primaryMuted,
        labelStyle: TextStyle(color: appColors.textPrimary),
        side: BorderSide(color: appColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: AppLayout.borderRadiusSmall,
        ),
      ),

      // ── Snackbar ──
      snackBarTheme: SnackBarThemeData(
        backgroundColor: appColors.surfaceElevated2,
        contentTextStyle: TextStyle(color: appColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: AppLayout.borderRadiusMedium,
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // ── Progress indicators ──
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: appColors.primary,
      ),

      // ── Switch ──
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return appColors.primary;
          return appColors.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return appColors.primaryMuted;
          return appColors.surface;
        }),
      ),
    );
  }
}
