import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class SleepQualitySheet extends StatefulWidget {
  const SleepQualitySheet({super.key});

  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
      ),
      builder: (_) => const SleepQualitySheet(),
    );
  }

  @override
  State<SleepQualitySheet> createState() => _SleepQualitySheetState();
}

class _SleepQualitySheetState extends State<SleepQualitySheet> {
  int? _selected;

  static const _options = [
    (1, '😴', 'Poor'),
    (2, '😐', 'Fair'),
    (3, '😊', 'Good'),
    (4, '🌟', 'Amazing'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.outline,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const Icon(Icons.nightlight_round, size: 48, color: AppColors.accent),
            const SizedBox(height: AppSpacing.md),
            Text(
              'How did you sleep?',
              style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Your rating helps personalize your experience.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _options.map((opt) {
                final (value, emoji, label) = opt;
                final isSelected = _selected == value;
                return GestureDetector(
                  onTap: () => setState(() => _selected = value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withAlpha(40)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected ? AppColors.accent : AppColors.outline,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          label,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                child: const Text('Save rating'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(
                'Skip',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
