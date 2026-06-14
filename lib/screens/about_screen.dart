import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import '../services/social_service.dart';
import '../widgets/widgets.dart';

class AboutScreen extends StatelessWidget {
  final bool showPrivacy;
  final bool showTerms;

  const AboutScreen({
    super.key,
    this.showPrivacy = false,
    this.showTerms = false,
  });

  String get _title {
    if (showPrivacy) return AppStrings.privacyPolicy;
    if (showTerms) return AppStrings.termsOfService;
    return AppStrings.about;
  }

  String get _legalUrl {
    if (showPrivacy) return AppStrings.privacyPolicyUrl;
    return AppStrings.termsOfServiceUrl;
  }

  String get _legalButtonLabel {
    if (showPrivacy) return 'View full Privacy Policy';
    return 'View full Terms of Service';
  }

  Future<String> get _appVersion async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  String get _content {
    if (showPrivacy) {
      return 'Vesperio is committed to protecting your privacy. We do not sell personal data and only use storage for local preferences, session tracking, and ad personalization settings. In-app purchases and premium subscriptions are handled securely through the app stores.';
    }
    if (showTerms) {
      return 'By using Vesperio, you agree to the app terms of service. This app is provided as-is for sleep and relaxation support, with no warranties.';
    }
    return 'Vesperio helps you fall asleep faster with curated soundscapes, sleep timers, and premium content. Enjoy peaceful nights and a calmer morning.';
  }

  Future<void> _launchLegalUrl(BuildContext context) async {
    final uri = Uri.parse(_legalUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the page. Please try again later.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!showPrivacy && !showTerms) ...[
                  Text(
                    AppStrings.appName,
                    style: AppTypography.heading1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    AppStrings.tagline,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
                ModernCard(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      _content,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (showPrivacy || showTerms) ...[
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchLegalUrl(context),
                      icon: const Icon(Icons.open_in_new),
                      label: Text(_legalButtonLabel),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                if (!showPrivacy && !showTerms) ...[
                  ElevatedButton.icon(
                    onPressed: () => SocialService().shareApp(),
                    icon: const Icon(Icons.share),
                    label: const Text(AppStrings.shareApp),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  ModernCard(
                    child: FutureBuilder<String>(
                      future: _appVersion,
                      builder: (context, snapshot) {
                        final versionText = snapshot.data ?? AppStrings.appVersion;
                        return ListTile(
                          title: const Text(AppStrings.version),
                          subtitle: Text(versionText),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ModernCard(
                    child: ListTile(
                      title: const Text('Support'),
                      subtitle: const Text(AppStrings.supportEmail),
                      leading: const Icon(Icons.email_outlined),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
