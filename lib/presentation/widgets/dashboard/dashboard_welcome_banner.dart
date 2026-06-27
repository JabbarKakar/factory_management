import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
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
    final dateLabel = DateFormat('EEE, d MMM').format(DateTime.now());

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

    final firstName = user?.name.split(' ').first;
    final greetingLine = user != null
        ? '${_greeting()}, $firstName'
        : _greeting();

    return DashboardSurfaceCard(
      padding: EdgeInsets.zero,
      gradient: gradient,
      borderRadius: 14,
      compact: true,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            right: -18,
            top: -18,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onGradient.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: onGradientMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        greetingLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: onGradient,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          fontSize: 17,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(width: 12),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: onGradient.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: UserAvatar(
                      name: user!.name,
                      photoUrl: user!.photoUrl,
                      radius: 22,
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
