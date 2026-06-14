import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService _instance = PreferencesService._internal();
  SharedPreferences? _prefs;

  factory PreferencesService() => _instance;
  PreferencesService._internal();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs?.getBool(key) ?? defaultValue;
  }

  Future<void> setBool(String key, bool value) async {
    await _prefs?.setBool(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs?.getInt(key) ?? defaultValue;
  }

  Future<void> setInt(String key, int value) async {
    await _prefs?.setInt(key, value);
  }

  String? getString(String key) => _prefs?.getString(key);
  Future<void> setString(String key, String value) async => await _prefs?.setString(key, value);

  Future<void> remove(String key) async {
    await _prefs?.remove(key);
  }

  // Timer fade preferences
  static const String _kFadeSeconds = 'fade_seconds';
  static const String _kUnlimitedFade = 'unlimited_fade';

  int getFadeSeconds() => _prefs?.getInt(_kFadeSeconds) ?? 3;
  Future<void> setFadeSeconds(int seconds) async => await _prefs?.setInt(_kFadeSeconds, seconds);

  bool getUnlimitedFade() => _prefs?.getBool(_kUnlimitedFade) ?? false;
  Future<void> setUnlimitedFade(bool enabled) async => await _prefs?.setBool(_kUnlimitedFade, enabled);

  // Daily rewarded-ad limit
  static const String _kLastRewardDateMs = 'last_reward_date_ms';

  DateTime? getLastRewardDate() {
    final ms = _prefs?.getInt(_kLastRewardDateMs);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Future<void> setLastRewardDate(DateTime date) async {
    await _prefs?.setInt(_kLastRewardDateMs, date.millisecondsSinceEpoch);
  }

  bool canClaimDailyReward() {
    final last = getLastRewardDate();
    if (last == null) return true;
    return DateTime.now().difference(last).inHours >= 24;
  }

  // Recently played sound IDs (most recent first, capped at 10)
  static const String _kRecentlyPlayed = 'recently_played_ids';
  static const int _maxRecentlyPlayed = 10;

  List<String> getRecentlyPlayed() {
    return _prefs?.getStringList(_kRecentlyPlayed) ?? [];
  }

  Future<void> addRecentlyPlayed(String soundId) async {
    final list = getRecentlyPlayed();
    list.remove(soundId);
    list.insert(0, soundId);
    if (list.length > _maxRecentlyPlayed) {
      list.removeRange(_maxRecentlyPlayed, list.length);
    }
    await _prefs?.setStringList(_kRecentlyPlayed, list);
  }

  // Notification preferences
  static const _kBedtimeReminderEnabled = 'bedtime_reminder_enabled';
  static const _kMorningCheckInEnabled = 'morning_checkin_enabled';

  bool getBedtimeReminderEnabled() => _prefs?.getBool(_kBedtimeReminderEnabled) ?? false;
  Future<void> setBedtimeReminderEnabled(bool v) async =>
      _prefs?.setBool(_kBedtimeReminderEnabled, v);

  bool getMorningCheckInEnabled() => _prefs?.getBool(_kMorningCheckInEnabled) ?? false;
  Future<void> setMorningCheckInEnabled(bool v) async =>
      _prefs?.setBool(_kMorningCheckInEnabled, v);
}
