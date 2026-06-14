import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/index.dart';
import '../models/index.dart';
import '../services/storage_service.dart';
import '../widgets/widgets.dart';
import 'premium_purchase_screen.dart';

class MixerScreen extends StatefulWidget {
  const MixerScreen({super.key});

  @override
  State<MixerScreen> createState() => _MixerScreenState();
}

class _MixerScreenState extends State<MixerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mixer),
        elevation: 0,
        backgroundColor: AppColors.surface,
      ),
      bottomNavigationBar: const _MixerPlayerBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _ActiveSoundsSection(),
              _AddMoreSoundsSection(),
              _MixerEmptyState(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveSoundsSection extends StatelessWidget {
  const _ActiveSoundsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        final currentSounds = provider.currentSounds;
        if (currentSounds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Sounds',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: currentSounds.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppSpacing.lg),
              itemBuilder: (context, index) {
                final sound = currentSounds[index];
                return _MixerSoundTile(
                  key: ValueKey(sound.id),
                  sound: sound,
                  soundIndex: index,
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }
}

class _MixerSoundTile extends StatelessWidget {
  final Sound sound;
  final int soundIndex;

  const _MixerSoundTile({
    super.key,
    required this.sound,
    required this.soundIndex,
  });

  @override
  Widget build(BuildContext context) {
    // Watch volume for this specific sound
    final volume = context.select<AudioPlayerProvider, double>(
      (provider) => provider.volumes.length > soundIndex
          ? provider.volumes[soundIndex]
          : 1.0,
    );

    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sound.name,
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        sound.category,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<AudioPlayerProvider>().removeSound(
                      sound.id,
                    );
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Removed "${sound.name}" from mixer'),
                        duration: const Duration(milliseconds: 900),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Volume: ${(volume * 100).toStringAsFixed(0)}%',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Slider(
              value: volume,
              onChanged: (newVolume) {
                context.read<AudioPlayerProvider>().updateSoundVolume(
                  sound.id,
                  newVolume,
                );
              },
              min: 0.0,
              max: 1.0,
              divisions: 100,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMoreSoundsSection extends StatelessWidget {
  const _AddMoreSoundsSection();

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioPlayerProvider>(
      builder: (context, provider, _) {
        final currentSoundIds = provider.currentSoundIds;
        if (currentSoundIds.length >= 4) {
          return const SizedBox.shrink();
        }

        final allSounds = context.read<SoundsProvider>().allSounds;
        final List<Sound> availableSounds = [];
        for (final sound in allSounds) {
          if (!currentSoundIds.contains(sound.id)) {
            availableSounds.add(sound);
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add More Sounds',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
          ),
          itemCount: availableSounds.length,
          itemBuilder: (context, index) {
            final sound = availableSounds[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  await context.read<AudioPlayerProvider>().addSound(sound);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Added "${sound.name}" to mixer'),
                      duration: const Duration(milliseconds: 900),
                    ),
                  );
                },
                child: ModernCard(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withAlpha(
                                (0.1 * 255).round(),
                              ),
                              AppColors.secondary.withAlpha(
                                (0.1 * 255).round(),
                              ),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.music_note,
                              size: 32,
                              color: AppColors.primary.withAlpha(
                                (0.5 * 255).round(),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              sound.name,
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: AppSpacing.md,
                        right: AppSpacing.md,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            color: AppColors.textInverse,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
        );
      },
    );
  }
}

class _MixerPlayerBar extends StatelessWidget {
  const _MixerPlayerBar();

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerProvider, bool>(
      selector: (_, provider) => provider.currentSounds.isNotEmpty,
      builder: (context, hasSounds, _) {
        if (!hasSounds) return const SizedBox.shrink();

        final isPlaying = context.select<AudioPlayerProvider, bool>(
          (provider) => provider.isPlaying,
        );
        final soundCount = context.select<AudioPlayerProvider, int>(
          (provider) => provider.currentSounds.length,
        );

        return SafeArea(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: AppColors.primary.withAlpha(40),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                // Status info
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.equalizer,
                            size: 14,
                            color: isPlaying
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            isPlaying ? 'Now Playing' : 'Paused',
                            style: AppTypography.labelMedium.copyWith(
                              color: isPlaying
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$soundCount sound${soundCount == 1 ? '' : 's'} in mix',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Save preset
                IconButton(
                  tooltip: 'Save Preset',
                  icon: const Icon(Icons.bookmark_add_outlined),
                  color: AppColors.textSecondary,
                  onPressed: () => _savePreset(context),
                ),
                // Restore preset
                IconButton(
                  tooltip: 'Restore Preset',
                  icon: const Icon(Icons.bookmarks_outlined),
                  color: AppColors.textSecondary,
                  onPressed: () => _restorePreset(context),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Stop
                IconButton(
                  tooltip: 'Stop',
                  icon: const Icon(Icons.stop_circle_outlined),
                  color: AppColors.textSecondary,
                  iconSize: 28,
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await context.read<AudioPlayerProvider>().stop();
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text('Mixer stopped'),
                        duration: Duration(milliseconds: 900),
                      ),
                    );
                  },
                ),
                // Play / Pause — primary action
                const SizedBox(width: AppSpacing.xs),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textInverse,
                    minimumSize: const Size(56, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final audioPlayer = context.read<AudioPlayerProvider>();
                    if (isPlaying) {
                      await audioPlayer.pause();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Mixer paused'),
                          duration: Duration(milliseconds: 900),
                        ),
                      );
                    } else {
                      await audioPlayer.play();
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Mixer playing'),
                          duration: Duration(milliseconds: 900),
                        ),
                      );
                    }
                  },
                  child: Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePreset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final storage = StorageService();
    final audioPlayer = context.read<AudioPlayerProvider>();
    final user = context.read<UserProvider>();

    if (!user.isPremiumOrRewarded && storage.getMixerPresets().length >= 2) {
      final goToPurchase = await PremiumUpsellSheet.show(
        context,
        source: UpsellSource.mixerLimit,
      );
      if (goToPurchase == true && context.mounted) {
        unawaited(Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()),
        ));
      }
      return;
    }

    final List<String> soundIds = [];
    for (final s in audioPlayer.currentSounds) {
      soundIds.add(s.id);
    }
    final data = {'soundIds': soundIds, 'volumes': audioPlayer.volumes};
    final nameCtrl = TextEditingController(
      text: 'My Mix ${storage.getMixerPresets().length + 1}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save Mixer Preset'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Preset name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(nameCtrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await storage.saveMixerPreset(name, data);
      messenger.showSnackBar(
        const SnackBar(content: Text('Mixer preset saved')),
      );
    }
  }

  Future<void> _restorePreset(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final storage = StorageService();
    final presets = storage.getMixerPresets();
    final allSounds = context.read<SoundsProvider>().allSounds;
    if (presets.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No saved presets')),
      );
      return;
    }
    final navigator = Navigator.of(context);
    final audioPlayer = context.read<AudioPlayerProvider>();
    final chosen = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        final options = <Widget>[];
        for (final name in presets.keys) {
          options.add(
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(name),
              child: Text(name),
            ),
          );
        }
        return SimpleDialog(
          title: const Text('Select Preset to Restore'),
          children: options,
        );
      },
    );
    if (!navigator.mounted) return;
    if (chosen == null) return;
    final saved = presets[chosen];
    if (saved is Map) {
      final soundIds = <String>[];
      final rawIds = saved['soundIds'] as List<dynamic>?;
      if (rawIds != null) {
        for (final id in rawIds) {
          try {
            soundIds.add(id as String);
          } catch (_) {}
        }
      }
      final volumes = <double>[];
      final rawVolumes = saved['volumes'] as List<dynamic>?;
      if (rawVolumes != null) {
        for (final e in rawVolumes) {
          try {
            volumes.add((e as num).toDouble());
          } catch (_) {}
        }
      }
      final sounds = <Sound>[];
      for (final id in soundIds) {
        try {
          final s = allSounds.firstWhere((s) => s.id == id);
          sounds.add(s);
        } catch (_) {}
      }
      if (sounds.isNotEmpty) {
        await audioPlayer.restoreFromIds(sounds, volumes);
        messenger.showSnackBar(
          SnackBar(content: Text('Preset "$chosen" restored')),
        );
      } else {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No matching sounds found for preset'),
          ),
        );
      }
    }
  }
}

class _MixerEmptyState extends StatelessWidget {
  const _MixerEmptyState();

  @override
  Widget build(BuildContext context) {
    return Selector<AudioPlayerProvider, bool>(
      selector: (_, provider) => provider.currentSounds.isEmpty,
      builder: (context, isEmpty, _) {
        if (!isEmpty) return const SizedBox.shrink();
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
            child: Column(
              children: [
                Icon(
                  Icons.music_note,
                  size: 64,
                  color: AppColors.primary.withAlpha((0.2 * 255).round()),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No sounds selected',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Add up to 4 sounds to create your mix',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
