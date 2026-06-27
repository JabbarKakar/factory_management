import 'package:flutter/material.dart';

/// Shared shell for dashboard sections — border, radius, optional header.
class DashboardSurfaceCard extends StatelessWidget {
  const DashboardSurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.gradient,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline = theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);

    final decoration = BoxDecoration(
      gradient: gradient,
      color: gradient == null ? theme.colorScheme.surface : null,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: outline),
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
    );

    final content = Padding(padding: padding, child: child);

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: onTap == null
            ? DecoratedBox(decoration: decoration, child: content)
            : InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(18),
                child: DecoratedBox(decoration: decoration, child: content),
              ),
      ),
    );
  }
}

class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    this.icon,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class DashboardTextLink extends StatelessWidget {
  const DashboardTextLink({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: primary,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_forward_rounded, size: 16, color: primary),
        ],
      ),
    );
  }
}
