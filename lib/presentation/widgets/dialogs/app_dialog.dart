import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Shared shell for app dialogs — compact typography, icon header, action row.
class AppDialog extends StatelessWidget {
  const AppDialog({
    required this.title,
    required this.content,
    this.message,
    this.icon,
    this.iconColor,
    this.actions,
    this.maxWidth = 400,
    this.scrollable = false,
    this.includeContentSection = true,
    super.key,
  });

  final String title;
  final String? message;
  final IconData? icon;
  final Color? iconColor;
  final Widget content;
  final List<Widget>? actions;
  final double maxWidth;
  final bool scrollable;
  final bool includeContentSection;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final accent = iconColor ?? theme.colorScheme.primary;

    final body = scrollable
        ? Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: content,
            ),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
            child: content,
          );

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: outline),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (icon != null) ...[
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 18, color: accent),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            height: 1.25,
                          ),
                        ),
                        if (message != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            message!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: outline.withValues(alpha: 0.7)),
            if (includeContentSection) ...[
              body,
            ],
            if (actions != null && actions!.isNotEmpty) ...[
              Divider(height: 1, color: outline.withValues(alpha: 0.7)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    for (var i = 0; i < actions!.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: actions![i]),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AppDialogActions {
  const AppDialogActions._();

  static Widget cancel(
    BuildContext context, {
    String label = AppStrings.cancel,
    VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed ?? () => Navigator.of(context).pop(),
      style: OutlinedButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      child: Text(label),
    );
  }

  static Widget confirm(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    bool destructive = false,
    bool isLoading = false,
  }) {
    final theme = Theme.of(context);

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(vertical: 10),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        backgroundColor: destructive ? theme.colorScheme.error : null,
        foregroundColor: destructive ? theme.colorScheme.onError : null,
      ),
      child: isLoading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: destructive
                    ? theme.colorScheme.onError
                    : theme.colorScheme.onPrimary,
              ),
            )
          : Text(label),
    );
  }
}

IconData appDialogIconForDestructive(bool destructive) {
  return destructive ? Icons.warning_amber_rounded : Icons.info_outline;
}

Color appDialogIconColorForDestructive(BuildContext context, bool destructive) {
  return destructive
      ? AppColors.error
      : Theme.of(context).colorScheme.primary;
}
