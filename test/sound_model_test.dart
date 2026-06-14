import 'package:flutter_test/flutter_test.dart';
import 'package:vesperio/models/sound.dart';

void main() {
  test('Sound copyWith and equality', () {
    final s1 = Sound(
      id: 'rain1',
      name: 'Rain',
      description: 'Soft rain',
      filePath: 'assets/sounds/free/rain1.mp3',
      duration: const Duration(minutes: 30),
      isPremium: false,
      isDownloaded: false,
      category: 'rain',
      imageAsset: 'assets/images/rain1.png',
      volume: 1.0,
    );

    final s2 = s1.copyWith(name: 'Rainy Night');
    expect(s2.name, 'Rainy Night');
    expect(s1 == s1, isTrue);
    // equality uses id only, so copyWith that keeps id should be equal
    expect(s1 == s2, isTrue);
  });
}
