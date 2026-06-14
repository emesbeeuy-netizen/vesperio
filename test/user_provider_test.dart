import 'package:flutter_test/flutter_test.dart';
import 'package:vesperio/providers/user_provider.dart';

void main() {
  group('UserProvider', () {
    test('initializes with default user and reports not premium', () {
      final provider = UserProvider();
      expect(provider.isInitialized, isTrue);
      // Premium state is driven by RevenueCat entitlements; starts false
      // until the SDK confirms an active subscription.
      expect(provider.isPremium, isFalse);
    });
  });
}
