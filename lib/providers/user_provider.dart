import 'dart:async';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';

class UserProvider extends ChangeNotifier {
  static const _kUserId = 'user_id';
  static const _kIsFirstLaunch = 'user_is_first_launch';
  static const _kTotalMinutes = 'user_total_minutes';
  static const _kDownloadedSounds = 'user_downloaded_sounds';
  static const _kRewardExpiresAtMs = 'reward_expires_at_ms';
  static const _kFavoriteSoundIds = 'user_favorite_sound_ids';

  late User _user;
  bool _isInitialized = false;
  bool _isPremium = false;
  DateTime? _rewardExpiresAt;
  Set<String> _favoriteSoundIds = {};
  StreamSubscription<CustomerInfo>? _customerInfoSub;
  final AuthService _authService = AuthService();
  final StorageService _storage = StorageService();

  User get user => _user;
  bool get isInitialized => _isInitialized;
  // Backed by RevenueCat entitlement — authoritative source of truth.
  bool get isPremium => _isPremium;
  bool get isLoggedIn => _user.isLoggedIn;

  bool get hasActiveReward {
    final expiry = _rewardExpiresAt;
    if (expiry == null) return false;
    return expiry.isAfter(DateTime.now());
  }

  /// True when the user has either an active premium subscription or an active ad reward.
  bool get isPremiumOrRewarded => isPremium || hasActiveReward;

  /// How much reward time remains (zero if no active reward).
  Duration get rewardTimeRemaining {
    final expiry = _rewardExpiresAt;
    if (expiry == null) return Duration.zero;
    final diff = expiry.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  UserProvider() {
    _initializeUser();
    _listenToEntitlements();
  }

  void _initializeUser() {
    final storedId = _storage.getUserData(_kUserId) as String?;
    // null means key was never written → treat as first launch
    final isFirstLaunch = _storage.getUserData(_kIsFirstLaunch) != false;
    final totalMinutes =
        (_storage.getUserData(_kTotalMinutes) as num?)?.toInt() ?? 0;
    final rawDownloads = _storage.getUserData(_kDownloadedSounds);
    final downloadedSoundIds =
        rawDownloads is List ? List<String>.from(rawDownloads) : <String>[];

    final rewardMs = _storage.getUserData(_kRewardExpiresAtMs) as int?;
    if (rewardMs != null) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(rewardMs);
      if (expiry.isAfter(DateTime.now())) {
        _rewardExpiresAt = expiry;
      }
    }

    final rawFavorites = _storage.getUserData(_kFavoriteSoundIds);
    _favoriteSoundIds = rawFavorites is List
        ? Set<String>.from(rawFavorites)
        : <String>{};

    final userId = storedId ?? const Uuid().v4();
    if (storedId == null) {
      _storage.saveUserData(_kUserId, userId);
      // First launch: mint a new UUID and immediately link it to RevenueCat.
      // PurchaseService.initialize() ran before UserProvider was created but
      // had no stored ID yet, so we do it here.
      unawaited(PurchaseService.instance.logIn(userId));
    }

    _user = User(
      id: userId,
      isPremium: false,
      premiumExpiryDate: DateTime.now(),
      downloadedSoundIds: downloadedSoundIds,
      totalListeningMinutes: totalMinutes,
      lastListenedDate: DateTime.now(),
      isFirstLaunch: isFirstLaunch,
      isLoggedIn: _authService.isLoggedIn,
      email: _authService.userEmail,
      displayName: _authService.displayName,
    );
    _isInitialized = true;
  }

  // Fetches the current entitlement state from RevenueCat (cached locally,
  // fast) and subscribes to real-time changes for the app's lifetime.
  void _listenToEntitlements() {
    PurchaseService.instance.isPremiumActive().then((active) {
      if (active == _isPremium) return;
      _isPremium = active;
      notifyListeners();
    }).catchError((_) {
      // Silently ignore — stays free-tier until the next successful check.
    });
    _customerInfoSub = PurchaseService.instance.customerInfoStream.listen(
      (info) {
        final active = info.entitlements.active
            .containsKey(PurchaseService.entitlementId);
        if (active == _isPremium) return;
        _isPremium = active;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _customerInfoSub?.cancel();
    super.dispose();
  }

  /// Grants temporary premium-level features for [duration] (typically 2 hours).
  Future<void> grantTemporaryReward(Duration duration) async {
    _rewardExpiresAt = DateTime.now().add(duration);
    await _storage.saveUserData(
      _kRewardExpiresAtMs,
      _rewardExpiresAt!.millisecondsSinceEpoch,
    );
    notifyListeners();
  }

  // Favorites
  List<String> get favoriteSoundIds => List.unmodifiable(_favoriteSoundIds.toList());
  bool isFavorite(String soundId) => _favoriteSoundIds.contains(soundId);

  Future<void> toggleFavorite(String soundId) async {
    if (_favoriteSoundIds.contains(soundId)) {
      _favoriteSoundIds.remove(soundId);
    } else {
      _favoriteSoundIds.add(soundId);
      unawaited(AnalyticsService.instance.logSoundFavorited(soundId));
    }
    await _storage.saveUserData(_kFavoriteSoundIds, _favoriteSoundIds.toList());
    notifyListeners();
  }

  Future<void> addDownloadedSound(String soundId) async {
    final updated = List<String>.from(_user.downloadedSoundIds);
    if (!updated.contains(soundId)) {
      updated.add(soundId);
      _user = _user.copyWith(downloadedSoundIds: updated);
      await _storage.saveUserData(_kDownloadedSounds, updated);
      notifyListeners();
    }
  }

  Future<void> removeDownloadedSound(String soundId) async {
    final updated = List<String>.from(_user.downloadedSoundIds);
    updated.remove(soundId);
    _user = _user.copyWith(downloadedSoundIds: updated);
    await _storage.saveUserData(_kDownloadedSounds, updated);
    notifyListeners();
  }

  void addListeningMinutes(int minutes) {
    _user = _user.copyWith(
      totalListeningMinutes: _user.totalListeningMinutes + minutes,
      lastListenedDate: DateTime.now(),
    );
    _storage.saveUserData(_kTotalMinutes, _user.totalListeningMinutes);
    notifyListeners();
  }

  void completeFirstLaunch() {
    _user = _user.copyWith(isFirstLaunch: false);
    _storage.saveUserData(_kIsFirstLaunch, false);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final success = await _authService.login(email, password);
    if (!success) return false;

    _user = _user.copyWith(
      isLoggedIn: true,
      email: email,
      displayName: _authService.displayName ?? email.split('@').first,
    );
    notifyListeners();
    return true;
  }

  Future<bool> register(String email, String password, String displayName) async {
    final success = await _authService.register(email, password, displayName);
    if (!success) return false;

    _user = _user.copyWith(
      isLoggedIn: true,
      email: email,
      displayName: displayName,
    );
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = _user.copyWith(
      isLoggedIn: false,
      email: null,
      displayName: null,
    );
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    await _authService.deleteAccount();
    await _storage.clearUserData();
    await _storage.clearAllSessions();
    _isPremium = false;
    _rewardExpiresAt = null;
    _favoriteSoundIds = {};
    _user = User(
      id: const Uuid().v4(),
      isPremium: false,
      premiumExpiryDate: DateTime.now(),
      downloadedSoundIds: [],
      totalListeningMinutes: 0,
      lastListenedDate: DateTime.now(),
      isFirstLaunch: true,
      isLoggedIn: false,
      email: null,
      displayName: null,
    );
    notifyListeners();
  }

}
