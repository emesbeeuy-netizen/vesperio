import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Deep brand purple
  static const Color primary = Color(0xFF2C2278); // Brand purple
  static const Color primaryLight = Color(0xFF6D5EA4);
  static const Color primaryDark = Color(0xFF1A144B);

  // Secondary Colors - Soft violet accent
  static const Color secondary = Color(0xFF9062F7);
  static const Color secondaryLight = Color(0xFFBEA4FF);

  // Accent Colors - Energetic neon teal
  static const Color accent = Color(0xFF22D0A7);
  static const Color accentLight = Color(0xFF7AF1D0);

  // Neutral Colors
  static const Color background = Color(0xFF100B26); // Very dark navy purple
  static const Color surface = Color(0xFF1E1640); // Dark surface
  static const Color surfaceVariant = Color(0xFF241A4F); // Soft purple surface
  static const Color surfaceAlt = Color(0xFF2D2260);
  static const Color outline = Color(0xFF453C75); // Subtle border
  static const Color outlineVariant = Color(0xFF372F66); // Darker border

  // Text Colors
  static const Color textPrimary = Color(0xFFF5F4FF); // Soft white
  static const Color textSecondary = Color(0xFFC9C2F0); // Light lavender
  static const Color textTertiary = Color(0xFF9F94C3); // Muted lavender
  static const Color textInverse = Color(0xFFFFFFFF); // White

  // System Colors
  static const Color success = Color(0xFF1EDDAF); // Green
  static const Color warning = Color(0xFFF59E0B); // Orange
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF6B7BFF); // Soft blue

  // Overlay
  static const Color scrimDark = Color(0x42000000); // Dark overlay
  static const Color scrimLight = Color(0x1F000000); // Light overlay
}

class AppTypography {
  static const String fontFamily = 'Poppins';

  // Heading Styles
  static const TextStyle heading1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: 0.15,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.25,
    letterSpacing: 0.12,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}

class AppDimensions {
  static const double buttonHeight = 56.0;
  static const double smallButtonHeight = 44.0;
  static const double soundCardHeight = 140.0;
  static const double soundCardWidth = 120.0;
  static const double sliderHeight = 8.0;
}

class AppStrings {
  // App Name
  static const String appName = 'Vesperio';
  static const String tagline = 'Sleep Better, Focus Deeper.';

  // Tabs
  static const String homeTab = 'Home';
  static const String soundsTab = 'Sounds';
  static const String focusTab = 'Focus';
  static const String sessionTab = 'Sessions';
  static const String settingsTab = 'Settings';

  // Common
  static const String premium = 'Premium';
  static const String free = 'Free';
  static const String upgrade = 'Upgrade';
  static const String upToNow = 'Up to now';
  static const String unlimitedAccess = 'Unlimited Access';

  // Home Screen
  static const String goodNight = 'Good Night';
  static const String recentlyPlayed = 'Recently Played';
  static const String featured = 'Featured';
  static const String startListening = 'Start Listening';

  // Sounds
  static const String allSounds = 'All Sounds';
  static const String rain = 'Rain';
  static const String sea = 'Sea Waves';
  static const String wind = 'Wind';
  static const String forest = 'Forest';
  static const String thunderstorm = 'Thunderstorm';
  static const String train = 'Train';
  static const String waterfall = 'Waterfall';
  static const String coffee = 'Vintage Coffee';

  // Timer
  static const String sleepTimer = 'Sleep Timer';
  static const String timerSet = 'Timer Set';
  static const String fadeOut = 'Fade Out';

  // Mixer
  static const String mixer = 'Sound Mixer';
  static const String addSound = 'Add Sound';
  static const String removeSound = 'Remove Sound';
  static const String maxSounds = 'Max 4 sounds allowed';

