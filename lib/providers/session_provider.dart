import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import '../models/sleep_session.dart';
import '../services/analytics_service.dart';
import '../services/preferences_service.dart';
import '../services/storage_service.dart';

class SessionProvider extends ChangeNotifier {
  static const _kLastReviewMs = 'last_review_request_ms';
  static const _kReviewThreshold = 3;
  static const _kReviewCooldownDays = 60;

  final StorageService _storageService = StorageService();
  final List<SleepSession> _sessions = [];
  late final UnmodifiableListView<SleepSession> _sessionsView =
      UnmodifiableListView(_sessions);

  List<SleepSession> get sessions => _sessionsView;

  int get currentStreak {
    final uniqueDays = _sessions
        .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    var streak = 0;
    var day = DateTime.now();
    day = DateTime(day.year, day.month, day.day);
    while (uniqueDays.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Median session-start hour — used to detect the user's habitual bedtime.
  int get habitualBedtimeHour {
    if (_sessions.isEmpty) return 22; // default 10 PM
    final hours = _sessions.map((s) => s.startTime.hour).toList()..sort();
    return hours[hours.length ~/ 2];
  }

  /// Average sleep quality across all rated sessions (1–4 scale), or null if none rated.
  double? get averageSleepQuality {
    final rated = _sessions.where((s) => s.sleepQuality != null).toList();
    if (rated.isEmpty) return null;
    return rated.map((s) => s.sleepQuality!).reduce((a, b) => a + b) / rated.length;
  }

  SessionProvider() {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final storedSessions = _storageService.getAllSessions();
    _sessions.clear();
    for (final session in storedSessions) {
      if (session is SleepSession) {
        _sessions.add(session);
      } else if (session is Map<String, dynamic>) {
        _sessions.add(SleepSession.fromMap(session));
      } else if (session is Map) {
        _sessions.add(SleepSession.fromMap(Map<String, dynamic>.from(session)));
      }
    }
    _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
    notifyListeners();
  }

  Future<void> addSession(SleepSession session) async {
    _sessions.insert(0, session);
    await _storageService.saveSession(session.id, session.toMap());
    notifyListeners();
    _maybeRequestReview();
    unawaited(AnalyticsService.instance.logSessionCompleted(session.duration.inMinutes));
  }

  Future<void> removeSession(String sessionId) async {
    _sessions.removeWhere((session) => session.id == sessionId);
    await _storageService.deleteSession(sessionId);
    notifyListeners();
  }

  Future<void> clearSessions() async {
    _sessions.clear();
    await _storageService.clearAllSessions();
    notifyListeners();
  }

  Future<void> _maybeRequestReview() async {
    if (_sessions.length < _kReviewThreshold) return;

    final prefs = PreferencesService();
    final lastMs = prefs.getInt(_kLastReviewMs);
    if (lastMs != 0) {
      final daysSinceLast =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(lastMs)).inDays;
      if (daysSinceLast < _kReviewCooldownDays) return;
    }

    final review = InAppReview.instance;
    if (!await review.isAvailable()) return;

    await prefs.setInt(_kLastReviewMs, DateTime.now().millisecondsSinceEpoch);
    await review.requestReview();
  }
}
