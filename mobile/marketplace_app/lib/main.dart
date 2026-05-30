import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

import 'config/app_config.dart';
import 'l10n/app_localizations.dart';
import 'providers/annonces_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/locale_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_colors.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.load();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print('Firebase init failed (likely missing config): $e');
  }
  runApp(const MarketplaceApp());
}

class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AnnoncesProvider()),
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
