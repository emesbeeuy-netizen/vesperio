import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/user_provider.dart';
import '../widgets/widgets.dart';
import 'auth_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  Future<void> _confirmDeleteAccount(BuildContext context, UserProvider userProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Account',
          style: TextStyle(color: AppColors.textPrimary, fontFamily: 'Poppins'),
        ),
        content: const Text(
          'This will permanently delete your account and erase all your data, including sleep sessions, favorites, and listening history. This action cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary, fontFamily: 'Poppins'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete Account',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    await userProvider.deleteAccount();

    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your account has been deleted.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayName = context.select<UserProvider, String?>((provider) => provider.user.displayName);
    final email = context.select<UserProvider, String?>((provider) => provider.user.email);
    final premiumExpiryDate = context.select<UserProvider, DateTime?>((provider) => provider.user.premiumExpiryDate);
    final totalListeningMinutes = context.select<UserProvider, int>((provider) => provider.user.totalListeningMinutes);
    final lastListenedDate = context.select<UserProvider, DateTime>((provider) => provider.user.lastListenedDate);
    final isLoggedIn = context.select<UserProvider, bool>((provider) => provider.isLoggedIn);
    final isPremium = context.select<UserProvider, bool>((provider) => provider.isPremium);
    final userProvider = context.read<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
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
                'Your profile',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ModernCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account status',
                        style: AppTypography.heading2.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        isLoggedIn
                            ? 'Signed in as ${displayName ?? email ?? 'Guest'}'
                            : 'Not signed in',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        isPremium
                            ? 'Premium member until ${premiumExpiryDate?.toLocal().toString().split(' ').first ?? 'N/A'}'
                            : 'Free member',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Total listening minutes',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$totalListeningMinutes minutes',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Last listened',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        lastListenedDate.toLocal().toString().split(' ').first,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      userProvider.logout();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Signed out successfully.')),
                      );
                      return;
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AuthScreen(),
                      ),
                    );
                  },
                  child: Text(isLoggedIn ? AppStrings.logout : AppStrings.signIn),
                ),
              ),
              if (isLoggedIn) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => _confirmDeleteAccount(context, userProvider),
                    child: const Text('Delete Account'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
