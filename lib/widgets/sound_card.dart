import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../screens/premium_purchase_screen.dart';

/// Horizontal card used in the "Recently Played" row on the Home tab.
class SoundCard extends StatelessWidget {
  final Sound sound;
  final VoidCallback? onTap;

  const SoundCard({super.key, required this.sound, this.onTap});

  @override
  Widget build(BuildContext context) {
    final meta = SoundData.metaFor(sound.id);

    return Selector<AudioPlayerProvider, bool>(
      selector: (_, p) => p.currentSoundIds.contains(sound.id) && p.isPlaying,
      builder: (context, isPlaying, _) {
        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: AppDimensions.soundCardWidth,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: isPlaying ? AppColors.accent : AppColors.outline,
                width: isPlaying ? 2 : 1,
              ),
              boxShadow: isPlaying
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(60),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg - 1),
              child: Stack(
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: meta.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                  // Watermark icon
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Icon(
                      meta.icon,
                      size: 64,
                      color: Colors.white.withAlpha(20),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sound icon
                        Icon(meta.icon, size: 24, color: Colors.white),
                        const Spacer(),

                        // Name
                        Text(
                          sound.name,
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textInverse,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: AppSpacing.xs),

                        // Bottom row: category + play button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                sound.isPremium ? 'Pro' : sound.category,
                                style: AppTypography.bodySmall.copyWith(
                                  color: Colors.white70,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            GestureDetector(
                              onTap: () async {
                                final user = context.read<UserProvider>();
                                if (sound.isPremium && !user.isPremiumOrRewarded) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const PremiumPurchaseScreen(),
                                    ),
                                  );
                                  return;
                                }
                                final audio = context.read<AudioPlayerProvider>();
                                if (isPlaying) {
                                  await audio.pause();
                                } else {
                                  await audio.playSound(sound);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isPlaying ? AppColors.accent : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(50),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 16,
                                  color: isPlaying
                                      ? AppColors.textInverse
                                      : meta.colorA,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // "Playing" badge (top-right)
                  if (isPlaying)
                    Positioned(
                      top: AppSpacing.sm,
                      right: AppSpacing.sm,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Text(
                          '▶',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textInverse,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
