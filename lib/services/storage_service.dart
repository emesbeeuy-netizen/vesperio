import 'dart:convert';
import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sleep_session_hive_adapter.dart';
import '../models/sleep_session.dart';

class StorageService {
  static const String userBoxName = 'user_box';
  static const String sessionsBoxName = 'sessions_box';
  static const String settingsBoxName = 'settings_box';

  static final StorageService _instance = StorageService._internal();
  late Box<dynamic> _userBox;
  late Box<dynamic> _sessionsBox;
  late Box<dynamic> _settingsBox;

  factory StorageService() {
    return _instance;
  }

  StorageService._internal();

  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SleepSessionAdapter());
    }

    _userBox = await Hive.openBox(userBoxName);
    _sessionsBox = await Hive.openBox(sessionsBoxName);
    _settingsBox = await Hive.openBox(settingsBoxName);

    // Simple migration: if sessions are stored as Map<String, dynamic>, convert
    // them to typed SleepSession objects using our adapter and set storage version.
    final currentVersion = _settingsBox.get('storage_version', defaultValue: 0) as int;
    if (currentVersion < 1) {
      for (final key in _sessionsBox.keys) {
        final value = _sessionsBox.get(key);
        if (value is Map) {
          try {
            final session = SleepSession.fromMap(Map<String, dynamic>.from(value));
            await _sessionsBox.put(key, session);
          } catch (_) {
            // If conversion fails, leave original value.
          }
        }
      }
      await _settingsBox.put('storage_version', 1);
    }
  }

  /// Export all sessions to a JSON file in the app documents directory.
  /// Returns the exported file path.
  Future<String> exportSessionsToFile({String? filename}) async {
    final docs = await getApplicationDocumentsDirectory();
    final file = File('${docs.path}/${filename ?? 'sessions_backup.json'}');
    final List<Map<String, dynamic>> sessions = [];
    for (final v in _sessionsBox.values) {
      if (v is SleepSession) {
        sessions.add(v.toMap());
      } else if (v is Map) {
        sessions.add(Map<String, dynamic>.from(v));
      }
    }
    await file.writeAsString(jsonEncode(sessions));
    return file.path;
  }

  /// Import sessions from a JSON file. Merges sessions by id.
  Future<void> importSessionsFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return;
    final content = await file.readAsString();
    final List<dynamic> decoded = jsonDecode(content) as List<dynamic>;
    for (final item in decoded) {
      if (item is Map<String, dynamic>) {
        try {
          final session = SleepSession.fromMap(item);
          await _sessionsBox.put(session.id, session);
        } catch (_) {
          // skip invalid entries
        }
      }
    }
  }

  // User data operations
  Future<void> saveUserData(String key, dynamic value) async {
    await _userBox.put(key, value);
  }

  dynamic getUserData(String key, [dynamic defaultValue]) {
    return _userBox.get(key, defaultValue: defaultValue);
  }

  Future<void> deleteUserData(String key) async {
    await _userBox.delete(key);
  }

  Future<void> clearUserData() async {
    await _userBox.clear();
  }

  // Session data operations
  Future<void> saveSession(String sessionId, dynamic sessionData) async {
    await _sessionsBox.put(sessionId, sessionData);
  }

  dynamic getSession(String sessionId) {
    return _sessionsBox.get(sessionId);
  }

  Iterable<dynamic> getAllSessions() {
    return _sessionsBox.values;
  }

  Future<void> deleteSession(String sessionId) async {
    await _sessionsBox.delete(sessionId);
  }

  Future<void> clearAllSessions() async {
    await _sessionsBox.clear();
  }

  // Settings operations
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  dynamic getSetting(String key, [dynamic defaultValue]) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> deleteSetting(String key) async {
    await _settingsBox.delete(key);
  }

  // Mixer presets helpers
  Future<void> saveMixerPreset(String name, Map<String, dynamic> data) async {
    final raw = _settingsBox.get('mixer_presets');
    Map<String, dynamic> presets = {};
    if (raw is Map) presets = Map<String, dynamic>.from(raw);
    presets[name] = data;
    await _settingsBox.put('mixer_presets', presets);
  }

  Map<String, dynamic> getMixerPresets() {
    final raw = _settingsBox.get('mixer_presets');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  Future<void> deleteMixerPreset(String name) async {
    final raw = _settingsBox.get('mixer_presets');
    if (raw is Map) {
      final presets = Map<String, dynamic>.from(raw);
      presets.remove(name);
      await _settingsBox.put('mixer_presets', presets);
    }
  }

  // Close all boxes
  Future<void> close() async {
    await Hive.close();
  }
}
