import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../utils/auth_actions.dart';

/// Shown when a signed-in member has been disabled by the factory owner.
/// The account keeps its Auth session but is blocked from all app data, so the
/// only available action is to sign out.
class AccountDisabledScreen extends StatelessWidget {
  const AccountDisabledScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.accountDisabledTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.no_accounts_outlined,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.accountDisabledTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.accountDisabledMessage,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => AuthActions.confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text(AppStrings.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
