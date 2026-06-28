import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/sales_enums.dart';
import 'sales_order_status_badge.dart';

class SalesOrderDetailHero extends StatelessWidget {
  const SalesOrderDetailHero({
    required this.order,
    required this.isSaving,
    required this.canInvoice,
    required this.hasInvoice,
    this.onAdvanceStatus,
    this.onScheduleDelivery,
    this.onOpenInvoice,
    this.onRecordPayment,
    super.key,
  });

  final SalesOrder order;
  final bool isSaving;
  final bool canInvoice;
  final bool hasInvoice;
  final VoidCallback? onAdvanceStatus;
  final VoidCallback? onScheduleDelivery;
  final VoidCallback? onOpenInvoice;
  final VoidCallback? onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final accent = _accentFor(order.status);
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );
    final nextStatus = order.status.nextStatus;
    final showRecordPayment = hasInvoice &&
        order.status != SalesOrderStatus.paid &&
        order.balanceDue > 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: cardShape,
          border: Border.all(color: outline),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.customerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                height: 1.2,
                              ),
                            ),
                          ),
                          SalesOrderStatusBadge(
                            status: order.status,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        order.orderNumber,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.orderSource.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: outline.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              order.balanceDue > 0
                                  ? AppStrings.balanceDue
                                  : AppStrings.grandTotal,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          Text(
                            Formatters.currencyPkr(
                              order.balanceDue > 0
                                  ? order.balanceDue
                                  : order.grandTotal,
                            ),
                            style: theme.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: accent,
                            ),
                          ),
                        ],
                      ),
                      if (nextStatus != null ||
                          canInvoice ||
                          showRecordPayment) ...[
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          color: outline.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 10),
                        if (nextStatus != null && onAdvanceStatus != null)
                          _ActionButton(
                            label: order.status.advanceActionLabel,
                            filled: true,
                            onPressed:
                                isSaving ? null : onAdvanceStatus,
                          ),
                        if (canInvoice && onScheduleDelivery != null) ...[
                          if (nextStatus != null) const SizedBox(height: 6),
                          _ActionButton(
                            label: AppStrings.scheduleDelivery,
                            icon: Icons.local_shipping_outlined,
                            outlined: true,
                            onPressed:
                                isSaving ? null : onScheduleDelivery,
                          ),
                        ],
                        if (canInvoice && onOpenInvoice != null) ...[
                          if (nextStatus != null || canInvoice)
                            const SizedBox(height: 6),
                          _ActionButton(
                            label: hasInvoice
                                ? AppStrings.viewInvoice
                                : AppStrings.generateInvoice,
                            icon: Icons.receipt_long_outlined,
                            outlined: true,
                            onPressed: isSaving ? null : onOpenInvoice,
                          ),
                        ],
                        if (showRecordPayment && onRecordPayment != null) ...[
                          const SizedBox(height: 6),
                          _ActionButton(
                            label: AppStrings.recordPayment,
                            icon: Icons.payments_outlined,
                            filled: true,
                            onPressed: isSaving ? null : onRecordPayment,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _accentFor(SalesOrderStatus status) {
    return switch (status) {
      SalesOrderStatus.received => AppColors.textSecondary,
      SalesOrderStatus.ready => AppColors.success,
      SalesOrderStatus.invoiced || SalesOrderStatus.paid => AppColors.accent,
      SalesOrderStatus.closed => const Color(0xFF455A64),
      SalesOrderStatus.cancelled => AppColors.error,
    };
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    this.outlined = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;
  final bool outlined;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final child = icon != null
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16),
              const SizedBox(width: 6),
              Text(label, style: style),
            ],
          )
        : Text(label, style: style);

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: child,
        ),
      );
    }

    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: child,
      ),
    );
  }
}
