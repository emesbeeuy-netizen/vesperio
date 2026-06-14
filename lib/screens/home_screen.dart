import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';
import '../widgets/widgets.dart';
import '../widgets/rewarded_ad_button.dart';
import 'focus_screen.dart';
import 'mixer_screen.dart';
import 'sound_detail_screen.dart';
import 'sleep_tracking_dashboard_screen.dart';
import 'about_screen.dart';
import 'notification_settings_screen.dart';
import 'settings_screen.dart';
import 'premium_purchase_screen.dart';

Future<void> _showHomeTimerSheet(BuildContext context) async {
  final audioProvider = context.read<AudioPlayerProvider>();
  if (!audioProvider.isPlaying) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Play a sound first to set a timer.')),
    );
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Sleep Timer',
            style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          ...[15, 30, 45, 60].map(
            (minutes) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await audioProvider.setTimer(minutes);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: Text('$minutes minutes'),
                ),
              ),
            ),
          ),
          if (audioProvider.timerActive)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await audioProvider.clearTimer();
                    if (ctx.mounted) Navigator.of(ctx).pop();
                  },
                  child: const Text('Cancel timer'),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PageStorageBucket _pageStorageBucket = PageStorageBucket();
  AudioPlayerProvider? _audioProvider;
  bool _showingRatingSheet = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = context.read<AudioPlayerProvider>();
    if (_audioProvider != provider) {
      _audioProvider?.removeListener(_checkPendingRating);
      _audioProvider = provider;
      _audioProvider!.addListener(_checkPendingRating);
    }
  }

  @override
  void dispose() {
    _audioProvider?.removeListener(_checkPendingRating);
    super.dispose();
  }

  void _checkPendingRating() {
    if (_audioProvider?.pendingRatingSession != null &&
        !_showingRatingSheet &&
        mounted) {
      _showingRatingSheet = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _showRatingSheet());
    }
  }

  Future<void> _showRatingSheet() async {
    if (!mounted) return;
    final rating = await SleepQualitySheet.show(context);
    if (!mounted) {
      _showingRatingSheet = false;
      return;
    }
    final provider = _audioProvider;
    if (rating != null && provider != null) {
      await provider.submitSessionQualityRating(rating);
    } else {
      provider?.clearPendingRating();
    }
    _showingRatingSheet = false;
  }

  Widget _buildBody() {
    return IndexedStack(
      index: _currentIndex,
      children: const [
        _HomeContent(),
        _SoundsContent(),
        FocusScreen(),
        _SessionContent(),
        _SettingsContent(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageStorage(
        bucket: _pageStorageBucket,
        child: _buildBody(),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Selector<UserProvider, bool>(
            selector: (_, p) => p.isPremiumOrRewarded,
            builder: (_, unlocked, _) =>
                unlocked ? const SizedBox.shrink() : const BannerAdWidget(),
          ),
          BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: AppStrings.homeTab,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.music_note),
                label: AppStrings.soundsTab,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.center_focus_strong),
                label: AppStrings.focusTab,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: AppStrings.sessionTab,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: AppStrings.settingsTab,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        key: const PageStorageKey('home_tab_scroll'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: AppTypography.heading1.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        AppStrings.tagline,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Profile Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _HomeStreakBanner(),
              const SizedBox(height: AppSpacing.xxl),

              const _PremiumPromo(),
              const SizedBox(height: AppSpacing.xxl),
              const _HomeFavoritesSection(),
              const _HomeRecentlyPlayed(),
              const SizedBox(height: AppSpacing.xxl),
              const _HomeMixerPresetsSection(),

              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.volume_up,
                      label: 'Mixer',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const MixerScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: QuickActionCard(
                      icon: Icons.timer,
                      label: 'Timer',
                      onTap: () => _showHomeTimerSheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoundsContent extends StatefulWidget {
  const _SoundsContent();

  @override
  State<_SoundsContent> createState() => _SoundsContentState();
}

class _SoundsContentState extends State<_SoundsContent> {
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<SoundsProvider>().setSearch(query);
  }

  void _toggleSearch() {
    setState(() => _showSearch = !_showSearch);
    if (!_showSearch) {
      _searchController.clear();
      context.read<SoundsProvider>().setSearch('');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + search toggle
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.allSounds,
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showSearch ? Icons.search_off : Icons.search,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _toggleSearch,
                ),
              ],
            ),
          ),

          // Search bar
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search sounds…',
                  prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),

          // Category filter chips
          const SizedBox(height: AppSpacing.md),
          const _CategoryFilterRow(),

          const SizedBox(height: AppSpacing.md),
          const Expanded(child: _SoundsGrid()),
        ],
      ),
    );
  }
}

class _CategoryFilterRow extends StatelessWidget {
  const _CategoryFilterRow();

