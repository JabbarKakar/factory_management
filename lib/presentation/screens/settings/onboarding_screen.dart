import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_actions.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/empty_state_view.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await AuthActions.confirmLogout(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.onboarding)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DashboardSurfaceCard(
              compact: true,
              borderRadius: 14,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              child: EmptyStateView(
                icon: Icons.factory_outlined,
                title: AppStrings.onboarding,
                subtitle: '${AppStrings.onboardingSubtitle}.\n\n'
                    '${AppStrings.onboardingBody}',
                action: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.push(RoutePaths.signUp),
                      icon: const Icon(Icons.app_registration_outlined, size: 18),
                      label: Text(
                        AppStrings.createFactoryAccount,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => context.push(RoutePaths.acceptInvite),
                      icon: const Icon(Icons.mail_outline, size: 18),
                      label: Text(
                        AppStrings.acceptInvite,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _logout(context),
                      child: Text(
                        AppStrings.logout,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
