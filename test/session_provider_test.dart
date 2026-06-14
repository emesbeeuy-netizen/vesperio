import 'package:flutter_test/flutter_test.dart';
import 'package:vesperio/models/sleep_session.dart';

void main() {
  group('SleepSession model', () {
    test('toMap/fromMap roundtrip preserves fields', () {
      final now = DateTime.now();
      final session = SleepSession(
        id: 's1',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        soundIds: ['a', 'b'],
        soundVolumes: [0.5, 0.8],
        timerDuration: 30,
        isActive: false,
        totalMinutesListened: 30,
        notes: 'test',
      );

      final map = session.toMap();
      final restored = SleepSession.fromMap(map);
      expect(restored.id, equals(session.id));
      expect(restored.startTime.toIso8601String(), equals(session.startTime.toIso8601String()));
      expect(restored.soundIds, equals(session.soundIds));
      expect(restored.soundVolumes, equals(session.soundVolumes));
      expect(restored.timerDuration, equals(session.timerDuration));
    });
  });
}
