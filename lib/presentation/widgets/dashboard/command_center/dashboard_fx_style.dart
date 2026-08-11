import 'package:flutter/material.dart';

import 'dashboard_fx_theme.dart';

/// Shared typography / spacing helpers for command-center widgets.
abstract final class DashboardFxStyle {
  static const double spaceXs = 6;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;

  static TextStyle title([BuildContext? context]) => TextStyle(
        color: context != null ? DashboardFx.text(context) : DashboardFx.darkText,
        fontWeight: FontWeight.w800,
        fontSize: 14,
        letterSpacing: -0.25,
        height: 1.2,
      );

  static TextStyle subtitle([BuildContext? context]) => TextStyle(
        color: context != null ? DashboardFx.muted(context) : DashboardFx.darkMuted,
        fontWeight: FontWeight.w500,
        fontSize: 11,
        height: 1.3,
      );

  static TextStyle label([BuildContext? context]) => TextStyle(
        color: context != null ? DashboardFx.muted(context) : DashboardFx.darkMuted,
        fontWeight: FontWeight.w700,
        fontSize: 10.5,
        letterSpacing: 0.15,
      );

  static TextStyle value([BuildContext? context]) => TextStyle(
        color: context != null ? DashboardFx.text(context) : DashboardFx.darkText,
        fontWeight: FontWeight.w800,
        fontSize: 18,
        letterSpacing: -0.4,
        height: 1.1,
      );

  static TextStyle caption([BuildContext? context]) => TextStyle(
        color: context != null ? DashboardFx.muted(context) : DashboardFx.darkMuted,
        fontWeight: FontWeight.w600,
        fontSize: 10,
      );
}

class DashboardFxSectionLabel extends StatelessWidget {
  const DashboardFxSectionLabel({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final primary = DashboardFx.primary(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: DashboardFxStyle.spaceSm),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: primary.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(icon, size: 15, color: primary),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: DashboardFxStyle.title(context)),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: DashboardFxStyle.subtitle(context)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
