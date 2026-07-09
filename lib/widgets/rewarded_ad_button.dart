import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/audio_player_provider.dart';
import '../providers/user_provider.dart';
import '../screens/premium_purchase_screen.dart';
import '../services/ads_service.dart';
import '../services/preferences_service.dart';
import 'premium_upsell_sheet.dart';

/// Button that shows a rewarded ad and grants the user 2 hours of temporary
/// premium access (+ sets a 2-hour sleep timer). Enforces a 24-hour daily limit.
class RewardedAdButton extends StatefulWidget {
  final String label;
  final String loadingLabel;

  const RewardedAdButton({
    super.key,
    this.label = 'Watch Ad',
    this.loadingLabel = 'Loading…',
  });

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _isLoading = false;
  bool _isAdReady = false;
  bool _canClaim = true;
  bool _isShowing = false;
  Timer? _showSafetyTimer;

  static const _rewardDuration = Duration(hours: 2);
  static const _rewardMinutes = 120;

  @override
  void initState() {
    super.initState();
    _canClaim = PreferencesService().canClaimDailyReward();
    _loadRewardedAd();
  }

  @override
  void dispose() {
    _showSafetyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRewardedAd() async {
    if (kIsWeb) {
      if (mounted) setState(() { _isLoading = false; _isAdReady = false; });
      return;
    }

    if (AdsService.instance.hasRewarded) {
      if (mounted) setState(() { _isLoading = false; _isAdReady = true; });
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    await AdsService.instance.init();
    await AdsService.instance.loadRewarded(
      onLoaded: () {
        if (!mounted) return;
        setState(() { _isLoading = false; _isAdReady = true; });
      },
      onFailed: (error) {
        if (!mounted) return;
        setState(() { _isLoading = false; _isAdReady = false; });
        if (kDebugMode) debugPrint('Rewarded ad failed to load: $error');
      },
    );
  }

  Future<void> _handleTap() async {
    if (!_canClaim) {
      final goToPurchase = await PremiumUpsellSheet.show(
        context, source: UpsellSource.adDailyLimit,
      );
      if (goToPurchase == true && mounted) {
        unawaited(Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()),
        ));
      }
      return;
    }

    if (!_isAdReady) {
      await _loadRewardedAd();
      if (!_isAdReady && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ad not ready yet, please try again shortly.')),
        );
      }
      return;
    }

    setState(() => _isShowing = true);

    // Widget-level safety net: if the AdsService timeout fires but the onClosed
    // callback is delayed (e.g. due to isolate scheduling), this ensures _isShowing
    // is always reset and the button never stays permanently disabled.
    _showSafetyTimer?.cancel();
    _showSafetyTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      setState(() { _isAdReady = false; _isShowing = false; });
      _loadRewardedAd();
    });

    AdsService.instance.showRewarded(
      onEarned: (RewardItem reward) async {
        if (!mounted) return;

        // Record claim time for daily limit.
        await PreferencesService().setLastRewardDate(DateTime.now());
        if (mounted) setState(() => _canClaim = false);

        // Grant temporary premium access.
        if (!mounted) return;
        await context.read<UserProvider>().grantTemporaryReward(_rewardDuration);

        // Set/extend the sleep timer by the reward duration.
        if (!mounted) return;
        final audio = context.read<AudioPlayerProvider>();
        final extraMinutes = audio.timerActive
            ? (audio.timerMinutes ?? 0) + _rewardMinutes
            : _rewardMinutes;
        await audio.setTimer(extraMinutes);

        if (!mounted) return;
        _showRewardDialog();
      },
      onClosed: () async {
        _showSafetyTimer?.cancel();
        if (!mounted) return;
        setState(() { _isAdReady = false; _isShowing = false; });
        await _loadRewardedAd();
      },
    );
  }

  void _showRewardDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Row(
          children: [
            const Icon(Icons.star, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Reward Unlocked!',
              style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You\'ve earned 2 hours of premium features:',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            _RewardBullet(icon: Icons.block, text: 'Ad-free listening for 2 hours'),
            _RewardBullet(icon: Icons.music_note, text: 'Access to premium sounds'),
            _RewardBullet(icon: Icons.timer, text: 'Sleep timer set to 2 hours'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return OutlinedButton(
        onPressed: null,
        child: const Text('Ads unavailable on web'),
      );
    }

    if (!_canClaim) {
      return OutlinedButton.icon(
        onPressed: () async {
          final goToPurchase = await PremiumUpsellSheet.show(
            context, source: UpsellSource.adDailyLimit,
          );
          if (goToPurchase == true && context.mounted) {
            unawaited(Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()),
            ));
          }
        },
        icon: const Icon(Icons.workspace_premium),
        label: const Text('Go Premium — skip ads forever'),
      );
    }

    return OutlinedButton.icon(
      onPressed: (_isLoading || _isShowing) ? null : _handleTap,
      icon: (_isLoading || _isShowing)
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_circle_outline),
      label: Text(
        _isShowing ? 'Opening…' : _isLoading ? widget.loadingLabel : widget.label,
      ),
    );
  }
}

class _RewardBullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _RewardBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
