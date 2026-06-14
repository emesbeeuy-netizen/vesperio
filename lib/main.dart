import 'dart:async';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_constants.dart';
import 'firebase_options.dart';
import 'providers/index.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/ads_service.dart';
import 'services/notification_service.dart';
import 'services/purchase_service.dart';
import 'services/smart_alarm_service.dart';
import 'services/storage_service.dart';
import 'services/preferences_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Route Flutter framework errors to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Route async errors outside the Flutter framework to Crashlytics.
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await StorageService().initialize();
  await PreferencesService().initialize();
  await NotificationService().initialize();
  await PurchaseService.instance.initialize();
  // Re-schedule any enabled smart alarms (handles post-boot restart).
  unawaited(SmartAlarmService().rescheduleAll());
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Defer to the first frame so the iOS window exists before the ATT dialog.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initAds());
  }

  Future<void> _initAds() async {
    if (!kIsWeb && Platform.isIOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
    await AdsService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => SoundsProvider()),
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerProvider()),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            return userProvider.user.isFirstLaunch
                ? const OnboardingScreen()
                : const HomeScreen();
          },
        ),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.textInverse,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondary,
        onSecondary: AppColors.textInverse,
        tertiary: AppColors.accent,
        onTertiary: AppColors.textInverse,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        error: AppColors.error,
        onError: AppColors.textInverse,
      ),
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: AppColors.surfaceVariant,
        foregroundColor: AppColors.textInverse,
        centerTitle: true,
        titleTextStyle: AppTypography.heading3.copyWith(
          color: AppColors.textInverse,
        ),
      ),
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: AppColors.primary.withAlpha((0.2 * 255).round()),
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: const BorderSide(
            color: AppColors.outline,
            width: 1,
          ),
        ),
      ),
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textInverse,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.textInverse,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          elevation: 0,
          foregroundColor: AppColors.secondary,
          minimumSize: const Size.fromHeight(AppDimensions.buttonHeight),
          side: const BorderSide(
            color: AppColors.secondary,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            color: AppColors.secondary,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.secondaryLight,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          borderSide: const BorderSide(color: AppColors.secondary, width: 2),
        ),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.secondary,
        inactiveTrackColor: AppColors.outline,
        thumbColor: AppColors.primary,
        trackHeight: AppDimensions.sliderHeight,
        valueIndicatorColor: AppColors.secondary,
      ),
    );
  }
}
