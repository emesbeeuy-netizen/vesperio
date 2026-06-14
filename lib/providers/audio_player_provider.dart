import 'dart:async';
import 'dart:collection';

import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/audio_service.dart';
import '../services/home_widget_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/preferences_service.dart';

enum PlayerState { playing, paused, stopped }

class AudioPlayerProvider extends ChangeNotifier {
  late final AudioService _audioService;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;

  PlayerState _state = PlayerState.stopped;
  final List<Sound> _currentSounds = [];
  final List<double> _volumes = [];
  final Set<String> _currentSoundIds = {};
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  int? _timerMinutes;
  DateTime? _timerEndTime;
  Timer? _sleepTimer;
  Timer? _countdownTicker;
  SleepSession? _currentSession;
  SleepSession? _pendingRatingSession;
  bool _screenOffMode = false;
  DateTime? _lastPositionNotify;
  late final StorageService _storageService;
  late final NotificationService _notificationService;
  late final PreferencesService _preferencesService;
  List<String>? _recentlyPlayedIds;
  int _recentlyPlayedVersion = 0;
  static const int _timerNotificationId = 1000;
  static const Duration _positionNotifyInterval = Duration(milliseconds: 250);

  // Getters
  PlayerState get state => _state;
  List<Sound> get currentSounds => UnmodifiableListView(_currentSounds);
  List<double> get volumes => UnmodifiableListView(_volumes);
  Set<String> get currentSoundIds => UnmodifiableSetView(_currentSoundIds);
  Duration get duration => _duration;
  Duration get position => _position;
  int? get timerMinutes => _timerMinutes;
  DateTime? get timerEndTime => _timerEndTime;
  bool get isPlaying => _state == PlayerState.playing;
  bool get timerActive => _timerMinutes != null;
  bool get screenOffMode => _screenOffMode;
  SleepSession? get pendingRatingSession => _pendingRatingSession;

