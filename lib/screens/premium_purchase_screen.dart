import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../providers/user_provider.dart';
import '../services/analytics_service.dart';
import '../services/purchase_service.dart';
import '../widgets/widgets.dart';

class PremiumPurchaseScreen extends StatefulWidget {
  const PremiumPurchaseScreen({super.key});

  @override
  State<PremiumPurchaseScreen> createState() => _PremiumPurchaseScreenState();
}

class _PremiumPurchaseScreenState extends State<PremiumPurchaseScreen> {
  PremiumPlan _selectedPlan = PremiumPlan.annual;
  bool _isPurchasing    = false;
  bool _isRestoring     = false;
  bool _isLoading       = true;
  bool _offeringsReady  = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (mounted) setState(() { _isLoading = true; _errorMessage = null; });
    await PurchaseService.instance.initialize();

    bool anyPlanReady() => PremiumPlan.values
        .any((p) => PurchaseService.instance.packageForPlan(p) != null);

    if (!anyPlanReady()) {
      await PurchaseService.instance.refreshOfferings();
    }
    if (!mounted) return;

    // If the default plan (annual) isn't available, switch to whichever plan is.
    if (PurchaseService.instance.packageForPlan(_selectedPlan) == null) {
      final fallback = PremiumPlan.values.cast<PremiumPlan?>().firstWhere(
        (p) => PurchaseService.instance.packageForPlan(p!) != null,
        orElse: () => null,
      );
      if (fallback != null) _selectedPlan = fallback;
    }

