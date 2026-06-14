import 'package:flutter/material.dart';
import '../models/sleep_session.dart';
import '../constants/app_constants.dart';
import '../widgets/widgets.dart';

class SessionDetailScreen extends StatelessWidget {
  final SleepSession session;

  const SessionDetailScreen({super.key, required this.session});

  String get _durationText {
    final duration = session.duration;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    return '${duration.inMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Session Details')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session summary',
                style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.md),
              ModernCard(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Duration'),
                      subtitle: Text(_durationText),
                    ),
                    ListTile(
                      title: const Text('Started'),
                      subtitle: Text(session.startTime.toLocal().toString()),
                    ),
                    if (session.endTime != null)
                      ListTile(
                        title: const Text('Ended'),
                        subtitle: Text(session.endTime!.toLocal().toString()),
                      ),
                    if (session.timerDuration != null)
                      ListTile(
                        title: const Text('Timer'),
                        subtitle: Text('${session.timerDuration} minutes'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Sounds',
                style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: ListView.separated(
                  itemCount: session.soundIds.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(session.soundIds[index]),
                      subtitle: Text('Volume ${(session.soundVolumes[index] * 100).round()}%'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
