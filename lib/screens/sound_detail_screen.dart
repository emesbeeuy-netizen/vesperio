import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../widgets/widgets.dart';
import 'premium_purchase_screen.dart';

class SoundDetailScreen extends StatelessWidget {
  final Sound sound;

  const SoundDetailScreen({super.key, required this.sound});

  @override
  Widget build(BuildContext context) {
    final meta = SoundData.metaFor(sound.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(sound.name),
        backgroundColor: meta.colorA,
        elevation: 0,
        foregroundColor: AppColors.textInverse,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner with per-sound gradient + icon
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: meta.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Watermark
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Icon(
                      meta.icon,
                      size: 160,
                      color: Colors.white.withAlpha(18),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meta.icon, size: 72, color: Colors.white),
                        const SizedBox(height: AppSpacing.md),
                        if (sound.isPremium)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              AppStrings.premium,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textInverse,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category chip
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: meta.colorA.withAlpha(60),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                            border: Border.all(color: meta.colorB.withAlpha(100)),
                          ),
                          child: Text(
                            sound.category[0].toUpperCase() +
                                sound.category.substring(1),
                            style: AppTypography.labelSmall.copyWith(
                              color: meta.colorB,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    ModernCard(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sound.description,
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'About this sound',
                              style: AppTypography.heading3.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'This sound is part of the Vesperio collection. '
                              'Use the play button below to listen, or add it to '
                              'your mixer to layer it with other sounds.',
                              style: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Now-playing indicator
                    Selector<AudioPlayerProvider, bool>(
                      selector: (_, p) =>
                          p.currentSoundIds.contains(sound.id) && p.isPlaying,
                      builder: (context, isPlaying, _) {
                        if (!isPlaying) return const SizedBox.shrink();
                        return ModernCard(
                          child: ListTile(
                            leading: Icon(Icons.equalizer, color: AppColors.accent),
                            title: Text(
                              'Now Playing',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.accent,
                              ),
                            ),
                            subtitle: Text(
                              '${sound.name} is currently playing',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final userProvider = context.read<UserProvider>();
                        if (sound.isPremium && !userProvider.isPremiumOrRewarded) {
                          final goToPurchase = await PremiumUpsellSheet.show(
                            context, source: UpsellSource.premiumSound,
                          );
                          if (goToPurchase == true && context.mounted) {
                            unawaited(Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()),
                            ));
                          }
                          return;
                        }
                        await context.read<AudioPlayerProvider>().addSound(sound);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${sound.name} added to mixer.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Add to mixer'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Selector<AudioPlayerProvider, bool>(
                      selector: (_, p) =>
                          p.currentSoundIds.contains(sound.id) && p.isPlaying,
                      builder: (context, isPlaying, _) {
                        return ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: meta.colorA,
                            foregroundColor: AppColors.textInverse,
                          ),
                          onPressed: () async {
                            final userProvider = context.read<UserProvider>();
                            if (sound.isPremium &&
                                !userProvider.isPremiumOrRewarded) {
                              final goToPurchase = await PremiumUpsellSheet.show(
                                context, source: UpsellSource.premiumSound,
                              );
                              if (goToPurchase == true && context.mounted) {
                                unawaited(Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()),
                                ));
                              }
                              return;
                            }
                            final audio = context.read<AudioPlayerProvider>();
                            if (isPlaying) {
                              await audio.pause();
                            } else {
                              await audio.playSound(sound);
                            }
                          },
                          icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                          label: Text(isPlaying ? 'Pause' : 'Play now'),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
