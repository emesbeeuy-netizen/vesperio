import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// Pushes playback state to the native home screen widget.
///
/// Android: reads from SharedPreferences named "HomeWidgetPreferences".
/// iOS: reads from the App Group container (configure group id below).
///
/// Call [update] whenever the audio state or current sound changes.
class HomeWidgetService {
  HomeWidgetService._();
  static final HomeWidgetService instance = HomeWidgetService._();

  // Replace with your iOS App Group ID once the WidgetKit extension is added
  // in Xcode (Runner target → Signing & Capabilities → App Groups).
  static const _iOSGroupId = 'group.com.vesperio.app';
  static const _androidWidgetName = 'VesperioWidget';
  static const _keySound = 'widgetCurrentSound';
  static const _keyPlaying = 'widgetIsPlaying';

  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    _initialized = true;
    await HomeWidget.setAppGroupId(_iOSGroupId);
  }

  /// Updates the widget to reflect [soundName] and [isPlaying].
  Future<void> update({
    required String soundName,
    required bool isPlaying,
  }) async {
    try {
      await _ensureInit();
      await HomeWidget.saveWidgetData<String>(_keySound, soundName);
      await HomeWidget.saveWidgetData<bool>(_keyPlaying, isPlaying);
      await HomeWidget.updateWidget(
        androidName: _androidWidgetName,
        iOSName: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('HomeWidgetService.update error: $e');
    }
  }

  /// Clears the widget back to the idle state.
  Future<void> clear() => update(soundName: 'Tap to play', isPlaying: false);
}