  @override
  Widget build(BuildContext context) {
    return Selector<SoundsProvider, String>(
      selector: (_, p) => p.selectedCategory,
      builder: (context, selected, _) {
        final categories = context.read<SoundsProvider>().getCategories();
        return SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: categories.length,
            separatorBuilder: (context, i) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = selected == cat;
              return GestureDetector(
                onTap: () => context.read<SoundsProvider>().setCategory(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.outline,
                    ),
                  ),
                  child: Text(
                    cat[0].toUpperCase() + cat.substring(1),
                    style: AppTypography.labelMedium.copyWith(
                      color: isSelected
                          ? AppColors.textInverse
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _SessionContent extends StatelessWidget {
  const _SessionContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'Listening History',
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.dashboard_customize),
                      label: const Text('Dashboard'),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SleepTrackingDashboardScreen(),
                          ),
                        );
                      },
                    ),
                    Selector<SessionProvider, bool>(
                      selector: (_, provider) => provider.sessions.isNotEmpty,
                      builder: (context, hasSessions, _) {
                        if (!hasSessions) {
                          return const SizedBox.shrink();
                        }
                        return TextButton(
                          onPressed: () => context.read<SessionProvider>().clearSessions(),
                          child: const Text('Clear All'),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const Expanded(child: _SessionList()),
          ],
        ),
      ),
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList();

  @override
  Widget build(BuildContext context) {
    return Selector<SessionProvider, List<SleepSession>>(
      selector: (_, provider) => provider.sessions,
      builder: (context, sessions, _) {
        if (sessions.isEmpty) {
          return Center(
            child: Text(
              'No sessions recorded yet. Start playing a sound to save your first session.',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          );
        }
            return ListView.separated(
          key: const PageStorageKey('session_tab_list'),
          itemCount: sessions.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final session = sessions[index];
            final durationText = session.duration.inHours > 0
                ? '${session.duration.inHours}h ${session.duration.inMinutes.remainder(60)}m'
                : '${session.duration.inMinutes}m';
            return ModernCard(
              child: ListTile(
                leading: session.isActive
                    ? const Icon(Icons.play_circle_fill, color: AppColors.primary)
                    : const Icon(Icons.history, color: AppColors.textSecondary),
                title: Text(
                  '${session.soundIds.length} sound${session.soundIds.length == 1 ? '' : 's'}',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  '$durationText • ${session.timerDuration != null ? 'Timer ${session.timerDuration}m' : 'No timer'}',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        );
      },
    );
  }
}

class _SoundsGrid extends StatelessWidget {
  const _SoundsGrid();

  @override
  Widget build(BuildContext context) {
    return Selector<SoundsProvider, List<Sound>>(
      selector: (_, provider) => provider.filteredSounds,
      builder: (context, sounds, _) {
        return GridView.builder(
          key: const PageStorageKey('sounds_tab_grid'),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1,
            mainAxisSpacing: AppSpacing.lg,
            crossAxisSpacing: AppSpacing.lg,
          ),
          itemCount: sounds.length,
          itemBuilder: (context, index) {
            final sound = sounds[index];
            return SoundCardGrid(
              sound: sound,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SoundDetailScreen(sound: sound),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _PremiumPromo extends StatelessWidget {
  const _PremiumPromo();

  @override
  Widget build(BuildContext context) {
    return Selector<UserProvider, bool>(
      selector: (_, provider) => provider.isPremiumOrRewarded,
      builder: (context, unlocked, _) {
        if (unlocked) {
          return const SizedBox.shrink();
        }
        final annualPrice = PurchaseService.instance.priceForPlan(PremiumPlan.annual);
        final annualNum = double.tryParse(annualPrice.replaceAll(RegExp(r'[^\d.]'), ''));
        final monthlyEquiv = annualNum != null
            ? '\$${(annualNum / 12).toStringAsFixed(2)}'
            : PurchaseService.instance.priceForPlan(PremiumPlan.monthly);
        return ModernCard(
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha((0.88 * 255).round()),
                  AppColors.secondary.withAlpha((0.88 * 255).round()),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Try Vesperio Premium free',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '7-day free trial, then $monthlyEquiv/mo when billed annually.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _PromoRow(icon: Icons.music_note, text: '9 premium HD sounds + mixer presets'),
                const SizedBox(height: AppSpacing.xs),
                _PromoRow(icon: Icons.block, text: 'Ad-free · offline listening · unlimited timer'),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          final goToPurchase = await PremiumUpsellSheet.show(
                            context, source: UpsellSource.homeBanner,
                          );
                          if (goToPurchase == true && context.mounted) {
                            unawaited(Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PremiumPurchaseScreen()),
                            ));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: AppColors.textInverse,
                        ),
                        child: const Text('Start 7-day free trial'),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const RewardedAdButton(label: 'Watch an Ad for 2-hr Access'),
                    ],
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

class _PromoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PromoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textInverse, size: 18),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textInverse),
          ),
        ),
      ],
    );
  }
}

class _HomeRecentlyPlayed extends StatelessWidget {
  const _HomeRecentlyPlayed();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.recentlyPlayed,
          style: AppTypography.heading2.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Selector on the version int so this only rebuilds when a new sound is played,
        // not on every 250 ms position tick.
        Selector<AudioPlayerProvider, int>(
          selector: (_, p) => p.recentlyPlayedVersion,
          builder: (context, version, child) {
            final recentIds = context.read<AudioPlayerProvider>().recentlyPlayedIds;
            if (recentIds.isEmpty) {
              return Text(
                'Play some sounds to see them here.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            }
            final allSounds = context.read<SoundsProvider>().allSounds;
            final soundMap = {for (final s in allSounds) s.id: s};
            final sounds = recentIds
                .map((id) => soundMap[id])
                .whereType<Sound>()
                .take(4)
                .toList();
            if (sounds.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: AppDimensions.soundCardHeight,
              child: ListView.separated(
                key: const PageStorageKey('home_recently_played'),
                scrollDirection: Axis.horizontal,
                itemCount: sounds.length,
                separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final sound = sounds[index];
                  return SoundCard(
                    sound: sound,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SoundDetailScreen(sound: sound),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HomeStreakBanner extends StatelessWidget {
  const _HomeStreakBanner();

  @override
  Widget build(BuildContext context) {
    return Selector<SessionProvider, int>(
      selector: (_, p) => p.currentStreak,
      builder: (context, streak, _) {
        if (streak == 0) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SleepTrackingDashboardScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.accent.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Text('🌙', style: TextStyle(fontSize: 18)),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '$streak-night streak',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  'See history →',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accent,
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

class _HomeFavoritesSection extends StatelessWidget {
  const _HomeFavoritesSection();

  @override
  Widget build(BuildContext context) {
    return Selector<UserProvider, List<String>>(
      selector: (_, p) => p.favoriteSoundIds,
      builder: (context, favIds, _) {
        if (favIds.isEmpty) return const SizedBox.shrink();
        final allSounds = context.read<SoundsProvider>().allSounds;
        final soundMap = {for (final s in allSounds) s.id: s};
        final sounds = favIds
            .map((id) => soundMap[id])
            .whereType<Sound>()
            .take(6)
            .toList();
        if (sounds.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Favorites',
              style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              height: AppDimensions.soundCardHeight,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: sounds.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, index) {
                  final sound = sounds[index];
                  return SoundCard(
                    sound: sound,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SoundDetailScreen(sound: sound),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }
}

class _HomeMixerPresetsSection extends StatelessWidget {
  const _HomeMixerPresetsSection();

  @override
  Widget build(BuildContext context) {
    final presets = StorageService().getMixerPresets();
    if (presets.isEmpty) return const SizedBox.shrink();
    final entries = presets.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Mixes',
          style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length + 1,
            separatorBuilder: (context, index) =>
                const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              if (index == entries.length) {
                return _NewMixCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MixerScreen()),
                  ),
                );
              }
              final entry = entries[index];
              return _PresetCard(name: entry.key, data: entry.value);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _PresetCard extends StatelessWidget {
  final String name;
  final dynamic data;
  const _PresetCard({required this.name, required this.data});

  @override
  Widget build(BuildContext context) {
    final soundCount = data is Map
        ? ((data as Map)['soundIds'] as List?)?.length ?? 0
        : 0;
    return GestureDetector(
      onTap: () async {
        final allSounds = context.read<SoundsProvider>().allSounds;
        final audio = context.read<AudioPlayerProvider>();
        if (data is! Map) return;
        final map = data as Map;
        final ids = (map['soundIds'] as List?)?.cast<String>() ?? [];
        final vols = (map['volumes'] as List?)
                ?.map((e) => (e as num).toDouble())
                .toList() ??
            [];
        final soundMap = {for (final s in allSounds) s.id: s};
        final sounds = ids
            .map((id) => soundMap[id])
            .whereType<Sound>()
            .toList();
        if (sounds.isNotEmpty) {
          await audio.restoreFromIds(sounds, vols, playAfter: true);
        }
      },
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.tune, size: 18, color: AppColors.accent),
            Text(
              name,
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '$soundCount sound${soundCount == 1 ? '' : 's'}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewMixCard extends StatelessWidget {
  final VoidCallback onTap;
  const _NewMixCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: AppColors.accent.withAlpha(80),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: AppColors.accent, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'New Mix',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.settings,
              style: AppTypography.heading1.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Expanded(
              child: ListView(
                key: const PageStorageKey('settings_tab_list'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text(AppStrings.account),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text(AppStrings.notifications),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: const Text(AppStrings.privacyPolicy),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(
                            showPrivacy: true,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: const Text(AppStrings.termsOfService),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(
                            showTerms: true,
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text(AppStrings.about),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
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
