import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/session_provider.dart';
import '../services/notification_service.dart';
import '../services/preferences_service.dart';
import '../widgets/widgets.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _timerAlerts = true;
  bool _bedtimeReminder = false;
  bool _morningCheckIn = false;

  @override
  void initState() {
    super.initState();
    final prefs = PreferencesService();
    _timerAlerts = prefs.getBool('timer_alerts', defaultValue: true);
    _bedtimeReminder = prefs.getBedtimeReminderEnabled();
    _morningCheckIn = prefs.getMorningCheckInEnabled();
  }

  Future<void> _onBedtimeReminderChanged(bool value) async {
    setState(() => _bedtimeReminder = value);
    // Capture provider data before any await.
    final sessionProvider = context.read<SessionProvider>();
    final streak = sessionProvider.currentStreak;
    final hour = sessionProvider.habitualBedtimeHour;

    await PreferencesService().setBedtimeReminderEnabled(value);
    final notif = NotificationService();
    if (value) {
      final reminderHour = hour == 0 ? 21 : (hour - 1).clamp(18, 23);
      await notif.scheduleBedtimeReminder(
        hour: reminderHour,
        minute: 45,
        streak: streak,
      );
    } else {
      await notif.cancelBedtimeReminder();
    }
  }

  Future<void> _onMorningCheckInChanged(bool value) async {
    setState(() => _morningCheckIn = value);
    await PreferencesService().setMorningCheckInEnabled(value);
    if (!value) {
      await NotificationService().cancelMorningCheckIn();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.notifications),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notification settings',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ModernCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: _timerAlerts,
                      onChanged: (value) async {
                        setState(() => _timerAlerts = value);
                        await PreferencesService().setBool('timer_alerts', value);
                      },
                      title: const Text('Timer alerts'),
                      subtitle:
                          const Text('Notify when sleep timer finishes.'),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _bedtimeReminder,
                      onChanged: _onBedtimeReminderChanged,
                      title: const Text('Bedtime reminder'),
                      subtitle: const Text(
                        'Daily reminder based on your usual sleep time.',
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      value: _morningCheckIn,
                      onChanged: _onMorningCheckInChanged,
                      title: const Text('Morning check-in'),
                      subtitle: const Text(
                        'Rate last night\'s sleep each morning.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Notifications help you build a consistent sleep routine and track improvement over time.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
