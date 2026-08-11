import 'package:flutter/material.dart';

/// Frontline command-center palette supporting both Light & Dark modes.
abstract final class DashboardFx {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0B1220) : const Color(0xFFF1F5F9);

  static Color cardBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF121826) : const Color(0xFFFFFFFF);

  static Color cardBorder(BuildContext context) =>
      isDark(context)
          ? const Color(0xFF1C2740)
          : const Color(0xFFE2E8F0);

  static Color elevated(BuildContext context) =>
      isDark(context) ? const Color(0xFF1A2436) : const Color(0xFFF8FAFC);

  static Color primary(BuildContext context) =>
      isDark(context)
          ? const Color(0xFFFDD343)
          : Theme.of(context).colorScheme.primary;

  static Color success(BuildContext context) =>
      isDark(context) ? const Color(0xFF22C55E) : const Color(0xFF16A34A);

  static Color danger(BuildContext context) =>
      isDark(context) ? const Color(0xFFEF4444) : const Color(0xFFDC2626);

  static Color electric(BuildContext context) =>
      isDark(context) ? const Color(0xFF3B82F6) : const Color(0xFF2563EB);

  static Color violet(BuildContext context) =>
      isDark(context) ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);

  static Color muted(BuildContext context) =>
      isDark(context) ? const Color(0xFF8B96A8) : const Color(0xFF64748B);

  static Color text(BuildContext context) =>
      isDark(context) ? const Color(0xFFECEFF4) : const Color(0xFF0F172A);

  // Static constants for backward compatibility
  static const Color darkBg = Color(0xFF0B1220);
  static const Color darkCardBg = Color(0xFF121826);
  static const Color darkCardBorder = Color(0xFF1C2740);
  static const Color darkElevated = Color(0xFF1A2436);
  static const Color darkPrimary = Color(0xFFFDD343);
  static const Color darkSuccess = Color(0xFF22C55E);
  static const Color darkDanger = Color(0xFFEF4444);
  static const Color darkElectric = Color(0xFF3B82F6);
  static const Color darkViolet = Color(0xFFA78BFA);
  static const Color darkMuted = Color(0xFF8B96A8);
  static const Color darkText = Color(0xFFECEFF4);
}
