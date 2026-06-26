import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../routes/route_paths.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/theme_mode_selector.dart';
import '../../widgets/user_profile_card.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.logoutTitle,
      message: AppStrings.logoutMessage,
      confirmLabel: AppStrings.logout,
      cancelLabel: AppStrings.cancel,
      destructive: true,
    );

    if (!context.mounted || !confirmed) return;

    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.more)),
      body: ListView(
        children: [
          if (user != null) UserProfileCard(user: user),
          SettingsSection(
            title: AppStrings.appearance,
            child: const ThemeModeSelector(),
          ),
          SettingsSection(
            title: AppStrings.general,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text(AppStrings.factoryExpenses),
                  subtitle: const Text(AppStrings.factoryExpensesSubtitle),
                  onTap: () => context.push(RoutePaths.expenses),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text(AppStrings.settings),
                  subtitle: const Text(AppStrings.comingSoon),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text(AppStrings.help),
                  subtitle: const Text(AppStrings.comingSoon),
                  onTap: () {},
                ),
              ],
            ),
          ),
          SettingsSection(
            title: AppStrings.account,
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text(
                AppStrings.logout,
                style: TextStyle(color: AppColors.error),
              ),
              subtitle: const Text(AppStrings.logoutSubtitle),
              onTap: () => _confirmLogout(context),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
