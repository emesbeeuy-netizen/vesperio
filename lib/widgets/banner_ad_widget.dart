import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ads_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _banner;
  AdSize? _adSize;
  bool _loaded = false;
  bool _initiated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Guard so dependency re-notifications don't trigger duplicate loads.
    if (!_initiated) {
      _initiated = true;
      _initAd();
    }
  }

  Future<void> _initAd() async {
    if (kIsWeb) return;

    final width = MediaQuery.of(context).size.width.truncate();
    final adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);

    if (adSize == null || !mounted) return;
    _adSize = adSize;

    AdsService.instance.loadBanner(
      size: adSize,
      onLoaded: () {
        if (!mounted) return;
        setState(() {
          _banner = AdsService.instance.bannerAd;
          _loaded = true;
        });
      },
      onFailed: (err) {
        if (kDebugMode) debugPrint('Banner failed to load: $err');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || !_loaded || _banner == null || _adSize == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: double.infinity,
      height: _adSize!.height.toDouble(),
      child: AdWidget(ad: _banner!),
    );
  }
}
