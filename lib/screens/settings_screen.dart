import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/user_provider.dart';
import '../services/social_service.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'notification_settings_screen.dart';
import 'smart_alarm_screen.dart';
import 'premium_purchase_screen.dart';
import 'settings_detail_screen.dart';
import 'sleep_stats_screen.dart';
import 'user_profile_screen.dart';
import '../services/preferences_service.dart';
import '../widgets/rewarded_ad_button.dart';
import '../widgets/widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _unlimitedFade;
  late int _fadeSeconds;

  @override
  void initState() {
    super.initState();
    final prefs = PreferencesService();
    _unlimitedFade = prefs.getUnlimitedFade();
    _fadeSeconds = prefs.getFadeSeconds();
  }

  Future<void> _updateUnlimited(bool v) async {
    setState(() => _unlimitedFade = v);
    await PreferencesService().setUnlimitedFade(v);
  }

  Future<void> _updateFadeSeconds(int s) async {
    setState(() => _fadeSeconds = s);
    await PreferencesService().setFadeSeconds(s);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.settings),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text(
                'Account',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ModernCard(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text(AppStrings.account),
                  subtitle: Selector<UserProvider, bool>(
                    selector: (_, provider) => provider.isPremium,
                    builder: (context, isPremium, _) {
                      return Text(isPremium ? 'Premium member' : 'Free user');
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UserProfileScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ModernCard(
                child: ListTile(
                  leading: const Icon(Icons.upgrade),
                  title: const Text('Premium Upgrade'),
                  subtitle: Selector<UserProvider, bool>(
                    selector: (_, provider) => provider.isPremium,
                    builder: (context, isPremium, _) {
                      return Text(isPremium
                          ? 'You already have premium access'
                          : 'Unlock ad-free playback, extra sounds, and downloads');
                    },
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PremiumPurchaseScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ModernCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text(AppStrings.notifications),
                      subtitle: const Text('Manage your notification preferences'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.alarm),
                      title: const Text('Smart Alarm'),
                      subtitle: const Text('Sleep-cycle aware alarm — Premium'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SmartAlarmScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.show_chart),
                      title: const Text('Sleep stats'),
                      subtitle: const Text('View session history and sleep trends'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SleepStatsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Advanced settings'),
                      subtitle: const Text('Open detailed app preferences'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SettingsDetailScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Preferences',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ModernCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      value: true,
                      onChanged: (_) {},
                      title: const Text('Notifications'),
                      subtitle: const Text('Receive sleep timer and reminder alerts'),
                    ),
                    const Divider(height: 1),
                    Selector<UserProvider, bool>(
                      selector: (_, provider) => provider.isPremium,
                      builder: (context, isPremium, _) {
                        return SwitchListTile(
                          value: isPremium,
                          onChanged: (_) {},
                          title: const Text('Premium feature access'),
                          subtitle: const Text('Unlock extended sounds and downloads'),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ModernCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.timeline),
                      title: const Text('Timer fade duration'),
                      subtitle: Text(_unlimitedFade
                          ? 'Unlimited fade enabled' : 'Fade seconds: $_fadeSeconds'),
                      trailing: DropdownButton<int>(
                        value: _fadeSeconds,
                        onChanged: _unlimitedFade ? null : (v) { if (v!=null) _updateFadeSeconds(v); },
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 s')),
                          DropdownMenuItem(value: 10, child: Text('10 s')),
                          DropdownMenuItem(value: 30, child: Text('30 s')),
                          DropdownMenuItem(value: 60, child: Text('60 s')),
                          DropdownMenuItem(value: 300, child: Text('300 s')),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Unlimited fade-out'),
                      subtitle: const Text('Gradually fade until sounds stop (long fade)'),
                      value: _unlimitedFade,
                      onChanged: (v) => _updateUnlimited(v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              ModernCard(
                child: ListTile(
                  leading: const Icon(Icons.play_circle_fill),
                  title: const Text('Watch ad reward'),
                  subtitle: const Text('Watch a quick ad to earn a bonus sound suggestion.'),
                  trailing: SizedBox(
                    width: 120,
                    child: const RewardedAdButton(label: 'Watch Ad'),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Support',
                style: AppTypography.heading2.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ModernCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.share_outlined),
                      title: const Text(AppStrings.shareApp),
                      subtitle: const Text('Invite friends and share Vesperio with your network'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        SocialService().shareApp();
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text(AppStrings.helpCenter),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const HelpScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text(AppStrings.about),
                      trailing: const Icon(Icons.chevron_right),
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
      ),
    );
  }
}
