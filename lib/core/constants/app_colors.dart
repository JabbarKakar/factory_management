import 'package:flutter/material.dart';

abstract final class AppColors {
  // Shared brand colors
  static const Color primary = Color(0xFF1A237E);
  static const Color accent = Color(0xFFF57F17);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color error = Color(0xFFC62828);
  static const Color dueSoon = Color(0xFFF9A825);
  static const Color overdue = Color(0xFFB71C1C);

  // Light theme
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFE0E0E0);

  // Dark theme
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceDarkElevated = Color(0xFF2C2C2C);
  static const Color textPrimaryDark = Color(0xFFE8E8E8);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color dividerDark = Color(0xFF3A3A3A);
}
