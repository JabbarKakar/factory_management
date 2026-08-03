import 'package:flutter/material.dart';

/// Frontline dark command-center palette.
abstract final class DashboardFx {
  static const Color bg = Color(0xFF0B1220);
  static const Color cardBg = Color(0xFF121826);
  static const Color cardBorder = Color(0xFF1C2740);
  static const Color elevated = Color(0xFF1A2436);
  static const Color primary = Color(0xFFFDD343);
  static const Color success = Color(0xFF22C55E);
  static const Color danger = Color(0xFFEF4444);
  static const Color electric = Color(0xFF3B82F6);
  static const Color violet = Color(0xFFA78BFA);
  static const Color muted = Color(0xFF8B96A8);
  static const Color text = Color(0xFFECEFF4);

  static ThemeData theme(BuildContext context) {
    final base = ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        surface: cardBg,
        primary: primary,
        secondary: electric,
        error: danger,
        onSurface: text,
        onPrimary: Color(0xFF0B1220),
        outline: cardBorder,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: cardBorder),
        ),
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      dividerColor: cardBorder,
      expansionTileTheme: const ExpansionTileThemeData(
        iconColor: primary,
        collapsedIconColor: muted,
        textColor: text,
        collapsedTextColor: text,
      ),
    );
  }
}
