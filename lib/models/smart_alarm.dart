class SmartAlarm {
  final String id;

  /// Desired (latest) wake time.
  final DateTime time;

  final bool enabled;
  final String? label;

  /// Smart-wake window in minutes (1–60). The alarm fires at the closest
  /// 90-minute sleep-cycle boundary before [time] within this window.
  final int windowMinutes;

  /// Optional estimated bedtime (hour + minute only; day is irrelevant).
  /// When set, the service uses 90-min cycles from bedtime to find the
  /// optimal wake point within the wake window.
  final int? bedTimeHour;
  final int? bedTimeMinute;

  /// Whether the alarm repeats daily.
  final bool isRecurring;

  SmartAlarm({
    required this.id,
    required this.time,
    this.enabled = true,
    this.label,
    this.windowMinutes = 30,
    this.bedTimeHour,
    this.bedTimeMinute,
    this.isRecurring = true,
  });

  bool get hasBedTime => bedTimeHour != null && bedTimeMinute != null;

  Map<String, dynamic> toMap() => {
        'id': id,
        'time': time.toIso8601String(),
        'enabled': enabled,
        'label': label,
        'windowMinutes': windowMinutes,
        'bedTimeHour': bedTimeHour,
        'bedTimeMinute': bedTimeMinute,
        'isRecurring': isRecurring,
      };

  factory SmartAlarm.fromMap(Map<String, dynamic> m) => SmartAlarm(
        id: m['id'] as String,
        time: DateTime.parse(m['time'] as String),
        enabled: m['enabled'] as bool? ?? true,
        label: m['label'] as String?,
        windowMinutes: m['windowMinutes'] as int? ?? 30,
        bedTimeHour: m['bedTimeHour'] as int?,
        bedTimeMinute: m['bedTimeMinute'] as int?,
        isRecurring: m['isRecurring'] as bool? ?? true,
      );

  SmartAlarm copyWith({
    String? id,
    DateTime? time,
    bool? enabled,
    String? label,
    int? windowMinutes,
    int? bedTimeHour,
    int? bedTimeMinute,
    bool? isRecurring,
  }) =>
      SmartAlarm(
        id: id ?? this.id,
        time: time ?? this.time,
        enabled: enabled ?? this.enabled,
        label: label ?? this.label,
        windowMinutes: windowMinutes ?? this.windowMinutes,
        bedTimeHour: bedTimeHour ?? this.bedTimeHour,
        bedTimeMinute: bedTimeMinute ?? this.bedTimeMinute,
        isRecurring: isRecurring ?? this.isRecurring,
      );
}
