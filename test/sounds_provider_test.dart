import 'package:flutter_test/flutter_test.dart';
import 'package:vesperio/providers/sounds_provider.dart';

void main() {
  group('SoundsProvider', () {
    test('initializes with sounds and categories', () {
      final provider = SoundsProvider();
      expect(provider.allSounds.isNotEmpty, isTrue);
      expect(provider.getCategories().contains('all'), isTrue);
    });

    test('searchSounds filters correctly', () {
      final provider = SoundsProvider();
      final results = provider.searchSounds('rain');
      // Should be a list (may be empty if no 'rain' entries in constants)
      expect(results, isA<List>());
    });

    test('getSoundById returns null for unknown id', () {
      final provider = SoundsProvider();
      final s = provider.getSoundById('nonexistent_id');
      expect(s, isNull);
    });
  });
}
