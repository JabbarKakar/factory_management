import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/app_notification.dart';
import '../../../domain/enums/notification_enums.dart';
import '../dashboard/dashboard_surface.dart';

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    required this.isUnread,
    required this.onTap,
    required this.onDismissed,
    this.onSendReminder,
    super.key,
  });

  final AppNotification notification;
  final bool isUnread;
  final VoidCallback onTap;
  final VoidCallback onDismissed;
  final VoidCallback? onSendReminder;

  static String relativeTime(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _priorityColor(notification.priority);
    final icon = _iconFor(notification.type);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Dismissible(
        key: ValueKey(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            Icons.done_all_rounded,
            color: theme.colorScheme.primary,
          ),
        ),
        child: DashboardSurfaceCard(
          compact: true,
          borderRadius: 12,
          padding: EdgeInsets.zero,
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(12),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, size: 16, color: accent),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          notification.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: isUnread
                                                ? FontWeight.w800
                                                : FontWeight.w600,
                                            fontSize: 12,
                                            height: 1.15,
                                          ),
                                        ),
                                      ),
                                      if (isUnread)
                                        Container(
                                          width: 7,
                                          height: 7,
                                          margin: const EdgeInsets.only(
                                            left: 4,
                                            top: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accent,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    notification.body,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme
                                          .colorScheme.onSurfaceVariant,
                                      height: 1.2,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _MetaChip(
                              label: relativeTime(notification.createdAt),
                              icon: Icons.schedule_rounded,
                            ),
                            if (notification.amountDue != null &&
                                notification.amountDue! > 0) ...[
                              const SizedBox(width: 5),
                              _MetaChip(
                                label: Formatters.currencyPkr(
                                  notification.amountDue!,
                                ),
                                icon: Icons.payments_outlined,
                                color: accent,
                              ),
                            ],
                            const Spacer(),
                            if (onSendReminder != null)
                              IconButton(
                                onPressed: onSendReminder,
                                icon: const Icon(Icons.chat_outlined, size: 17),
                                tooltip: AppStrings.sendPaymentReminder,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 30,
                                  minHeight: 30,
                                ),
                              ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(NotificationPriority priority) {
    return switch (priority) {
      NotificationPriority.critical => AppColors.overdue,
      NotificationPriority.high => AppColors.warning,
      NotificationPriority.medium => AppColors.dueSoon,
      NotificationPriority.low => AppColors.textSecondary,
      NotificationPriority.info => AppColors.primary,
    };
  }

  IconData _iconFor(NotificationType type) {
    return switch (type) {
      NotificationType.partialPaymentReceived => Icons.payments_rounded,
      NotificationType.paymentOverdue => Icons.warning_amber_rounded,
      NotificationType.lowRawMaterialStock ||
      NotificationType.lowFinishedGoodsStock =>
        Icons.inventory_2_outlined,
      NotificationType.equipmentMaintenanceDueSoon ||
      NotificationType.equipmentMaintenanceOverdue =>
        Icons.build_circle_outlined,
      NotificationType.pendingDelivery => Icons.local_shipping_outlined,
      NotificationType.qcReject => Icons.cancel_outlined,
      NotificationType.jobWorkReadyForPickup ||
      NotificationType.jobWorkNotCollected =>
        Icons.content_cut_rounded,
      _ => Icons.notifications_active_outlined,
    };
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.icon,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;

  static Color _readableForeground(Color accent, bool isDark) {
    if (!isDark) return accent;
    final hsl = HSLColor.fromColor(accent);
    if (hsl.lightness >= 0.55) return accent;
    return hsl
        .withLightness((hsl.lightness + 0.46).clamp(0.0, 0.84))
        .withSaturation((hsl.saturation * 0.95).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAccent = color != null;
    final accent = color;
    final foreground = isAccent
        ? _readableForeground(accent!, isDark)
        : theme.colorScheme.onSurfaceVariant;
    final background = isAccent
        ? accent!.withValues(alpha: isDark ? 0.30 : 0.14)
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: foreground),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: isAccent ? FontWeight.w700 : FontWeight.w600,
              fontSize: 9,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