  Duration get timerRemaining {
    if (_timerEndTime == null) return Duration.zero;
    final diff = _timerEndTime!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  double get progress => duration.inSeconds > 0
    ? (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0)
    : 0.0;

  List<String> get recentlyPlayedIds {
    _recentlyPlayedIds ??= _preferencesService.getRecentlyPlayed();
    return List.unmodifiable(_recentlyPlayedIds!);
  }

  int get recentlyPlayedVersion => _recentlyPlayedVersion;

  AudioPlayerProvider({
    AudioService? audioService,
    StorageService? storageService,
    NotificationService? notificationService,
    PreferencesService? preferencesService,
  }) {
    _audioService = audioService ?? AudioService();
    _storageService = storageService ?? StorageService();
    _notificationService = notificationService ?? NotificationService();
    _preferencesService = preferencesService ?? PreferencesService();
    _initializeAudioListeners();
  }

  void _initializeAudioListeners() {
    _positionSubscription = _audioService.onPositionChanged().listen((position) {
      updatePosition(position);
    });
    _durationSubscription = _audioService.onDurationChanged().listen((duration) {
      updateDuration(duration);
    });
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _sleepTimer?.cancel();
    _countdownTicker?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  // Add a sound to the mixer
  Future<void> addSound(Sound sound) async {
    if (_currentSounds.length >= 4) return;
    _currentSounds.add(sound);
    _currentSoundIds.add(sound.id);
    _volumes.add(1.0);
    notifyListeners(); // update UI immediately

    // Restart playback and persist in the background.
    if (_state == PlayerState.playing) {
      unawaited(_audioService.playMultipleSounds(_currentSounds, List.of(_volumes)));
    }
    unawaited(_persistMixerState());
  }

  Future<void> removeSound(String soundId) async {
    final index = _currentSounds.indexWhere((s) => s.id == soundId);
    if (index == -1) return;
    _currentSounds.removeAt(index);
    _currentSoundIds.remove(soundId);
    _volumes.removeAt(index);
    notifyListeners(); // update UI immediately

    // Restart playback and persist in the background.
    final soundsCopy  = List<Sound>.of(_currentSounds);
    final volumesCopy = List<double>.of(_volumes);
    unawaited(_audioService.stopAll().then((_) async {
      if (soundsCopy.isNotEmpty && _state == PlayerState.playing) {
        await _audioService.playMultipleSounds(soundsCopy, volumesCopy);
      }
    }));
    unawaited(_persistMixerState());
  }

  // Update volume of a sound
  Future<void> updateSoundVolume(String soundId, double volume) async {
    final index = _currentSounds.indexWhere((s) => s.id == soundId);
    if (index == -1) return;

    final normalized = volume.clamp(0.0, 1.0);
    if (_volumes[index] == normalized) return;

    _volumes[index] = normalized;
    notifyListeners(); // update % label immediately on every drag event

    // Apply to audio player and persist in the background.
    unawaited(_audioService.setVolume(soundId, index, normalized));
    unawaited(_persistMixerState());
  }

  /// Restore mixer state from a list of sounds and volumes.
  Future<void> restoreFromIds(List<Sound> sounds, List<double> volumes, {bool playAfter = false}) async {
    _currentSounds
      ..clear()
      ..addAll(sounds);
    _currentSoundIds.clear();
    for (final sound in sounds) {
      _currentSoundIds.add(sound.id);
    }
    _volumes
      ..clear()
      ..addAll(volumes);
    if (playAfter) {
      await play();
    } else {
      notifyListeners();
    }
    await _persistMixerState();
  }

  Future<void> _persistMixerState() async {
    try {
      final List<String> soundIds = [];
      for (final s in _currentSounds) {
        soundIds.add(s.id);
      }
      final data = {
        'soundIds': soundIds,
        'volumes': _volumes,
      };
      await _storageService.saveSetting('mixer_last', data);
    } catch (_) {
      // ignore persistence failures
    }
  }

  void _ensureSessionStarted() {
    if (_currentSession != null || _currentSounds.isEmpty) {
      return;
    }

    _currentSession = SleepSession(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      soundIds: () {
        final ids = <String>[];
        for (final s in _currentSounds) {
          ids.add(s.id);
        }
        return ids;
      }(),
      soundVolumes: List<double>.from(_volumes),
      timerDuration: _timerMinutes,
      isActive: true,
      totalMinutesListened: 0,
    );
  }

  Future<void> _finishSession() async {
    if (_currentSession == null) return;

    final endTime = DateTime.now();
    final minutesListened = endTime.difference(_currentSession!.startTime).inMinutes;
    final session = _currentSession!.copyWith(
      endTime: endTime,
      isActive: false,
      totalMinutesListened: minutesListened,
      timerDuration: _currentSession!.timerDuration,
    );
    await _storageService.saveSession(session.id, session.toMap());
    // Offer quality rating for sessions of at least 1 minute.
    if (minutesListened >= 1) {
      _pendingRatingSession = session;
    }
    _currentSession = null;
  }

  Future<void> submitSessionQualityRating(int rating) async {
    if (_pendingRatingSession == null) return;
    final updated = _pendingRatingSession!.copyWith(sleepQuality: rating);
    await _storageService.saveSession(updated.id, updated.toMap());
    _pendingRatingSession = null;
    // Schedule morning check-in for the next session cycle.
    unawaited(_notificationService.scheduleMorningCheckIn());
    notifyListeners();
  }

  void clearPendingRating() {
    _pendingRatingSession = null;
    notifyListeners();
  }

  // Play audio
  Future<void> play() async {
    await _audioService.stopAll();
    _ensureSessionStarted();
    if (_currentSounds.length == 1) {
      await _audioService.playSingleSound(
        _currentSounds.first,
        volume: _volumes.first,
      );
    } else {
      await _audioService.playMultipleSounds(_currentSounds, _volumes);
    }
    _state = PlayerState.playing;
    await _notificationService.cancelNotification(_timerNotificationId);
    unawaited(HomeWidgetService.instance.update(
      soundName: _currentSounds.isNotEmpty ? _currentSounds.first.name : 'Playing',
      isPlaying: true,
    ));
    notifyListeners();
  }

  Future<void> playSound(Sound sound) async {
    _currentSounds
      ..clear()
      ..add(sound);
    _currentSoundIds
      ..clear()
      ..add(sound.id);
    _volumes
      ..clear()
      ..add(1.0);
    _trackRecentlyPlayed(sound.id);
    await play();
  }

  void _trackRecentlyPlayed(String soundId) {
    _recentlyPlayedIds ??= _preferencesService.getRecentlyPlayed();
    _recentlyPlayedIds!.remove(soundId);
    _recentlyPlayedIds!.insert(0, soundId);
    if (_recentlyPlayedIds!.length > 10) _recentlyPlayedIds!.removeLast();
    _recentlyPlayedVersion++;
    unawaited(_preferencesService.addRecentlyPlayed(soundId));
  }

  // Pause audio
  Future<void> pause() async {
    await _audioService.pause();
    _state = PlayerState.paused;
    notifyListeners();
  }

  // Resume audio
  Future<void> resume() async {
    await _audioService.resume();
    _state = PlayerState.playing;
    notifyListeners();
  }

  // Stop audio
  Future<void> stop() async {
    await _audioService.stopAll();
    await _finishSession();
    _state = PlayerState.stopped;
    _currentSounds.clear();
    _currentSoundIds.clear();
    _volumes.clear();
    _duration = Duration.zero;
    _position = Duration.zero;
    _timerMinutes = null;
    _timerEndTime = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _countdownTicker?.cancel();
    _countdownTicker = null;
    await _notificationService.cancelNotification(_timerNotificationId);
    unawaited(HomeWidgetService.instance.clear());
    notifyListeners();
  }

  // Set timer
  Future<void> setTimer(int minutes) async {
    _timerMinutes = minutes;
    _sleepTimer?.cancel();
    _countdownTicker?.cancel();
    final duration = Duration(minutes: minutes);
    _timerEndTime = DateTime.now().add(duration);
    _sleepTimer = Timer(duration, () async {
      await _notificationService.showNotification(
        id: _timerNotificationId,
        title: 'Sleep timer complete',
        body: 'Your sleep sound timer has finished.',
        payload: 'sleep_timer',
      );
      // Determine fade duration from preferences
      try {
        final unlimited = _preferencesService.getUnlimitedFade();
        final fadeSec = _preferencesService.getFadeSeconds();
        final durationSeconds = unlimited ? 600 : fadeSec;
        await stopWithFade(fadeSeconds: durationSeconds);
      } catch (_) {
        await stopWithFade();
      }
    });

    await _notificationService.scheduleNotification(
      id: _timerNotificationId,
      title: 'Sleep timer ending',
      body: 'Your sounds will stop in $minutes minutes.',
      scheduledTime: DateTime.now().add(duration),
      payload: 'sleep_timer',
    );

    // Tick every second so the countdown display stays current.
    _countdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
    });

    notifyListeners();
  }

