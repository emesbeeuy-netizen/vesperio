import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../models/sleep_session.dart';
import '../providers/session_provider.dart';
import '../widgets/widgets.dart';
import 'session_detail_screen.dart';

class SleepTrackingDashboardScreen extends StatelessWidget {
  const SleepTrackingDashboardScreen({super.key});

  String _qualityLabel(double avg) {
    if (avg >= 3.5) return '🌟 Amazing';
    if (avg >= 2.5) return '😊 Good';
    if (avg >= 1.5) return '😐 Fair';
    return '😴 Poor';
  }

  MapEntry<String, int>? _topSound(List<SleepSession> sessions) {
    final counts = <String, int>{};
    for (final session in sessions) {
      for (final sound in session.soundIds) {
        counts[sound] = (counts[sound] ?? 0) + 1;
      }
    }
    if (counts.isEmpty) return null;
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  }

  String _durationLabel(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remaining = minutes % 60;
      return '$hours h $remaining m';
    }
    return '$minutes m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Dashboard')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Consumer<SessionProvider>(
            builder: (context, provider, _) {
              final sessions = provider.sessions;
              final totalMinutes = sessions.fold<int>(
                  0, (sum, s) => sum + s.totalMinutesListened);
              final averageMinutes = sessions.isEmpty
                  ? 0
                  : (totalMinutes / sessions.length).round();
              final currentStreak = provider.currentStreak;
              final avgQuality = provider.averageSleepQuality;
              final topSound = _topSound(sessions);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep Tracking Dashboard',
                    style: AppTypography.heading1
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'A quick overview of your recent sleep sessions and listening habits.',
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 1.3,
                    children: [
                      _DashboardCard(
                        title: 'Total sessions',
                        value: '${sessions.length}',
                      ),
                      _DashboardCard(
                        title: 'Total minutes',
                        value: _durationLabel(totalMinutes),
                      ),
                      _DashboardCard(
                        title: 'Avg session',
                        value: _durationLabel(averageMinutes),
                      ),
                      _DashboardCard(
                        title: 'Current streak',
                        value: '$currentStreak nights',
                      ),
                      if (avgQuality != null)
                        _DashboardCard(
                          title: 'Sleep quality',
                          value: _qualityLabel(avgQuality),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (topSound != null)
                    ModernCard(
                      child: ListTile(
                        leading: const Icon(Icons.music_note),
                        title: const Text('Most played sound'),
                        subtitle: Text('${topSound.key} • ${topSound.value} sessions'),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Recent sessions',
                    style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: sessions.isEmpty
                        ? Center(
                            child: Text(
                              'No sleep sessions yet. Start a session to see your dashboard metrics.',
                              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : Builder(
                            builder: (context) {
                              return ListView.separated(
                                itemCount: sessions.length > 5 ? 5 : sessions.length,
                                separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final session = sessions[index];
                                  final duration = session.duration;
                                  final durationText = duration.inHours > 0
                                      ? '${duration.inHours}h ${duration.inMinutes.remainder(60)}m'
                                      : '${duration.inMinutes}m';
                                  return ModernCard(
                                    child: ListTile(
                                      title: Text('${session.soundIds.length} sounds'),
                                      subtitle: Text('$durationText • ${session.timerDuration != null ? 'Timer ${session.timerDuration}m' : 'No timer'}'),
                                      trailing: const Icon(Icons.arrow_forward_ios),
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => SessionDetailScreen(session: session),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final String value;

  const _DashboardCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
            const Spacer(),
            Text(
              value,
              style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
