import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logSoundPlayed(String soundId, {required bool isPremium}) async {
    await _analytics.logEvent(
      name: 'sound_played',
      parameters: {'sound_id': soundId, 'is_premium': isPremium},
    );
  }

  Future<void> logSessionCompleted(int minutes) async {
    await _analytics.logEvent(
      name: 'session_completed',
      parameters: {'duration_minutes': minutes},
    );
  }

  Future<void> logPremiumPurchased({required String plan}) async {
    await _analytics.logEvent(
      name: 'premium_purchased',
      parameters: {'plan': plan},
    );
  }

  Future<void> logFreeTrialStarted({required String plan}) async {
    await _analytics.logEvent(
      name: 'free_trial_started',
      parameters: {'plan': plan},
    );
  }

  Future<void> logPlanSelected(String plan) async {
    await _analytics.logEvent(
      name: 'plan_selected',
      parameters: {'plan': plan},
    );
  }

  Future<void> logPaywallShown(String source) async {
    await _analytics.logEvent(
      name: 'paywall_shown',
      parameters: {'source': source},
    );
  }

  Future<void> logPaywallDismissed(String source) async {
    await _analytics.logEvent(
      name: 'paywall_dismissed',
      parameters: {'source': source},
    );
  }

  Future<void> logAdRewardEarned() async {
    await _analytics.logEvent(name: 'ad_reward_earned');
  }

  Future<void> logAdDailyLimitHit() async {
    await _analytics.logEvent(name: 'ad_daily_limit_hit');
  }

  Future<void> logSoundFavorited(String soundId) async {
    await _analytics.logEvent(
      name: 'sound_favorited',
      parameters: {'sound_id': soundId},
    );
  }

  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }
}
