import 'package:flutter/material.dart';

/// Small status label used inside list cards and similar compact surfaces.
class CompactStatusChip extends StatelessWidget {
  const CompactStatusChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final foreground = _readableOnSurface(color, isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
              fontSize: 11,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static Color readableForeground(Color base, bool isDark) {
    if (!isDark) return base;

    final hsl = HSLColor.fromColor(base);
    if (hsl.lightness < 0.55) {
      return hsl
          .withLightness((hsl.lightness + 0.42).clamp(0.0, 0.82))
          .toColor();
    }
    return base;
  }

  static Color _readableOnSurface(Color base, bool isDark) =>
      readableForeground(base, isDark);
}
