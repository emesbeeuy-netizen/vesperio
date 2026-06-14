import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../constants/app_constants.dart';
import 'storage_service.dart';

enum PremiumPlan { weekly, monthly, annual }

extension PremiumPlanX on PremiumPlan {
  String get label {
    switch (this) {
      case PremiumPlan.weekly:  return 'weekly';
      case PremiumPlan.monthly: return 'monthly';
      case PremiumPlan.annual:  return 'annual';
    }
  }

  String get fallbackPrice {
    switch (this) {
      case PremiumPlan.weekly:  return AppStrings.premiumWeeklyFallbackPrice;
      case PremiumPlan.monthly: return AppStrings.premiumMonthlyFallbackPrice;
      case PremiumPlan.annual:  return AppStrings.premiumAnnualFallbackPrice;
    }
  }
}

class PurchaseService {
  PurchaseService._();
  static final PurchaseService instance = PurchaseService._();

  // Public so UserProvider can reference the same string without duplication.
  static const entitlementId = 'premium';
  static const _entitlementId = entitlementId;

  // Set these from your RevenueCat dashboard → Apps.
  static const _iosApiKey     = 'appl_OZWTOKJNEfsYjbtQtJKRdilhVfR';
  static const _androidApiKey = 'goog_SfPrhhfxXOlKHXUWitJRqEwsvDt';

  Offerings? _offerings;

  // Broadcast stream backed by Purchases.addCustomerInfoUpdateListener.
  final StreamController<CustomerInfo> _customerInfoController =
      StreamController<CustomerInfo>.broadcast();
  Stream<CustomerInfo> get customerInfoStream => _customerInfoController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;
    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    final key = defaultTargetPlatform == TargetPlatform.iOS
        ? _iosApiKey
        : _androidApiKey;
    await Purchases.configure(PurchasesConfiguration(key));
    // Only mark initialized after configure succeeds so a failure is retryable.
    _initialized = true;
    // Forward RevenueCat callbacks into the broadcast stream. The SDK calls
    // the listener immediately with the last cached CustomerInfo if available.
    Purchases.addCustomerInfoUpdateListener(_customerInfoController.add);
    // Link session to the app's stable user ID if one already exists (i.e. not
    // first launch). On first launch UserProvider calls logIn() after it mints
    // the UUID and persists it to storage.
    final storedUserId = StorageService().getUserData('user_id') as String?;
    if (storedUserId != null) {
      await logIn(storedUserId);
    }
    await _fetchOfferings();
  }

  /// Links the current RevenueCat session to [userId].
  /// Safe to call multiple times — RevenueCat is a no-op if the ID matches.
  Future<void> logIn(String userId) async {
    if (!_initialized || kIsWeb) return;
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('RevenueCat: logIn failed: $e');
    }
  }

  Future<void> _fetchOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCat: failed to load offerings: $e');
    }
  }

  /// Re-fetches offerings from RevenueCat. Call when the screen opens if
  /// offerings weren't available at startup (e.g. network not ready).
  Future<void> refreshOfferings() => _fetchOfferings();

  // Returns the RevenueCat Package for a plan, or null if offerings not loaded.
  // Lookup order: (1) RevenueCat standard package type → (2) product identifier.
  Package? packageForPlan(PremiumPlan plan) {
    final offering = _offerings?.current;
    if (offering == null) return null;

    // 1. Standard RevenueCat package-type properties.
    final byType = switch (plan) {
      PremiumPlan.weekly  => offering.weekly,
      PremiumPlan.monthly => offering.monthly,
      PremiumPlan.annual  => offering.annual,
    };
    if (byType != null) return byType;

    // 2. Match by the product identifier defined in AppStrings — handles
    //    RevenueCat offerings where packages use custom identifiers.
    final productId = switch (plan) {
      PremiumPlan.weekly  => AppStrings.premiumProductIdWeekly,
      PremiumPlan.monthly => AppStrings.premiumProductId,
      PremiumPlan.annual  => AppStrings.premiumProductIdAnnual,
    };
    return offering.availablePackages.cast<Package?>().firstWhere(
      (p) => p?.storeProduct.identifier == productId,
      orElse: () => null,
    );
  }

  // Price string from the store, falling back to hardcoded defaults while loading.
  String priceForPlan(PremiumPlan plan) {
    return packageForPlan(plan)?.storeProduct.priceString ?? plan.fallbackPrice;
  }

  /// Whether [plan] has a free introductory trial configured in the store.
  bool hasFreeTrial(PremiumPlan plan) {
    final intro = packageForPlan(plan)?.storeProduct.introductoryPrice;
    return intro != null && intro.price == 0;
  }

  /// Human-readable trial label from the store, e.g. "7-day free trial".
  /// Returns null when no trial is available or offerings are still loading.
  String? trialDescription(PremiumPlan plan) {
    final intro = packageForPlan(plan)?.storeProduct.introductoryPrice;
    if (intro == null || intro.price != 0) return null;
    final n = intro.periodNumberOfUnits;
    return switch (intro.periodUnit) {
      PeriodUnit.day   => '$n-day free trial',
      PeriodUnit.week  => '$n-week free trial',
      PeriodUnit.month => '$n-month free trial',
      _                => 'free trial',
    };
  }

  // Checks the store (uses local cache, very fast) for an active premium entitlement.
  Future<bool> isPremiumActive() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_entitlementId);
    } catch (_) {
      return false;
    }
  }

  // Returns CustomerInfo on success, null if the user cancelled, throws on error.
  Future<CustomerInfo?> purchasePlan(PremiumPlan plan) async {
    final pkg = packageForPlan(plan);
    if (pkg == null) {
      throw Exception(
        'Could not load this product from the App Store. Please check your connection and tap Retry.',
      );
    }
    try {
      return await Purchases.purchasePackage(pkg);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return null;
      rethrow;
    }
  }

  // Restores prior subscriptions for the current App Store / Play Store account.
  Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }
}
