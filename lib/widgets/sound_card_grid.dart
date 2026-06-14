import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/index.dart';
import '../providers/index.dart';
import 'premium_upsell_sheet.dart';

class SoundCardGrid extends StatelessWidget {
  final Sound sound;
  final VoidCallback? onTap;

  const SoundCardGrid({super.key, required this.sound, this.onTap});

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
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.lg - 1),
              child: Stack(
                fit: StackFit.expand,
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

                  // Large background icon (watermark)
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Icon(
                      meta.icon,
                      size: 80,
                      color: Colors.white.withAlpha(20),
                    ),
                  ),

                  // Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: premium badge or now-playing chip
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (sound.isPremium)
                              _Chip(
                                label: 'Premium',
                                color: AppColors.accent,
                              )
                            else
                              const SizedBox.shrink(),
                            if (isPlaying)
                              _Chip(
                                label: '▶ Playing',
                                color: AppColors.accent,
                              ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Bottom: icon + name + play/pause button
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(meta.icon, size: 28, color: Colors.white),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              sound.name,
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.textInverse,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  sound.category,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                                _PlayPauseButton(
                                  sound: sound,
                                  isPlaying: isPlaying,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(200),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.textInverse,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatefulWidget {
  final Sound sound;
  final bool isPlaying;
  const _PlayPauseButton({required this.sound, required this.isPlaying});

  @override
  State<_PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<_PlayPauseButton> {
  Timer? _previewTimer;
  bool _isPreviewing = false;

  @override
  void dispose() {
    _previewTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(_PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If audio stopped externally during preview, clean up our timer.
    if (!widget.isPlaying && _isPreviewing) {
      _previewTimer?.cancel();
      _previewTimer = null;
      _isPreviewing = false;
    }
  }

  Future<void> _startPreview() async {
    final audio = context.read<AudioPlayerProvider>(); // capture before await
    await audio.playSound(widget.sound);
    if (!mounted) return;
    audio.updateSoundVolume(widget.sound.id, 0.7);
    setState(() => _isPreviewing = true);
    _previewTimer = Timer(const Duration(seconds: 15), _onPreviewExpired);
  }

  void _onPreviewExpired() {
    if (!mounted) return;
    _previewTimer = null;
    setState(() => _isPreviewing = false);
    context.read<AudioPlayerProvider>().pause().then((_) {
      if (mounted) {
        PremiumUpsellSheet.show(context, source: UpsellSource.premiumSound);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isPlaying = widget.isPlaying;
    return GestureDetector(
      onTap: () async {
        final user = context.read<UserProvider>(); // before await
        final audio = context.read<AudioPlayerProvider>(); // before await
        if (widget.sound.isPremium && !user.isPremiumOrRewarded) {
          if (isPlaying || _isPreviewing) {
            _previewTimer?.cancel();
            _previewTimer = null;
            setState(() => _isPreviewing = false);
            await audio.pause();
          } else {
            await _startPreview();
          }
          return;
        }
        if (isPlaying) {
          await audio.pause();
        } else {
          await audio.playSound(widget.sound);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.accent : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(60),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          _isPreviewing
              ? Icons.timer
              : (isPlaying ? Icons.pause : Icons.play_arrow),
          size: 20,
          color: isPlaying
              ? AppColors.textInverse
              : SoundData.metaFor(widget.sound.id).colorA,
        ),
      ),
    );
  }
}