    final ready = PurchaseService.instance.packageForPlan(_selectedPlan) != null;
    setState(() {
      _isLoading = false;
      _offeringsReady = ready;
      if (!ready) {
        final rcError = PurchaseService.instance.offeringsError;
        _errorMessage = rcError ?? 'Could not load products. Check your connection and tap Retry.';
      }
    });
  }

  Future<void> _purchase() async {
    setState(() { _isPurchasing = true; _errorMessage = null; });
    unawaited(AnalyticsService.instance.logPlanSelected(_selectedPlan.label));

    try {
      final info = await PurchaseService.instance.purchasePlan(_selectedPlan);
      if (!mounted) return;

      if (info == null) {
        // User cancelled — no error, just stop the spinner.
        setState(() => _isPurchasing = false);
        return;
      }

      unawaited(AnalyticsService.instance.logPremiumPurchased(plan: _selectedPlan.label));
      // UserProvider's customerInfoStream listener updates isPremium automatically.
      Navigator.of(context).pop();
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = PurchasesErrorHelper.getErrorCode(e).name;
        _isPurchasing = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      setState(() {
        _errorMessage = msg;
        _isPurchasing = false;
        // If packages weren't ready, mark so button stays disabled until retry.
        if (msg.contains('still loading') || msg.contains('Products are')) {
          _offeringsReady = false;
        }
      });
    }
  }

  Future<void> _restore() async {
    setState(() { _isRestoring = true; _errorMessage = null; });
    try {
      final info = await PurchaseService.instance.restorePurchases();
      if (!mounted) return;
      final active = info.entitlements.active.containsKey('premium');
      if (active) {
        // UserProvider's stream listener will set isPremium; just close.
        Navigator.of(context).pop();
      } else {
        setState(() => _isRestoring = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No active subscription found for this account.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
        _isRestoring = false;
      });
    }
  }

  String _ctaLabel() {
    final trial = PurchaseService.instance.trialDescription(_selectedPlan);
    if (trial != null) return 'Start $trial';
    return 'Get Premium — ${PurchaseService.instance.priceForPlan(_selectedPlan)}';
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = context.select<UserProvider, bool>((p) => p.isPremium);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      bottom: -20,
                      child: Icon(
                        Icons.workspace_premium,
                        size: 180,
                        color: Colors.white.withAlpha(15),
                      ),
                    ),
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(height: 40),
                          Icon(Icons.workspace_premium, size: 48, color: Colors.white),
                          SizedBox(height: 8),
                          Text(
                            'Vesperio Premium',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Sleep better, every night',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isPremium) ...[
                    _AlreadyPremiumCard(),
                  ] else ...[
                    // Plan selector
                    Text(
                      'Choose your plan',
                      style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      _PlanSelector(
                        selected: _selectedPlan,
                        onChanged: (plan) => setState(() => _selectedPlan = plan),
                      ),
                    const SizedBox(height: AppSpacing.xl),

                    // Free trial / cancellation note
                    _TrialNote(plan: _selectedPlan),
                    const SizedBox(height: AppSpacing.xl),

                    // Purchase button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textInverse,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: (_isPurchasing || !_offeringsReady) ? null : _purchase,
                        child: _isPurchasing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textInverse,
                                ),
                              )
                            : Text(_offeringsReady ? _ctaLabel() : 'Loading…'),
                      ),
                    ),
                    _PostCtaSubtext(plan: _selectedPlan),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
                            ),
                          ),
                          TextButton(
                            onPressed: _isLoading ? null : _loadOfferings,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),

                    // Benefits
                    Text(
                      'Everything included',
                      style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _BenefitsList(),
                    const SizedBox(height: AppSpacing.xl),

                    // Restore
                    Center(
                      child: TextButton.icon(
                        onPressed: _isRestoring ? null : _restore,
                        icon: _isRestoring
                            ? const SizedBox(
                                height: 14,
                                width: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.restore, size: 18),
                        label: const Text('Restore previous purchase'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Required legal footer (Apple 3.1.2c)
                    const _LegalFooter(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Info banner below the plan selector. Shows trial copy for annual + trial,
/// or a generic "cancel anytime" note for other plans.
class _TrialNote extends StatelessWidget {
  final PremiumPlan plan;
  const _TrialNote({required this.plan});

  @override
  Widget build(BuildContext context) {
    final trial = PurchaseService.instance.trialDescription(plan);
    final text = trial != null
        ? '$trial included. Cancel anytime before the trial ends and you won\'t be charged.'
        : 'Cancel anytime. Manage your subscription in App Store / Play Store settings.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.accent.withAlpha(60)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.accent),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small print shown immediately below the purchase CTA button.
/// Displays the post-trial charge amount when a free trial applies.
class _PostCtaSubtext extends StatelessWidget {
  final PremiumPlan plan;
  const _PostCtaSubtext({required this.plan});

  @override
  Widget build(BuildContext context) {
    final trial = PurchaseService.instance.trialDescription(plan);
    if (trial == null) return const SizedBox.shrink();

    final fullPrice = PurchaseService.instance.priceForPlan(plan);
    final periodLabel = switch (plan) {
      PremiumPlan.annual  => 'yr',
      PremiumPlan.monthly => 'mo',
      PremiumPlan.weekly  => 'wk',
    };

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Center(
        child: Text(
          'Then $fullPrice/$periodLabel after trial · Cancel anytime',
          style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PlanSelector extends StatelessWidget {
  final PremiumPlan selected;
  final ValueChanged<PremiumPlan> onChanged;

  const _PlanSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const displayOrder = [PremiumPlan.annual, PremiumPlan.monthly, PremiumPlan.weekly];
    return Column(
      children: displayOrder.map((plan) {
        return _PlanCard(
          plan: plan,
          isSelected: selected == plan,
          onTap: () => onChanged(plan),
        );
      }).toList(),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final PremiumPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final price = PurchaseService.instance.priceForPlan(plan);
    final isAnnual = plan == PremiumPlan.annual;

    // Compute monthly equivalent for annual to show savings.
    String? savingsLabel;
    if (isAnnual) {
      final monthly = PurchaseService.instance.priceForPlan(PremiumPlan.monthly);
      final annualNum = double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), ''));
      final monthlyNum = double.tryParse(monthly.replaceAll(RegExp(r'[^\d.]'), ''));
      if (annualNum != null && monthlyNum != null && monthlyNum > 0) {
        final savings = ((1 - (annualNum / 12) / monthlyNum) * 100).round();
        savingsLabel = 'Save $savings%';
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(40)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.outline,
                  width: 2,
                ),
                color: isSelected ? AppColors.accent : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),

            // Plan label
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        _planLabel(plan),
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (isAnnual) ...[
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
                    ],
                  ),
                  if (isAnnual) Builder(builder: (context) {
                    final trial = PurchaseService.instance.trialDescription(plan)
                        ?? '7-day free trial';
                    return Text(
                      '$trial included',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accent,
                      ),
                    );
                  }),
                ],
              ),
            ),

            // Price + savings
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Billed amount is always the primary/largest element (Apple 3.1.2c).
                Text(
                  _billedLabel(plan, price),
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected ? AppColors.accent : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Monthly equivalent shown subordinate (smaller, muted) for annual.
                if (isAnnual)
                  Text(
                    _monthlyEquivalent(price),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                if (savingsLabel != null)
                  Text(
                    savingsLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _planLabel(PremiumPlan plan) {
    switch (plan) {
      case PremiumPlan.weekly:  return 'Weekly';
      case PremiumPlan.monthly: return 'Monthly';
      case PremiumPlan.annual:  return 'Annual';
    }
  }

  // Actual billed amount — always the primary price element (Apple 3.1.2c).
  String _billedLabel(PremiumPlan plan, String price) {
    switch (plan) {
      case PremiumPlan.weekly:  return '$price / wk';
      case PremiumPlan.monthly: return '$price / mo';
      case PremiumPlan.annual:  return '$price / yr';
    }
  }

  // Monthly equivalent for annual — shown subordinate to the billed amount.
  String _monthlyEquivalent(String annualPrice) {
    final num = double.tryParse(annualPrice.replaceAll(RegExp(r'[^\d.]'), ''));
    if (num == null) return '';
    return '\$${(num / 12).toStringAsFixed(2)} / mo';
  }
}

class _BenefitsList extends StatelessWidget {
  const _BenefitsList();

  static const List<(IconData, String, String)> _benefits = [
    (Icons.music_note,       '9 Premium HD Sounds',         'Thunderstorm, train, waterfall, meditation bells & more'),
    (Icons.tune,             'Sound Mixer + Saved Presets',  'Layer up to 4 sounds and name your own sleep mix'),
    (Icons.block,            'Ad-Free Experience',           'No banners, no interruptions — ever'),
    (Icons.download_rounded, 'Offline Listening',            'Download your favourite sounds for when you have no signal'),
    (Icons.timer,            'Unlimited Sleep Timer',         'Set hours, not just minutes. With gradual fade-out'),
    (Icons.nightlight_round, 'Smart Alarm',                  'Wake during light sleep for a gentler morning'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _benefits.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(b.$1, size: 18, color: AppColors.accent),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b.$2,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      b.$3,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Required by Apple guideline 3.1.2(c): functional links to Privacy Policy
/// and Terms of Use must appear inside the subscription purchase flow.
class _LegalFooter extends StatelessWidget {
  const _LegalFooter();

  Future<void> _launch(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the page. Please try again later.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 11,
      height: 1.5,
      color: Color(0xFF9F94C3), // AppColors.textTertiary
    );
    const linkStyle = TextStyle(
      fontFamily: 'Poppins',
      fontSize: 11,
      height: 1.5,
      color: Color(0xFF22D0A7), // AppColors.accent
      decoration: TextDecoration.underline,
      decorationColor: Color(0xFF22D0A7),
    );

    return Column(
      children: [
        const Divider(color: Color(0xFF453C75), height: 1),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Vesperio Premium is an auto-renewable subscription. Your subscription will automatically renew unless cancelled at least 24 hours before the end of the current period. You can manage or cancel your subscription in your App Store account settings.',
          style: style,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _launch(context, AppStrings.privacyPolicyUrl),
              child: const Text(AppStrings.privacyPolicy, style: linkStyle),
            ),
            const Text('  ·  ', style: style),
            GestureDetector(
              onTap: () => _launch(context, AppStrings.termsOfServiceUrl),
              child: const Text(AppStrings.termsOfService, style: linkStyle),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _AlreadyPremiumCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(Icons.verified, size: 64, color: AppColors.accent),
            const SizedBox(height: AppSpacing.md),
            Text(
              'You\'re Premium!',
              style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'All premium features are unlocked and active.',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Back to app'),
            ),
          ],
        ),
      ),
    );
  }
}