  // Settings
  static const String settings = 'Settings';
  static const String account = 'Account';
  static const String notifications = 'Notifications';
  static const String about = 'About';
  static const String helpCenter = 'Help Center';
  static const String faq = 'FAQ';
  static const String privacyPolicy = 'Privacy Policy';
  static const String termsOfService = 'Terms of Service';
  static const String version = 'Version';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@vesperio.app';
  static const String supportUrl = 'https://emesbeeuy-netizen.github.io/vesperio-website/support/';
  static const String privacyPolicyUrl = 'https://emesbeeuy-netizen.github.io/vesperio-website/privacy/';
  static const String termsOfServiceUrl = 'https://emesbeeuy-netizen.github.io/vesperio-website/terms/';
  static const String shareApp = 'Share Vesperio';
  // TODO: replace with live App Store / Play Store URLs before publishing.
  static const String shareMessage =
      'Discover Vesperio — sleep better with calming soundscapes, smart timers, and premium content. Available on the App Store and Google Play.';
  static const String signIn = 'Sign In';
  static const String logout = 'Sign Out';
  static const String createAccount = 'Create account';
  static const String haveAccount = 'Already have an account?';
  static const String emailAddress = 'Email address';
  static const String password = 'Password';
  static const String displayName = 'Display name';
  static const String pleaseWait = 'Please wait...';
  static const String premiumProductId = 'vesperio_premium_monthly';
  static const String premiumProductIdWeekly = 'vesperio_premium_weekly';
  static const String premiumProductIdAnnual = 'vesperio_premium_annual';
  // Fallback display prices shown while store prices are loading.
  static const String premiumWeeklyFallbackPrice = '\$1.99';
  static const String premiumMonthlyFallbackPrice = '\$6.99';
  static const String premiumAnnualFallbackPrice = '\$29.99';
}

class AdMobIds {
  // Test IDs (Google provided) - used automatically in debug builds.
  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111'; // Banner Android
  static const String testBannerIOS = 'ca-app-pub-3940256099942544/2934735716'; // Banner iOS
  static const String testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917'; // Rewarded Android
  static const String testRewardedIOS = 'ca-app-pub-3940256099942544/1712485313'; // Rewarded iOS

  // Replace these with your production AdMob unit IDs before release.
  static const String prodBannerAndroid = 'ca-app-pub-1213871432624926/1713533349'; // Banner Android
  static const String prodBannerIOS = 'ca-app-pub-1213871432624926/9775627282'; // Banner iOS
  static const String prodRewardedAndroid = 'ca-app-pub-1213871432624926/2036738062'; // Rewarded Android
  static const String prodRewardedIOS = 'ca-app-pub-1213871432624926/4148124999'; // Rewarded iOS

  // Optional: set your production app IDs here for Android and iOS.
  // If these are empty, your native manifests will still use app IDs when provided.
  static const String prodAppIdAndroid = ''; // AdMob App ID Android
  static const String prodAppIdIOS = ''; // AdMob App ID iOS

  // Helper: use test IDs in debug builds unless you explicitly override by
  // setting [forceUseProductionIds] to true.
  static const bool forceUseProductionIds = false;
  static bool get useTestIds => !forceUseProductionIds && bool.fromEnvironment('dart.vm.product') == false;
}

/// Visual identity for a single sound (icon + two-stop gradient).
class SoundMeta {
  final IconData icon;
  final Color colorA;
  final Color colorB;

  const SoundMeta({
    required this.icon,
    required this.colorA,
    required this.colorB,
  });

  List<Color> get gradient => [colorA, colorB];
}

class SoundData {
  // Per-sound visual metadata: gradient colours + icon.
  static const Map<String, SoundMeta> soundMeta = {
    // --- Free: Nature ---
    'rain':        SoundMeta(icon: Icons.water_drop,        colorA: Color(0xFF1E3A5F), colorB: Color(0xFF2D6A9F)),
    'sea':         SoundMeta(icon: Icons.waves,             colorA: Color(0xFF006994), colorB: Color(0xFF1CB5E0)),
    'wind':        SoundMeta(icon: Icons.air,               colorA: Color(0xFF134E5E), colorB: Color(0xFF52C4A0)),
    'forest':      SoundMeta(icon: Icons.park,              colorA: Color(0xFF1B4332), colorB: Color(0xFF2D6A4F)),
    // --- Free: Ambient ---
    'white_noise': SoundMeta(icon: Icons.graphic_eq,        colorA: Color(0xFF2C3E50), colorB: Color(0xFF4A6572)),
    'pink_noise':  SoundMeta(icon: Icons.blur_on,           colorA: Color(0xFF614B6A), colorB: Color(0xFFB06AB3)),
    'brown_noise': SoundMeta(icon: Icons.grain,             colorA: Color(0xFF5C3317), colorB: Color(0xFF8B5E3C)),
    'fireplace':   SoundMeta(icon: Icons.whatshot,          colorA: Color(0xFF7B1D1D), colorB: Color(0xFFE05C00)),
    // --- Premium ---
    'thunderstorm':SoundMeta(icon: Icons.thunderstorm,      colorA: Color(0xFF1B1B2F), colorB: Color(0xFF4B3869)),
    'train':       SoundMeta(icon: Icons.train,             colorA: Color(0xFF2B2D42), colorB: Color(0xFF4A5568)),
    'waterfall':   SoundMeta(icon: Icons.water,             colorA: Color(0xFF006994), colorB: Color(0xFF1CBECA)),
    'coffee_shop': SoundMeta(icon: Icons.coffee,            colorA: Color(0xFF4A2C0A), colorB: Color(0xFF8B5E3C)),
    'river':       SoundMeta(icon: Icons.waves,             colorA: Color(0xFF0277BD), colorB: Color(0xFF26C6DA)),
    'bird_forest': SoundMeta(icon: Icons.nature,            colorA: Color(0xFF1B5E20), colorB: Color(0xFF66BB6A)),
    'rain_thunder':SoundMeta(icon: Icons.storm,             colorA: Color(0xFF2C3E50), colorB: Color(0xFF4CA1AF)),
    'meditation':  SoundMeta(icon: Icons.self_improvement,  colorA: Color(0xFF5C258D), colorB: Color(0xFF4389A2)),
    'night_wind':  SoundMeta(icon: Icons.dark_mode,         colorA: Color(0xFF0F0C29), colorB: Color(0xFF302B63)),
  };

