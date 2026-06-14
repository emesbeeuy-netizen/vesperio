import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vesperio/providers/audio_player_provider.dart';
import 'package:vesperio/models/sound.dart';
import 'package:vesperio/services/audio_service.dart';
import 'package:vesperio/services/storage_service.dart';
import 'package:vesperio/services/notification_service.dart';

class MockAudioService extends Mock implements AudioService {}
class MockStorageService extends Mock implements StorageService {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Sound(
      id: 'fallback',
      name: 'fallback',
      description: 'fallback',
      filePath: 'fallback',
      duration: Duration.zero,
      category: 'none',
      imageAsset: 'none',
    ));
    registerFallbackValue(<Sound>[]);
  });
  late MockAudioService mockAudio;
  late MockStorageService mockStorage;
  late MockNotificationService mockNotification;
  late AudioPlayerProvider provider;

  setUp(() {
    mockAudio = MockAudioService();
    mockStorage = MockStorageService();
    mockNotification = MockNotificationService();

    // Default stubs for streams
    when(() => mockAudio.onPositionChanged()).thenAnswer((_) => const Stream<Duration>.empty());
    when(() => mockAudio.onDurationChanged()).thenAnswer((_) => const Stream<Duration>.empty());

    // Default no-op for async methods
    when(() => mockAudio.playSingleSound(any(), volume: any(named: 'volume'))).thenAnswer((_) async {});
    when(() => mockAudio.playMultipleSounds(any(), any())).thenAnswer((_) async {});
    when(() => mockAudio.stopAll()).thenAnswer((_) async {});
    when(() => mockAudio.pause()).thenAnswer((_) async {});
    when(() => mockAudio.resume()).thenAnswer((_) async {});

    when(() => mockStorage.saveSession(any(), any())).thenAnswer((_) async {});
    when(() => mockNotification.scheduleNotification(id: any(named: 'id'), title: any(named: 'title'), body: any(named: 'body'), scheduledTime: any(named: 'scheduledTime'), payload: any(named: 'payload'))).thenAnswer((_) async {});
    when(() => mockNotification.showNotification(id: any(named: 'id'), title: any(named: 'title'), body: any(named: 'body'), payload: any(named: 'payload'))).thenAnswer((_) async {});
    when(() => mockNotification.cancelNotification(any())).thenAnswer((_) async {});

    provider = AudioPlayerProvider(
      audioService: mockAudio,
      storageService: mockStorage,
      notificationService: mockNotification,
    );
  });

  test('addSound adds a sound to currentSounds', () async {
    final sound = Sound(
      id: 'rain',
      name: 'Rain',
      description: 'Gentle rain',
      filePath: 'assets/sounds/free/rain.mp3',
      duration: const Duration(minutes: 3),
      category: 'nature',
      imageAsset: 'assets/images/rain.png',
    );

    expect(provider.currentSounds, isEmpty);
    await provider.addSound(sound);
    expect(provider.currentSounds.length, 1);
    expect(provider.currentSounds.first, sound);

    // Since provider is stopped by default, playMultipleSounds should not be called
    verifyNever(() => mockAudio.playMultipleSounds(any(), any()));
  });

  test('play calls playSingleSound when one sound present', () async {
    final sound = Sound(
      id: 'sea',
      name: 'Sea Waves',
      description: 'Ocean waves',
      filePath: 'assets/sounds/free/sea.mp3',
      duration: const Duration(minutes: 4),
      category: 'nature',
      imageAsset: 'assets/images/sea.png',
    );

    await provider.addSound(sound);
    await provider.play();

    verify(() => mockAudio.playSingleSound(sound, volume: 1.0)).called(1);
    expect(provider.isPlaying, isTrue);
  });
}
