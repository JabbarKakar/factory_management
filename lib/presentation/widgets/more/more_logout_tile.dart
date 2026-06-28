import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../dashboard/dashboard_surface.dart';

class MoreLogoutTile extends StatelessWidget {
  const MoreLogoutTile({
    required this.onTap,
    this.embedded = false,
    super.key,
  });

  final VoidCallback onTap;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final errorColor = isDark
        ? Color.alphaBlend(
            AppColors.error.withValues(alpha: 0.85),
            Colors.white,
          )
        : AppColors.error;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.logout_rounded, size: 19, color: errorColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.logout,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: errorColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.logoutSubtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: errorColor.withValues(alpha: 0.7),
          ),
        ],
      ),
    );

    if (embedded) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return DashboardSurfaceCard(
      compact: true,
      borderRadius: 14,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: content,
    );
  }
}
