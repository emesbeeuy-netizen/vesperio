import '../models/smart_alarm.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// Manages smart alarms with 90-minute sleep-cycle detection.
///
/// When a bed time is set on the alarm, [computeOptimalWakeTime] finds the
/// latest 90-minute sleep-cycle boundary that falls inside the user's wake
/// window ([alarm.time - alarm.windowMinutes … alarm.time]). If no cycle
/// boundary lands in the window the target wake time is used as-is.
class SmartAlarmService {
  static final SmartAlarmService _instance = SmartAlarmService._internal();
  factory SmartAlarmService() => _instance;
  SmartAlarmService._internal();

  final StorageService _storage = StorageService();
  final NotificationService _notifications = NotificationService();

  static const String _kAlarmsKey = 'smart_alarms';
  static const int _cycleDurationMinutes = 90;

  // ── CRUD ─────────────────────────────────────────────────────────────────

  Future<List<SmartAlarm>> loadAlarms() async {
    try {
      final raw = _storage.getSetting(_kAlarmsKey);
      if (raw is List) {
        final result = <SmartAlarm>[];
        for (final e in raw) {
          try {
            result.add(SmartAlarm.fromMap(Map<String, dynamic>.from(e as Map)));
          } catch (_) {}
        }
        return result;
      }
    } catch (_) {}
    return [];
  }

  Future<void> saveAlarm(SmartAlarm alarm) async {
    final alarms = await loadAlarms();
    final idx = alarms.indexWhere((a) => a.id == alarm.id);
    if (idx >= 0) {
      alarms[idx] = alarm;
    } else {
      alarms.add(alarm);
    }
    await _persistAlarms(alarms);

    if (alarm.enabled) {
      await _scheduleNotification(alarm);
    } else {
      await _notifications.cancelAlarmNotification(alarm);
    }
  }

  Future<void> deleteAlarm(String id) async {
    final alarms = await loadAlarms();
    final target = alarms.firstWhere((a) => a.id == id,
        orElse: () => SmartAlarm(id: id, time: DateTime.now()));
    await _notifications.cancelAlarmNotification(target);
    alarms.removeWhere((a) => a.id == id);
    await _persistAlarms(alarms);
  }

  Future<void> enableAlarm(String id, bool enabled) async {
    final alarms = await loadAlarms();
    final idx = alarms.indexWhere((a) => a.id == id);
    if (idx < 0) return;
    final updated = alarms[idx].copyWith(enabled: enabled);
    alarms[idx] = updated;
    await _persistAlarms(alarms);

    if (enabled) {
      await _scheduleNotification(updated);
    } else {
      await _notifications.cancelAlarmNotification(updated);
    }
  }

  /// Re-schedules all enabled alarms. Call on app start / after device reboot.
  Future<void> rescheduleAll() async {
    final alarms = await loadAlarms();
    for (final alarm in alarms) {
      if (alarm.enabled) await _scheduleNotification(alarm);
    }
  }

  // ── Sleep-cycle logic ─────────────────────────────────────────────────────

  /// Returns the optimal wake time for [alarm]:
  /// the latest 90-minute cycle boundary from the estimated bedtime that falls
  /// within [alarm.time - alarm.windowMinutes … alarm.time].
  /// Falls back to [alarm.time] when no boundary lands in the window.
  DateTime computeOptimalWakeTime(SmartAlarm alarm) {
    final target = _nextOccurrence(alarm.time);
    final windowStart =
        target.subtract(Duration(minutes: alarm.windowMinutes));

    if (!alarm.hasBedTime) return target;

    // Construct the bed-datetime on the night before the wake date.
    var bedDt = DateTime(
      target.year,
      target.month,
      target.day,
      alarm.bedTimeHour!,
      alarm.bedTimeMinute!,
    );
    // If bed time is after the wake time on the same calendar day, shift back
    // a day (user went to bed the previous evening).
    if (bedDt.isAfter(target)) {
      bedDt = bedDt.subtract(const Duration(days: 1));
    }

    DateTime? best;
    var elapsed = const Duration(minutes: _cycleDurationMinutes);

    while (true) {
      final candidate = bedDt.add(elapsed);
      if (candidate.isAfter(target)) break;
      if (!candidate.isBefore(windowStart)) {
        // Candidate is within the wake window — prefer the latest.
        if (best == null || candidate.isAfter(best)) best = candidate;
      }
      elapsed += const Duration(minutes: _cycleDurationMinutes);
    }

    return best ?? target;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _scheduleNotification(SmartAlarm alarm) async {
    final fireAt = computeOptimalWakeTime(alarm);
    await _notifications.scheduleAlarmNotification(
        alarm: alarm, fireAt: fireAt);
  }

  /// Returns the next DateTime that matches the time-of-day of [base].
  /// If [base] is in the past, advances to tomorrow.
  DateTime _nextOccurrence(DateTime base) {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, base.hour, base.minute);
    if (!next.isAfter(now)) next = next.add(const Duration(days: 1));
    return next;
  }

  Future<void> _persistAlarms(List<SmartAlarm> alarms) async {
    final raw = alarms.map((a) => a.toMap()).toList();
    await _storage.saveSetting(_kAlarmsKey, raw);
  }
}
