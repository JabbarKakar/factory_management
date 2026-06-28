import 'package:flutter/material.dart';

/// Refined extended FAB for list screens — slim symmetric pill, no accent bar.
class AppExtendedFab extends StatelessWidget {
  const AppExtendedFab({
    required this.heroTag,
    required this.onPressed,
    required this.icon,
    required this.label,
    super.key,
  });

  final String heroTag;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;

    return Hero(
      tag: heroTag,
      child: Material(
        color: Colors.transparent,
        elevation: 0,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: isDark ? 0.3 : 0.24),
                  blurRadius: isDark ? 10 : 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 17, color: onPrimary),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      height: 1.2,
                      letterSpacing: 0.15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
