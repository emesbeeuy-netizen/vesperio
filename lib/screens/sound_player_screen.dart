import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../utils/extensions.dart';
import '../widgets/widgets.dart';

class SoundPlayerScreen extends StatefulWidget {
  final Sound sound;

  const SoundPlayerScreen({
    super.key,
    required this.sound,
  });

  @override
  State<SoundPlayerScreen> createState() => _SoundPlayerScreenState();
}

class _SoundPlayerScreenState extends State<SoundPlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showTimerDialog() async {
    final audioProvider = context.read<AudioPlayerProvider>();
    final options = [15, 30, 45, 60];

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set Sleep Timer',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ...options.map((minutes) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: ElevatedButton(
                      onPressed: () async {
                        await audioProvider.setTimer(minutes);
                        if (!mounted) return;
                        Navigator.of(this.context).pop();
                      },
                      child: Text('$minutes minutes'),
                    ),
                  )),
              if (audioProvider.timerActive)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: OutlinedButton(
                    onPressed: () async {
                      await audioProvider.clearTimer();
                      if (mounted) Navigator.pop(this.context);
                    },
                    child: const Text('Cancel timer'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Now Playing',
                      style: AppTypography.heading3,
                    ),
                    Selector<UserProvider, bool>(
                      selector: (_, p) => p.isFavorite(widget.sound.id),
                      builder: (context, isFav, _) => IconButton(
                        icon: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? AppColors.accent : null,
                        ),
                        onPressed: () =>
                            context.read<UserProvider>().toggleFavorite(widget.sound.id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Audio visualisation orb — colours & icon from SoundMeta
                Center(
                  child: _SoundOrb(
                    sound: widget.sound,
                    animationController: _animationController,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Sound name and category
                Text(
                  widget.sound.name,
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                    decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha((0.1 * 255).round()),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    widget.sound.category.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                const _PlayerProgress(),
                const SizedBox(height: AppSpacing.xxl),
                _VolumeControl(soundId: widget.sound.id),
                const SizedBox(height: AppSpacing.xxl),
                _PlaybackControls(sound: widget.sound),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: _TimerButton(onPressed: _showTimerDialog),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Selector<AudioPlayerProvider, bool>(
                        selector: (_, p) => p.screenOffMode,
                        builder: (context, screenOff, _) {
                          return OutlinedButton.icon(
                            onPressed: () {
                              context.read<AudioPlayerProvider>().toggleScreenOffMode();
                            },
                            style: screenOff
                                ? OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.accent,
                                    side: const BorderSide(
                                      color: AppColors.accent,
                                      width: 2,
                                    ),
                                  )
                                : null,
                            icon: Icon(
                              screenOff ? Icons.phone_locked : Icons.phone_android,
                            ),
                            label: Text(screenOff ? 'Screen On' : 'Screen Off'),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),

                // Description
                if (widget.sound.description.isNotEmpty)
                  ModernCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'About',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            widget.sound.description,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Per-sound animated orb
// ---------------------------------------------------------------------------

class _SoundOrb extends StatelessWidget {
  final Sound sound;
  final AnimationController animationController;

  const _SoundOrb({required this.sound, required this.animationController});

  @override
  Widget build(BuildContext context) {
    final meta = SoundData.metaFor(sound.id);
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, _) {
            final pulse = animationController.value;
            return Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: meta.colorB.withAlpha(((0.25 + pulse * 0.35) * 255).round()),
                    blurRadius: 20 + pulse * 35,
                    spreadRadius: 8 * pulse,
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      meta.colorA,
                      meta.colorB.withAlpha((0.85 * 255).round()),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    meta.icon,
                    size: 80,
                    color: AppColors.textInverse,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _PlaybackProgressState {
  final double progress;
  final Duration position;
  final Duration duration;

  const _PlaybackProgressState({
    required this.progress,
    required this.position,
    required this.duration,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is _PlaybackProgressState &&
            progress == other.progress &&
            position == other.position &&
            duration == other.duration;
  }

  @override
  int get hashCode => Object.hash(progress, position, duration);
}

class _PlayerProgress extends StatelessWidget {
  const _PlayerProgress();

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerProvider, _PlaybackProgressState>(
      selector: (_, provider) => _PlaybackProgressState(
        progress: provider.progress,
        position: provider.position,
        duration: provider.duration,
      ),
      builder: (context, state, _) {
        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
              ),
              child: Slider(
                value: state.progress,
                onChanged: (_) {},
                min: 0.0,
                max: 1.0,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  state.position.toFormattedString(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  state.duration.toFormattedString(),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _VolumeControl extends StatelessWidget {
  final String soundId;

  const _VolumeControl({required this.soundId});

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerProvider, double>(
      selector: (_, provider) {
        if (provider.currentSounds.isNotEmpty) {
          return provider.volumes.isNotEmpty ? provider.volumes[0] : 1.0;
        }
        return 1.0;
      },
      builder: (context, volume, _) {
        return Row(
          children: [
            const Icon(
              Icons.volume_down,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Slider(
                value: volume,
                onChanged: (value) async {
                  await context.read<AudioPlayerProvider>().updateSoundVolume(soundId, value);
                },
                min: 0.0,
                max: 1.0,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            const Icon(
              Icons.volume_up,
              color: AppColors.primary,
            ),
          ],
        );
      },
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  final Sound sound;

  const _PlaybackControls({required this.sound});

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerProvider, bool>(
      selector: (_, provider) {
        return provider.isPlaying &&
            provider.currentSounds.isNotEmpty &&
            provider.currentSounds.first.id == sound.id;
      },
      builder: (context, isPlayingCurrent, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outline,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {},
              ),
            ),
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.secondary,
                  ],
                ),
              ),
              child: IconButton(
                icon: Icon(
                  isPlayingCurrent ? Icons.pause : Icons.play_arrow,
                  size: 32,
                  color: AppColors.textInverse,
                ),
                onPressed: () async {
                  final audioProvider = context.read<AudioPlayerProvider>();
                  if (isPlayingCurrent) {
                    await audioProvider.pause();
                  } else {
                    await audioProvider.playSound(sound);
                  }
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.outline,
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {},
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimerButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _TimerButton({required this.onPressed});

  static String _formatRemaining(Duration remaining) {
    if (remaining.inHours > 0) {
      final h = remaining.inHours;
      final m = remaining.inMinutes.remainder(60);
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    if (remaining.inMinutes > 0) {
      final m = remaining.inMinutes;
      final s = remaining.inSeconds.remainder(60);
      return '${m}m ${s.toString().padLeft(2, '0')}s';
    }
    return '${remaining.inSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerProvider, (bool, Duration)>(
      selector: (_, p) => (p.timerActive, p.timerRemaining),
      builder: (context, data, _) {
        final timerActive = data.$1;
        final remaining = data.$2;
        final label = timerActive
            ? (remaining == Duration.zero ? 'Ending…' : _formatRemaining(remaining))
            : 'Sleep Timer';
        return OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.timer),
          label: Text(label),
        );
      },
    );
  }
}
