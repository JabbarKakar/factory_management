import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/app_user.dart';
import '../user_avatar.dart';
import 'dashboard_surface.dart';

class DashboardWelcomeBanner extends StatelessWidget {
  const DashboardWelcomeBanner({this.user, super.key});

  final AppUser? user;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateLabel = DateFormat('EEEE, d MMMM').format(DateTime.now());

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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -24,
            top: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onGradient.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 32,
            bottom: -16,
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
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: onGradientMuted,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user != null
                            ? '${_greeting()},\n${user!.name.split(' ').first}'
                            : _greeting(),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: onGradient,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppStrings.dashboardMvpReady,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: onGradientMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(width: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: onGradient.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                    child: UserAvatar(
                      name: user!.name,
                      photoUrl: user!.photoUrl,
                      radius: 30,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
