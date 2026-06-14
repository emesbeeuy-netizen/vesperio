import 'package:audioplayers/audioplayers.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import '../models/index.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Map<String, AudioPlayer> _soundPlayers = {};
  final Future<void> _audioSessionInitialization;

  AudioService() : _audioSessionInitialization = _initializeAudioSession();

  static Future<void> _initializeAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      await session.setActive(true);
    } catch (e) {
      debugPrint('Audio session init failed: $e');
    }
  }

  String _normalizeAssetPath(String path) {
    var normalized = path;
    while (normalized.startsWith('assets/')) {
      normalized = normalized.substring('assets/'.length);
    }
    while (normalized.startsWith('/')) {
      normalized = normalized.substring(1);
    }
    return normalized;
  }

  Future<void> _playAssetSource(
    AudioPlayer player,
    String assetPath,
    bool isPremium,
  ) async {
    final normalizedPath = _normalizeAssetPath(assetPath);
    final candidates = <String>[
      normalizedPath,
      'assets/$normalizedPath',
    ];

    for (final candidate in candidates) {
      try {
        await player.play(AssetSource(candidate));
        return;
      } catch (e) {
        debugPrint('Asset play failed for "$candidate": $e');
      }
    }

    final fallback = isPremium
        ? 'sounds/premium/sample_premium.m4a'
        : 'sounds/free/sample_free.m4a';
    try {
      await player.play(AssetSource(fallback));
    } catch (e) {
      debugPrint('Fallback play also failed for "$fallback": $e');
    }
  }

  // Play a single sound
  Future<void> playSingleSound(Sound sound, {double volume = 1.0}) async {
    try {
      await _audioSessionInitialization;
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(volume);
      if (sound.filePath.startsWith('http')) {
        await _audioPlayer.play(UrlSource(sound.filePath));
      } else {
        await _playAssetSource(_audioPlayer, sound.filePath, sound.isPremium);
      }
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  // Play multiple sounds (mixer mode)
  Future<void> playMultipleSounds(
    List<Sound> sounds,
    List<double> volumes,
  ) async {
    try {
      await _audioSessionInitialization;
      // Stop all existing players
      await stopAll();

      // Create and play each sound with its volume
      for (int i = 0; i < sounds.length; i++) {
        final player = AudioPlayer();
        // Use only soundId as key (not index) to avoid issues when sounds are removed
        _soundPlayers[sounds[i].id] = player;
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setVolume(volumes[i]);
        if (sounds[i].filePath.startsWith('http')) {
          await player.play(UrlSource(sounds[i].filePath));
        } else {
          await _playAssetSource(player, sounds[i].filePath, sounds[i].isPremium);
        }
      }
    } catch (e) {
      debugPrint('Error playing multiple sounds: $e');
    }
  }

  // Pause current audio
  Future<void> pause() async {
    await _audioPlayer.pause();
    for (final player in _soundPlayers.values) {
      await player.pause();
    }
  }

  // Resume current audio
  Future<void> resume() async {
    await _audioPlayer.resume();
    for (final player in _soundPlayers.values) {
      await player.resume();
    }
  }

  // Set volume for the shared player or a mixer track
  Future<void> setVolume(String soundId, int index, double volume) async {
    // Try to find the player by soundId first (mixer mode)
    if (_soundPlayers.containsKey(soundId)) {
      await _soundPlayers[soundId]!.setVolume(volume);
    } else if (index == 0 && _soundPlayers.isEmpty) {
      // Fallback for single sound playback
      await _audioPlayer.setVolume(volume);
    }
  }

  // Stop current audio
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  // Stop all sounds
  Future<void> stopAll({
    bool fadeOut = false,
    int fadeDurationSeconds = 3,
  }) async {
    if (fadeOut && _soundPlayers.isNotEmpty) {
      // Gradually reduce volume for all players
      const int steps = 12;
      final stepDelay = Duration(
        milliseconds: (fadeDurationSeconds * 1000 ~/ steps),
      );
      for (int step = 0; step < steps; step++) {
        final t = 1.0 - (step + 1) / steps; // remaining volume factor
        for (final entry in _soundPlayers.entries) {
          try {
            await entry.value.setVolume(t);
          } catch (_) {}
        }
        try {
          await _audioPlayer.setVolume(t);
        } catch (_) {}
        await Future.delayed(stepDelay);
      }
    }

    await _audioPlayer.stop();
    for (final player in _soundPlayers.values) {
      await player.stop();
    }
    _soundPlayers.clear();
  }

  // Update volume of a specific sound in mixer
  Future<void> updateVolume(String soundId, int index, double volume) async {
    if (_soundPlayers.containsKey(soundId)) {
      await _soundPlayers[soundId]!.setVolume(volume);
    }
  }

  // Get current playback state
  PlayerState getCurrentState() {
    return _audioPlayer.state;
  }

  // Listen to player state changes
  Stream<PlayerState> onStateChanged() {
    return _audioPlayer.onPlayerStateChanged;
  }

  // Listen to duration changes
  Stream<Duration> onDurationChanged() {
    return _audioPlayer.onDurationChanged;
  }

  // Listen to position changes
  Stream<Duration> onPositionChanged() {
    return _audioPlayer.onPositionChanged;
  }

  // Dispose resources
  void dispose() {
    _audioPlayer.dispose();
    for (final player in _soundPlayers.values) {
      player.dispose();
    }
    _soundPlayers.clear();
  }
}
