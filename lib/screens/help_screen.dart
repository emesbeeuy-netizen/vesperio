import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../widgets/widgets.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.helpCenter),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Frequently Asked Questions',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      _FaqItem(
                        question: 'How do I set a sleep timer?',
                        answer: 'Open the timer tab, choose a duration, and press Start. You can also select fade-out behavior for a gentle stop.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FaqItem(
                        question: 'How do I unlock premium sounds?',
                        answer: 'Go to Settings or tap the Upgrade button on Home to access the premium purchase flow.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _FaqItem(
                        question: 'Can I use the app offline?',
                        answer: 'Most free sounds are available offline once downloaded. Premium downloads are coming soon.',
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Need more help?',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Email ${AppStrings.supportEmail} for support, feedback, or feature requests.',
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              question,
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              answer,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
