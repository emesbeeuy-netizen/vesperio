import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/user_provider.dart';
import '../widgets/widgets.dart';
import 'auth_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

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
              ElevatedButton(
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
            ],
          ),
        ),
      ),
    );
  }
}