  static const SoundMeta _defaultMeta = SoundMeta(
    icon: Icons.music_note,
    colorA: AppColors.primary,
    colorB: AppColors.secondary,
  );

  static SoundMeta metaFor(String soundId) => soundMeta[soundId] ?? _defaultMeta;

  // Basic Free Sounds (8 sounds)
  static const List<Map<String, String>> basicSounds = [
    {
      'id': 'rain',
      'name': 'Rain',
      'category': 'nature',
      'description': 'Gentle rainfall perfect for sleep',
    },
    {
      'id': 'sea',
      'name': 'Sea Waves',
      'category': 'nature',
      'description': 'Calming ocean waves',
    },
    {
      'id': 'wind',
      'name': 'Wind',
      'category': 'nature',
      'description': 'Soft wind through trees',
    },
    {
      'id': 'forest',
      'name': 'Forest',
      'category': 'nature',
      'description': 'Peaceful forest ambience',
    },
    {
      'id': 'white_noise',
      'name': 'White Noise',
      'category': 'ambient',
      'description': 'Pure white noise',
    },
    {
      'id': 'brown_noise',
      'name': 'Brown Noise',
      'category': 'ambient',
      'description': 'Deep relaxing brown noise',
    },
    {
      'id': 'pink_noise',
      'name': 'Pink Noise',
      'category': 'ambient',
      'description': 'Balanced pink noise',
    },
    {
      'id': 'fireplace',
      'name': 'Fireplace',
      'category': 'ambient',
      'description': 'Cozy fireplace crackling',
    },
  ];

  // Premium Sounds (9 sounds)
  static const List<Map<String, String>> premiumSounds = [
    {
      'id': 'thunderstorm',
      'name': 'Thunderstorm',
      'category': 'weather',
      'description': 'Dramatic storm with thunder',
    },
    {
      'id': 'train',
      'name': 'Train',
      'category': 'transport',
      'description': 'Rhythmic train journey',
    },
    {
      'id': 'waterfall',
      'name': 'Waterfall',
      'category': 'water',
      'description': 'Majestic waterfall sounds',
    },
    {
      'id': 'coffee_shop',
      'name': 'Vintage Coffee',
      'category': 'ambient',
      'description': 'Cozy coffee shop ambience',
    },
    {
      'id': 'river',
      'name': 'River Flow',
      'category': 'water',
      'description': 'Gentle river stream',
    },
    {
      'id': 'bird_forest',
      'name': 'Bird Forest',
      'category': 'nature',
      'description': 'Morning forest birds',
    },
    {
      'id': 'rain_thunder',
      'name': 'Rain & Thunder',
      'category': 'weather',
      'description': 'Rain with distant thunder',
    },
    {
      'id': 'meditation',
      'name': 'Meditation Bells',
      'category': 'ambient',
      'description': 'Tibetan singing bowls',
    },
    {
      'id': 'night_wind',
      'name': 'Night Wind',
      'category': 'nature',
      'description': 'Deep wind gusts at night',
    },
  ];
}
