import 'package:flutter/material.dart';

/// Slate & champagne palette — cool stone neutrals with a refined bronze accent.
abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2E5077);
  static const Color primaryDark = Color(0xFF7CB8E8);
  static const Color primaryContainer = Color(0xFFE8EEF5);
  static const Color primaryContainerDark = Color(0xFF1A3555);
  static const Color accent = Color(0xFFC9A66B);
  static const Color accentLight = Color(0xFFE2C9A0);

  // Semantic
  static const Color success = Color(0xFF0D9488);
  static const Color warning = Color(0xFFEA580C);
  static const Color error = Color(0xFFDC2626);
  static const Color dueSoon = Color(0xFFCA8A04);
  static const Color overdue = Color(0xFF991B1B);

  // Light theme
  static const Color background = Color(0xFFF7F8FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF0F2F5);
  static const Color textPrimary = Color(0xFF141C28);
  static const Color textSecondary = Color(0xFF5E6A7A);
  static const Color divider = Color(0xFFE4E8EE);
  static const Color outline = Color(0xFFD1D9E3);

  // Dark theme
  static const Color backgroundDark = Color(0xFF0E1218);
  static const Color surfaceDark = Color(0xFF171D27);
  static const Color surfaceDarkElevated = Color(0xFF222A38);
  static const Color surfaceDarkMuted = Color(0xFF2A3344);
  static const Color textPrimaryDark = Color(0xFFECEFF4);
  static const Color textSecondaryDark = Color(0xFF8B96A8);
  static const Color dividerDark = Color(0xFF2F3A4D);
  static const Color outlineDark = Color(0xFF3D4D63);
}
