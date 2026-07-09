import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/index.dart';
import '../providers/index.dart';
import 'sound_detail_screen.dart';

enum _FocusPhase { work, shortBreak, longBreak }

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key});

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  static const _workSec = 25 * 60;
  static const _shortBreakSec = 5 * 60;
  static const _longBreakSec = 15 * 60;
  static const _pomodorosPerCycle = 4;

  // Focus-recommended sounds (subset of the library).
  static const _focusSoundIds = [
    'brown_noise',
    'white_noise',
    'rain',
    'forest',
    'coffee_shop',
    'pink_noise',
  ];

  _FocusPhase _phase = _FocusPhase.work;
  int _secondsRemaining = _workSec;
  bool _isRunning = false;
  int _completedPomodoros = 0;
  Timer? _ticker;

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _toggleRunning() {
    if (_isRunning) {
      _ticker?.cancel();
      setState(() => _isRunning = false);
    } else {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_secondsRemaining > 0) {
          setState(() => _secondsRemaining--);
        } else {
          _ticker?.cancel();
          setState(() => _isRunning = false);
          _advancePhase();
        }
      });
      setState(() => _isRunning = true);
    }
  }

  void _advancePhase() {
    setState(() {
      if (_phase == _FocusPhase.work) {
        _completedPomodoros++;
        if (_completedPomodoros % _pomodorosPerCycle == 0) {
          _phase = _FocusPhase.longBreak;
          _secondsRemaining = _longBreakSec;
        } else {
          _phase = _FocusPhase.shortBreak;
          _secondsRemaining = _shortBreakSec;
        }
      } else {
        _phase = _FocusPhase.work;
        _secondsRemaining = _workSec;
      }
    });
  }

  void _skipPhase() {
    _ticker?.cancel();
    setState(() => _isRunning = false);
    _advancePhase();
  }

  void _reset() {
    _ticker?.cancel();
    setState(() {
      _isRunning = false;
      _phase = _FocusPhase.work;
      _secondsRemaining = _workSec;
      _completedPomodoros = 0;
    });
  }

  String get _formattedTime {
    final m = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _phaseLabel {
    switch (_phase) {
      case _FocusPhase.work: return 'Work Session';
      case _FocusPhase.shortBreak: return 'Short Break';
      case _FocusPhase.longBreak: return 'Long Break';
    }
  }

  Color get _phaseColor {
    switch (_phase) {
      case _FocusPhase.work: return AppColors.accent;
      case _FocusPhase.shortBreak: return AppColors.primaryLight;
      case _FocusPhase.longBreak: return AppColors.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inCycle = _completedPomodoros % _pomodorosPerCycle;
    final isLongBreakEarned = _completedPomodoros > 0 && inCycle == 0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Focus Mode',
                  style: AppTypography.heading1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                  onPressed: _reset,
                  tooltip: 'Reset all',
                ),
              ],
            ),
            Text(
              'Deep work with ambient sound.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Timer card ──────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.xxl,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _phaseColor.withAlpha((0.18 * 255).round()),
                    AppColors.surfaceVariant,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: _phaseColor.withAlpha(80)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: _phaseColor.withAlpha(40),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      _phaseLabel,
                      style: AppTypography.labelMedium.copyWith(
                        color: _phaseColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 72,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -2,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleRunning,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _phaseColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, AppDimensions.buttonHeight),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
                        label: Text(_isRunning ? 'Pause' : 'Start'),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _skipPhase,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, AppDimensions.buttonHeight),
                        ),
                        icon: const Icon(Icons.skip_next),
                        label: const Text('Skip'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // ── Pomodoro progress ───────────────────────────────────────
            _PomodoroProgress(
              inCurrentCycle: inCycle,
              totalCompleted: _completedPomodoros,
              perCycle: _pomodorosPerCycle,
              isLongBreakEarned: isLongBreakEarned,
            ),
            const SizedBox(height: AppSpacing.xxl),

            // ── Focus sounds ────────────────────────────────────────────
            Text(
              'Focus Sounds',
              style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ambient sound helps maintain flow state. Tap to play.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            _FocusSoundGrid(soundIds: _focusSoundIds),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

// ── Pomodoro progress dots ──────────────────────────────────────────────────

class _PomodoroProgress extends StatelessWidget {
  final int inCurrentCycle;
  final int totalCompleted;
  final int perCycle;
  final bool isLongBreakEarned;

  const _PomodoroProgress({
    required this.inCurrentCycle,
    required this.totalCompleted,
    required this.perCycle,
    required this.isLongBreakEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$totalCompleted session${totalCompleted == 1 ? '' : 's'} completed',
          style: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: List.generate(perCycle, (i) {
            final filled = i < inCurrentCycle;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: filled
                      ? AppColors.accent
                      : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: filled ? AppColors.accent : AppColors.outline,
                  ),
                ),
                child: filled
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : Center(
                        child: Text(
                          '${i + 1}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
              ),
            );
          }),
        ),
        if (isLongBreakEarned)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '🎉 Long break earned! Well done.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.accent),
            ),
          ),
      ],
    );
  }
}

// ── Focus sound grid ────────────────────────────────────────────────────────

class _FocusSoundGrid extends StatelessWidget {
  final List<String> soundIds;
  const _FocusSoundGrid({required this.soundIds});

  @override
  Widget build(BuildContext context) {
    final allSounds = context.read<SoundsProvider>().allSounds;
    final soundMap = {for (final s in allSounds) s.id: s};
    final sounds = soundIds.map((id) => soundMap[id]).whereType<Sound>().toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
      ),
      itemCount: sounds.length,
      itemBuilder: (context, i) => _FocusSoundTile(sound: sounds[i]),
    );
  }
}

class _FocusSoundTile extends StatelessWidget {
  final Sound sound;
  const _FocusSoundTile({required this.sound});

  @override
  Widget build(BuildContext context) {
    final meta = SoundData.metaFor(sound.id);
    return Selector<AudioPlayerProvider, bool>(
      selector: (_, p) => p.currentSoundIds.contains(sound.id) && p.isPlaying,
      builder: (context, isPlaying, _) => GestureDetector(
        onTap: () async {
          final user = context.read<UserProvider>();
          final audio = context.read<AudioPlayerProvider>();
          if (sound.isPremium && !user.isPremiumOrRewarded) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => SoundDetailScreen(sound: sound)),
            );
            return;
          }
          if (isPlaying) {
            await audio.pause();
          } else {
            await audio.playSound(sound);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: meta.gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isPlaying ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
            boxShadow: isPlaying
                ? [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(60),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPlaying ? Icons.pause_circle_filled : meta.icon,
                size: 28,
                color: Colors.white,
              ),
              const SizedBox(height: AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  sound.name,
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight:
                        isPlaying ? FontWeight.w700 : FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
