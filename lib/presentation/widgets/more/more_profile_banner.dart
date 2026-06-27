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
      borderRadius: 12,
      compact: true,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -18,
            bottom: -18,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onGradient.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -10,
            top: -14,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onGradient.withValues(alpha: 0.04),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: onGradient.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: UserAvatar(
                    name: user.name,
                    photoUrl: user.photoUrl,
                    radius: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onGradient,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          fontSize: 15,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: onGradientMuted,
                          fontSize: 11,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: onGradient.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: onGradient.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.badge_outlined,
                              size: 11,
                              color: onGradientMuted,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              Formatters.roleLabel(user.role),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: onGradient,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                                height: 1.1,
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
