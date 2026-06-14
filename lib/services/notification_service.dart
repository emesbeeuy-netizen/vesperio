import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../models/smart_alarm.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _channelId = 'vesperio_channel';
  static const _channelName = 'Vesperio Notifications';
  static const _channelDesc = 'Vesperio app notifications';
  static const _alarmChannelId = 'vesperio_alarm';
  static const _alarmChannelName = 'Smart Alarms';
  static const _alarmChannelDesc = 'Vesperio smart sleep alarm notifications';

  static const int morningCheckInId = 1001;
  static const int bedtimeReminderId = 1002;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      final location = tz.getLocation(_localTimeZoneName());
      tz.setLocalLocation(location);
    } catch (_) {
      // Falls back to UTC; acceptable on most devices.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: _handleTap,
    );
  }

  String _localTimeZoneName() {
    try {
      return DateTime.now().timeZoneName;
    } catch (_) {
      return 'UTC';
    }
  }

  void _handleTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  // ── General notifications ────────────────────────────────────────────────

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _generalDetails(),
      payload: payload,
    );
  }

  /// Schedules a one-time notification using an exact alarm.
  /// Falls back to [showNotification] when [scheduledTime] is in the past.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    if (scheduledTime.isBefore(DateTime.now())) {
      await showNotification(id: id, title: title, body: body, payload: payload);
      return;
    }
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: _generalDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }

  // ── Smart alarm notifications ────────────────────────────────────────────

  /// Schedules the smart alarm notification.
  /// The notification id is derived from the alarm's id hash so each alarm
  /// maps to a stable, unique notification slot.
  Future<void> scheduleAlarmNotification({
    required SmartAlarm alarm,
    required DateTime fireAt,
  }) async {
    final notifId = alarm.id.hashCode.abs() % 100000;
    await _plugin.zonedSchedule(
      id: notifId,
      title: '⏰ ${alarm.label ?? 'Smart Alarm'}',
      body: _alarmBody(alarm, fireAt),
      scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
      notificationDetails: _alarmDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents:
          alarm.isRecurring ? DateTimeComponents.time : null,
      payload: 'alarm:${alarm.id}',
    );
  }

  /// Schedules a daily recurring bedtime reminder at [hour]:[minute].
  Future<void> scheduleBedtimeReminder({
    required int hour,
    required int minute,
    required int streak,
  }) async {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (now.isAfter(target)) target = target.add(const Duration(days: 1));
    final body = streak > 1
        ? 'Your $streak-night streak is waiting. Wind down with Vesperio.'
        : 'Time to wind down. Your sleep sounds are ready.';
    await _plugin.zonedSchedule(
      id: bedtimeReminderId,
      title: 'Bedtime reminder',
      body: body,
      scheduledDate: tz.TZDateTime.from(target, tz.local),
      notificationDetails: _generalDetails(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'bedtime_reminder',
    );
  }

  Future<void> cancelBedtimeReminder() async {
    await _plugin.cancel(id: bedtimeReminderId);
  }

  /// Schedules a one-time morning check-in notification at the next 8 AM.
  Future<void> scheduleMorningCheckIn() async {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 8, 0);
    if (now.isAfter(target)) target = target.add(const Duration(days: 1));
    await scheduleNotification(
      id: morningCheckInId,
      title: 'Good morning!',
      body: 'How did you sleep? Tap to rate last night.',
      scheduledTime: target,
      payload: 'morning_check_in',
    );
  }

  Future<void> cancelMorningCheckIn() async {
    await _plugin.cancel(id: morningCheckInId);
  }

  Future<void> cancelAlarmNotification(SmartAlarm alarm) async {
    final notifId = alarm.id.hashCode.abs() % 100000;
    await _plugin.cancel(id: notifId);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _alarmBody(SmartAlarm alarm, DateTime fireAt) {
    final h = fireAt.hour.toString().padLeft(2, '0');
    final m = fireAt.minute.toString().padLeft(2, '0');
    if (alarm.hasBedTime &&
        (fireAt.hour != alarm.time.hour || fireAt.minute != alarm.time.minute)) {
      return 'Waking you at $h:$m — optimal end of a sleep cycle.';
    }
    return 'Good morning! Time to rise and shine.';
  }

  NotificationDetails _generalDetails() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.max,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }

  NotificationDetails _alarmDetails() {
    const android = AndroidNotificationDetails(
      _alarmChannelId,
      _alarmChannelName,
      channelDescription: _alarmChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: ios);
  }
}