  // Clear timer
  Future<void> clearTimer() async {
    _timerMinutes = null;
    _timerEndTime = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _countdownTicker?.cancel();
    _countdownTicker = null;
    await _notificationService.cancelNotification(_timerNotificationId);
    notifyListeners();
  }

  /// Stop with a short fade-out.
  Future<void> stopWithFade({int fadeSeconds = 3}) async {
    await _audioService.stopAll(fadeOut: true, fadeDurationSeconds: fadeSeconds);
    await _finishSession();
    _state = PlayerState.stopped;
    _currentSounds.clear();
    _currentSoundIds.clear();
    _volumes.clear();
    _duration = Duration.zero;
    _position = Duration.zero;
    _timerMinutes = null;
    _timerEndTime = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _countdownTicker?.cancel();
    _countdownTicker = null;
    await _notificationService.cancelNotification(_timerNotificationId);
    notifyListeners();
  }

  // Toggle screen off mode
  void toggleScreenOffMode() {
    _screenOffMode = !_screenOffMode;
    notifyListeners();
  }

  // Update position (called by audio player)
  void updatePosition(Duration position) {
    final now = DateTime.now();
    final positionChanged = position != _position;
    final shouldNotify = positionChanged &&
        (_lastPositionNotify == null ||
            now.difference(_lastPositionNotify!) >= _positionNotifyInterval ||
            position == Duration.zero ||
            position == _duration ||
            position < _position);

    _position = position;
    if (shouldNotify) {
      _lastPositionNotify = now;
      notifyListeners();
    }
  }

  // Update duration (called by audio player)
  void updateDuration(Duration duration) {
    if (duration != _duration) {
      _duration = duration;
      notifyListeners();
    }
  }

  // Clear current session
  Future<void> clearSession() async {
    await _finishSession();
    _state = PlayerState.stopped;
    _currentSounds.clear();
    _currentSoundIds.clear();
    _volumes.clear();
    _duration = Duration.zero;
    _position = Duration.zero;
    _timerMinutes = null;
    _timerEndTime = null;
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _countdownTicker?.cancel();
    _countdownTicker = null;
    _screenOffMode = false;
    await _notificationService.cancelNotification(_timerNotificationId);
    notifyListeners();
  }
}
