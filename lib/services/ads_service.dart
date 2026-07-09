import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../constants/app_constants.dart';

/// Simple AdsService singleton to initialize Google Mobile Ads,
/// load a banner and a rewarded ad, and expose helpers for the UI.
class AdsService {
  AdsService._internal();
  static final AdsService instance = AdsService._internal();
  static const AdRequest _defaultAdRequest = AdRequest();

  bool _initialized = false;
  Future<void>? _initFuture;
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  bool _bannerLoaded = false;
  Future<void>? _bannerLoadFuture;
  Future<void>? _rewardedLoadFuture;
  Timer? _rewardedLoadTimer;
  Timer? _rewardedShowTimer;

  Future<void> init() async {
    if (_initialized) return;
    // Prevent concurrent calls from each entering the consent/SDK-init flow.
    if (_initFuture != null) {
      await _initFuture;
      return;
    }
    final completer = Completer<void>();
    _initFuture = completer.future;
    try {
      if (!kIsWeb) {
        await _gatherConsent();
        await MobileAds.instance.initialize();
      }
      _initialized = true;
    } finally {
      completer.complete();
      _initFuture = null;
    }
  }

  /// Requests GDPR/CCPA consent via the UMP SDK before the ad SDK initialises.
  /// Always completes — failures are non-fatal so ads still serve where allowed.
  /// Hard timeout of 8 s prevents a stalled consent form from blocking ad load.
  Future<void> _gatherConsent() async {
    final completer = Completer<void>();

    void done() {
      if (!completer.isCompleted) completer.complete();
    }

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        final available =
            await ConsentInformation.instance.isConsentFormAvailable();
        if (available) {
          ConsentForm.loadConsentForm(
            (form) => form.show((_) => done()),
            (_) => done(),
          );
        } else {
          done();
        }
      },
      (_) => done(),
    );

    return completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () {},
    );
  }

  /// Test Ad unit IDs from Google. Replace with real IDs for production.
  String get _bannerAdUnitId {
    if (kIsWeb) return '<WEB_AD_UNIT_ID>'; // AdMob for web is not supported
    if (Platform.isAndroid) {
      return AdMobIds.useTestIds
          ? AdMobIds.testBannerAndroid
          : (AdMobIds.prodBannerAndroid.isNotEmpty ? AdMobIds.prodBannerAndroid : AdMobIds.testBannerAndroid);
    }
    if (Platform.isIOS) {
      return AdMobIds.useTestIds
          ? AdMobIds.testBannerIOS
          : (AdMobIds.prodBannerIOS.isNotEmpty ? AdMobIds.prodBannerIOS : AdMobIds.testBannerIOS);
    }
    return AdMobIds.testBannerAndroid;
  }

  String get _rewardedAdUnitId {
    if (kIsWeb) return '<WEB_REWARDED_ID>';
    if (Platform.isAndroid) {
      return AdMobIds.useTestIds
          ? AdMobIds.testRewardedAndroid
          : (AdMobIds.prodRewardedAndroid.isNotEmpty ? AdMobIds.prodRewardedAndroid : AdMobIds.testRewardedAndroid);
    }
    if (Platform.isIOS) {
      return AdMobIds.useTestIds
          ? AdMobIds.testRewardedIOS
          : (AdMobIds.prodRewardedIOS.isNotEmpty ? AdMobIds.prodRewardedIOS : AdMobIds.testRewardedIOS);
    }
    return AdMobIds.testRewardedAndroid;
  }

  Future<void> loadBanner({AdSize size = AdSize.banner, void Function()? onLoaded, void Function(LoadAdError)? onFailed}) async {
    if (kIsWeb) {
      _bannerAd = null;
      _bannerLoaded = false;
      onFailed?.call(LoadAdError(0, 'ads', 'Ads not supported on web', null));
      return;
    }

    await init();

    if (_bannerAd != null && _bannerLoaded) {
      onLoaded?.call();
      return;
    }

    if (_bannerLoadFuture != null) {
      try {
        await _bannerLoadFuture;
        if (_bannerAd != null && _bannerLoaded) {
          onLoaded?.call();
        }
      } catch (_) {
        // Load already failed or is being retried.
      }
      return;
    }

    _bannerAd?.dispose();
    _bannerLoaded = false;
    final completer = Completer<void>();
    _bannerLoadFuture = completer.future;

    _bannerAd = BannerAd(
      size: size,
      adUnitId: _bannerAdUnitId,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerLoaded = true;
          onLoaded?.call();
          if (!completer.isCompleted) {
            completer.complete();
          }
          _bannerLoadFuture = null;
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
          _bannerAd = null;
          _bannerLoaded = false;
          onFailed?.call(err);
          if (!completer.isCompleted) {
            completer.completeError(err);
          }
          _bannerLoadFuture = null;
          if (!kDebugMode) {
            FirebaseCrashlytics.instance.recordError(
              'Banner ad failed: code=${err.code} domain=${err.domain} message=${err.message}',
              null, reason: 'AdMob banner load failed', fatal: false,
            );
          }
        },
      ),
      request: _defaultAdRequest,
    )..load();

    await _bannerLoadFuture;
  }

  bool get hasBanner => _bannerAd != null && _bannerLoaded;

  BannerAd? get bannerAd => _bannerAd;

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  Future<void> loadRewarded({void Function()? onLoaded, void Function(LoadAdError)? onFailed}) async {
    if (kIsWeb) {
      _rewardedAd = null;
      onFailed?.call(LoadAdError(0, 'ads', 'Ads not supported on web', null));
      return;
    }

    await init();

    if (_rewardedAd != null) {
      onLoaded?.call();
      return;
    }

    if (_rewardedLoadFuture != null) {
      try {
        await _rewardedLoadFuture;
        if (_rewardedAd != null) {
          onLoaded?.call();
        } else {
          onFailed?.call(LoadAdError(0, 'ads', 'Ad unavailable', null));
        }
      } catch (e) {
        // Propagate the load error so the caller can reset its loading state.
        onFailed?.call(
          e is LoadAdError ? e : LoadAdError(0, 'ads', e.toString(), null),
        );
      }
      return;
    }

    final completer = Completer<void>();
    _rewardedLoadFuture = completer.future;

    // Safety net: if the GMA SDK never fires either callback (e.g. on newer
    // OS versions), we fail gracefully rather than hanging indefinitely.
    _rewardedLoadTimer?.cancel();
    _rewardedLoadTimer = Timer(const Duration(seconds: 30), () {
      if (!completer.isCompleted) {
        _rewardedAd = null;
        _rewardedLoadFuture = null;
        final err = LoadAdError(0, 'ads', 'Rewarded ad load timed out', null);
        onFailed?.call(err);
        completer.completeError(err);
      }
    });

    await RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: _defaultAdRequest,
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedLoadTimer?.cancel();
          _rewardedAd = ad;
          onLoaded?.call();
          if (!completer.isCompleted) {
            completer.complete();
          }
          _rewardedLoadFuture = null;
        },
        onAdFailedToLoad: (err) {
          _rewardedLoadTimer?.cancel();
          _rewardedAd = null;
          onFailed?.call(err);
          if (!completer.isCompleted) {
            completer.completeError(err);
          }
          _rewardedLoadFuture = null;
          if (!kDebugMode) {
            FirebaseCrashlytics.instance.recordError(
              'Rewarded ad failed: code=${err.code} domain=${err.domain} message=${err.message}',
              null, reason: 'AdMob rewarded load failed', fatal: false,
            );
          }
        },
      ),
    );

    try {
      await _rewardedLoadFuture;
    } catch (_) {
      // Error already surfaced via onFailed.
    }
  }

  bool get hasRewarded => _rewardedAd != null;

  void showRewarded({required void Function(RewardItem) onEarned, void Function()? onClosed}) {
    final ad = _rewardedAd;
    if (ad == null) {
      // No ad available — unblock the caller immediately so the UI never hangs.
      onClosed?.call();
      return;
    }

    // Safety net: on iPad (iPadOS 26+) the GMA SDK can silently fail to present
    // a full-screen ad without firing any FullScreenContentCallback. The timer
    // only covers the "did it appear?" window — it is cancelled as soon as
    // onAdShowedFullScreenContent fires so it never interferes with a legitimately
    // playing ad.
    _rewardedShowTimer?.cancel();
    _rewardedShowTimer = Timer(const Duration(seconds: 8), () {
      ad.dispose();
      _rewardedAd = null;
      onClosed?.call();
      loadRewarded();
    });

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        // Ad is confirmed on screen — cancel the "failed to appear" timer.
        _rewardedShowTimer?.cancel();
      },
      onAdDismissedFullScreenContent: (ad) {
        _rewardedShowTimer?.cancel();
        // Guard against double-dispose if the safety timer already ran.
        if (_rewardedAd == null) return;
        ad.dispose();
        _rewardedAd = null;
        onClosed?.call();
        loadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        _rewardedShowTimer?.cancel();
        // Guard against double-dispose if the safety timer already ran.
        if (_rewardedAd == null) return;
        ad.dispose();
        _rewardedAd = null;
        onClosed?.call();
        loadRewarded();
      },
    );
    try {
      ad.show(onUserEarnedReward: (adWithoutView, reward) => onEarned(reward));
    } catch (_) {
      _rewardedShowTimer?.cancel();
      ad.dispose();
      _rewardedAd = null;
      onClosed?.call();
    }
  }

  void dispose() {
    _rewardedLoadTimer?.cancel();
    _rewardedShowTimer?.cancel();
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
  }
}
