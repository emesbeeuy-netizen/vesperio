class SleepSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final List<String> soundIds;
  final List<double> soundVolumes;
  final int? timerDuration; // in minutes
  final bool isActive;
  final int totalMinutesListened;
  final String? notes;
  /// 1=Poor  2=Fair  3=Good  4=Amazing — null if not yet rated.
  final int? sleepQuality;

  SleepSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.soundIds,
    required this.soundVolumes,
    this.timerDuration,
    this.isActive = true,
    this.totalMinutesListened = 0,
    this.notes,
    this.sleepQuality,
  });

  Duration get duration {
    if (endTime == null) {
      return DateTime.now().difference(startTime);
    }
    return endTime!.difference(startTime);
  }

  SleepSession copyWith({
    String? id,
    DateTime? startTime,
    DateTime? endTime,
    List<String>? soundIds,
    List<double>? soundVolumes,
    int? timerDuration,
    bool? isActive,
    int? totalMinutesListened,
    String? notes,
    int? sleepQuality,
  }) {
    return SleepSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      soundIds: soundIds ?? this.soundIds,
      soundVolumes: soundVolumes ?? this.soundVolumes,
      timerDuration: timerDuration ?? this.timerDuration,
      isActive: isActive ?? this.isActive,
      totalMinutesListened: totalMinutesListened ?? this.totalMinutesListened,
      notes: notes ?? this.notes,
      sleepQuality: sleepQuality ?? this.sleepQuality,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SleepSession &&
          runtimeType == other.runtimeType &&
          id == other.id;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'soundIds': soundIds,
      'soundVolumes': soundVolumes,
      'timerDuration': timerDuration,
      'isActive': isActive,
      'totalMinutesListened': totalMinutesListened,
      'notes': notes,
      'sleepQuality': sleepQuality,
    };
  }

  factory SleepSession.fromMap(Map<String, dynamic> map) {
    return SleepSession(
      id: map['id'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: map['endTime'] != null ? DateTime.parse(map['endTime'] as String) : null,
      soundIds: List<String>.from(map['soundIds'] as List<dynamic>),
      soundVolumes: List<double>.from(
        (map['soundVolumes'] as List<dynamic>).map((value) => (value as num).toDouble()),
      ),
      timerDuration: map['timerDuration'] as int?,
      isActive: map['isActive'] as bool? ?? true,
      totalMinutesListened: map['totalMinutesListened'] as int? ?? 0,
      notes: map['notes'] as String?,
      sleepQuality: map['sleepQuality'] as int?,
    );
  }

  @override
  int get hashCode => id.hashCode;
}
