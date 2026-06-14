import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../services/analytics_service.dart';
import '../services/purchase_service.dart';

/// Context labels used to attribute which surface triggered the paywall.
class UpsellSource {
  static const String premiumSound = 'premium_sound';
  static const String mixerLimit   = 'mixer_limit';
  static const String timerLimit   = 'timer_limit';
  static const String adDailyLimit = 'ad_daily_limit';
  static const String homeBanner   = 'home_banner';
}

/// Reusable paywall bottom sheet.
///
/// Returns `true` when the user taps either CTA (try trial or see all plans),
/// and `false`/null when dismissed via "Maybe later" or swipe-down.
/// The caller is responsible for navigating to [PremiumPurchaseScreen].
///
/// ```dart
/// final goToPurchase = await PremiumUpsellSheet.show(
///   context, source: UpsellSource.premiumSound,
/// );
/// if (goToPurchase == true && context.mounted) {
///   Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()));
/// }
/// ```
class PremiumUpsellSheet extends StatelessWidget {
  final String source;
  final String headline;
  final String subtext;

  const PremiumUpsellSheet._({
    required this.source,
    required this.headline,
    required this.subtext,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String source,
    String? headline,
    String? subtext,
  }) {
    unawaited(AnalyticsService.instance.logPaywallShown(source));
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => PremiumUpsellSheet._(
        source: source,
        headline: headline ?? _defaultHeadline(source),
        subtext:  subtext  ?? _defaultSubtext(source),
      ),
    ).then((result) {
      if (result != true) {
        unawaited(AnalyticsService.instance.logPaywallDismissed(source));
      }
      return result;
    });
  }

  static String _defaultHeadline(String source) {
    switch (source) {
      case UpsellSource.premiumSound:  return 'This is a Premium Sound';
      case UpsellSource.mixerLimit:    return 'Mixer Limit Reached';
      case UpsellSource.timerLimit:    return 'Unlock Unlimited Timer';
      case UpsellSource.adDailyLimit:  return 'Skip the Ads Forever';
      default:                         return 'Upgrade to Vesperio Premium';
    }
  }

  static String _defaultSubtext(String source) {
    switch (source) {
      case UpsellSource.premiumSound:
        return 'Try premium free for 7 days and unlock all 9 HD sounds.';
      case UpsellSource.mixerLimit:
        return 'Premium removes the 4-sound limit and saves your custom mixes.';
      case UpsellSource.timerLimit:
        return 'Free tier caps at 60 minutes. Premium sets any duration you want.';
      case UpsellSource.adDailyLimit:
        return "You've used today's reward. Go ad-free permanently with Premium.";
      default:
        return 'Get the full Vesperio experience with a 7-day free trial.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final annualPrice  = PurchaseService.instance.priceForPlan(PremiumPlan.annual);
    final monthlyPrice = PurchaseService.instance.priceForPlan(PremiumPlan.monthly);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),

            // Icon + headline
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    headline,
                    style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              subtext,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Benefit list
            ..._kBenefits.map((b) => _BenefitRow(icon: b.$1, text: b.$2)),
            const SizedBox(height: AppSpacing.xl),

            // Annual price card
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.accent.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Annual plan',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              child: Text(
                                'BEST VALUE',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '7-day free trial included',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$annualPrice/yr',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${_monthlyEquivalent(annualPrice)}/mo',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Primary CTA — try free trial
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: AppColors.textInverse,
                ),
                onPressed: () {
                  unawaited(AnalyticsService.instance.logFreeTrialStarted(plan: 'annual'));
                  Navigator.of(context).pop(true);
                },
                child: const Text('Start 7-day free trial'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Secondary CTAs
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'See all plans · $monthlyPrice/mo',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Maybe later',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _monthlyEquivalent(String annualPrice) {
    final numeric = double.tryParse(annualPrice.replaceAll(RegExp(r'[^\d.]'), ''));
    if (numeric != null) return '\$${(numeric / 12).toStringAsFixed(2)}';
    return '\$2.49';
  }

  static const List<(IconData, String)> _kBenefits = [
    (Icons.music_note,        '9 premium HD sounds'),
    (Icons.tune,              'Sound mixer with saved custom presets'),
    (Icons.block,             'Ad-free experience'),
    (Icons.download_rounded,  'Offline listening'),
    (Icons.timer,             'Unlimited sleep timer'),
    (Icons.nightlight_round,  'Smart alarm with sleep cycle detection'),
  ];
}

class _BenefitRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _BenefitRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
