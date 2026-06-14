import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sleep_session.dart';
import '../providers/session_provider.dart';
import '../constants/app_constants.dart';
import '../widgets/widgets.dart';
import 'session_detail_screen.dart';

class SleepStatsScreen extends StatelessWidget {
  const SleepStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Stats')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Selector<SessionProvider, List<SleepSession>>(
            selector: (_, provider) => provider.sessions,
            builder: (context, sessions, _) {
              final totalMinutes = sessions.fold<int>(0, (sum, session) => sum + session.totalMinutesListened);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sleep statistics',
                    style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ModernCard(
                    child: ListTile(
                      title: const Text('Total sessions'),
                      subtitle: Text('${sessions.length} recorded sessions'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ModernCard(
                    child: ListTile(
                      title: const Text('Total minutes listened'),
                      subtitle: Text('$totalMinutes minutes'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: ListView.separated(
                      itemCount: sessions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        final duration = session.duration;
                        final durationText = duration.inHours > 0
                            ? '${duration.inHours}h ${duration.inMinutes.remainder(60)}m'
                            : '${duration.inMinutes}m';
                        return ModernCard(
                          child: ListTile(
                            title: Text('${session.soundIds.length} sounds'),
                            subtitle: Text(durationText),
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
