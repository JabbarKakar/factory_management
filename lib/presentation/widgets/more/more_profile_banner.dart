import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/app_user.dart';
import '../user_avatar.dart';
import '../dashboard/dashboard_surface.dart';

class MoreProfileBanner extends StatelessWidget {
  const MoreProfileBanner({required this.user, super.key});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              AppColors.primaryContainerDark,
              AppColors.surfaceDarkElevated,
            ]
          : [
              AppColors.primary,
              AppColors.primaryLight,
            ],
    );

    final onGradient = isDark ? theme.colorScheme.onSurface : Colors.white;
    final onGradientMuted =
        onGradient.withValues(alpha: isDark ? 0.72 : 0.82);

    return DashboardSurfaceCard(
      padding: EdgeInsets.zero,
      gradient: gradient,
      borderRadius: 14,
      compact: true,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -24,
            bottom: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onGradient.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -12,
            top: -20,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onGradient.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: onGradient.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: UserAvatar(
                    name: user.name,
                    photoUrl: user.photoUrl,
                    radius: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onGradient,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onGradientMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: onGradient.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: onGradient.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 13,
                              color: onGradientMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.roleLabel(user.role),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: onGradient,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
