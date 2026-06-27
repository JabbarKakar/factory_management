import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../routes/route_paths.dart';
import '../utils/auth_actions.dart';

class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_AccountMenuAction>(
      tooltip: AppStrings.account,
      icon: const Icon(Icons.account_circle_outlined),
      onSelected: (action) async {
        switch (action) {
          case _AccountMenuAction.settings:
            context.go(RoutePaths.more);
          case _AccountMenuAction.logout:
            await AuthActions.confirmLogout(context);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _AccountMenuAction.settings,
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text(AppStrings.settings),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: _AccountMenuAction.logout,
          child: ListTile(
            leading: Icon(Icons.logout, color: AppColors.error),
            title: Text(
              AppStrings.logout,
              style: TextStyle(color: AppColors.error),
            ),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

enum _AccountMenuAction { settings, logout }
