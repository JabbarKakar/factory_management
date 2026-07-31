import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../routes/route_paths.dart';
import '../compact_status_chip.dart';
import '../job_work/job_work_detail_section.dart';

/// First-class per-order delivery history (Sales Order detail).
class DeliveryHistorySection extends StatelessWidget {
  const DeliveryHistorySection({
    required this.deliveries,
    this.onScheduleDelivery,
    this.enabled = true,
    super.key,
  });

  final List<Delivery> deliveries;
  final VoidCallback? onScheduleDelivery;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final sorted = List<Delivery>.from(deliveries)
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));

    return JobWorkDetailSection(
      title: AppStrings.dispatchHistory,
      icon: Icons.local_shipping_outlined,
      action: onScheduleDelivery == null
          ? null
          : TextButton.icon(
              onPressed: enabled ? onScheduleDelivery : null,
              icon: const Icon(Icons.add, size: 16),
              label: const Text(AppStrings.scheduleDelivery),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: sorted.isEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppStrings.noOrderDeliveries,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                  if (onScheduleDelivery != null) ...[
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.tonalIcon(
                        onPressed: enabled ? onScheduleDelivery : null,
                        icon: const Icon(Icons.local_shipping_outlined, size: 18),
                        label: const Text(AppStrings.scheduleDelivery),
                      ),
                    ),
                  ],
                ],
              )
            : Column(
                children: [
                  for (var i = 0; i < sorted.length; i++) ...[
                    _DeliveryHistoryRow(
                      delivery: sorted[i],
                      enabled: enabled,
                    ),
                    if (i < sorted.length - 1) const SizedBox(height: 6),
                  ],
                ],
              ),
      ),
    );
  }
}

class _DeliveryHistoryRow extends StatelessWidget {
  const _DeliveryHistoryRow({
    required this.delivery,
    required this.enabled,
  });

  final Delivery delivery;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = _accentFor(delivery.status);
    final scheduledLabel = DateFormat.yMMMd().format(delivery.scheduledDate);
    final actualLabel = delivery.actualDeliveryDate == null
        ? null
        : DateFormat.yMMMd().format(delivery.actualDeliveryDate!);
    final quantityLabel = _quantityLabel(delivery);
    final logistics = _logisticsLabel(delivery);

    return Material(
      color: accent.withValues(
        alpha: delivery.status == DeliveryStatus.failed ? 0.04 : 0.06,
      ),
      borderRadius: BorderRadius.circular(8),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: Icon(Icons.local_shipping_outlined, size: 16, color: accent),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  delivery.deliveryNumber,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              CompactStatusChip(
                label: delivery.status.label,
                color: accent,
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actualLabel == null
                      ? '${AppStrings.scheduledDateLabel}: $scheduledLabel'
                      : '${AppStrings.scheduledDateLabel}: $scheduledLabel · '
                          '${AppStrings.actualDispatchDate}: $actualLabel',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  quantityLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (logistics != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    logistics,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontSize: 10,
                    ),
                  ),
                ],
                if (delivery.notes != null && delivery.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    delivery.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (delivery.isDispatchOverdue()) ...[
                  const SizedBox(height: 4),
                  CompactStatusChip(
                    label: AppStrings.dispatchOverdue,
                    color: AppColors.overdue,
                  ),
                ],
              ],
            ),
          ),
          children: [
            for (final item in delivery.lineItems)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.displayLabel,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _lineItemQuantityLabel(delivery, item),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: enabled
                      ? () => context.push(
                            RoutePaths.deliveryDetail(delivery.id),
                          )
                      : null,
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text(AppStrings.deliveryDetails),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: enabled
                      ? () => context.push(
                            RoutePaths.deliveryChallan(delivery.id),
                          )
                      : null,
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text(AppStrings.viewChallan),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _quantityLabel(Delivery delivery) {
    if (delivery.status.isTerminal) {
      if (delivery.status == DeliveryStatus.partiallyDelivered) {
        return '${delivery.effectivePieces} / ${delivery.totalPieces} pcs · '
            '${delivery.effectiveSquareFeet.toStringAsFixed(2)} / '
            '${delivery.totalSquareFeet.toStringAsFixed(2)} sq. ft';
      }
      return '${delivery.effectivePieces} pcs · '
          '${delivery.effectiveSquareFeet.toStringAsFixed(2)} sq. ft';
    }
    return '${delivery.totalPieces} pcs · '
        '${delivery.totalSquareFeet.toStringAsFixed(2)} sq. ft scheduled';
  }

  String _lineItemQuantityLabel(Delivery delivery, DeliveryLineItem item) {
    if (delivery.status.isTerminal) {
      return '${item.effectivePieces} / ${item.pieces} pcs · '
          '${item.effectiveSquareFeet.toStringAsFixed(2)} / '
          '${item.squareFeet.toStringAsFixed(2)} sq. ft';
    }
    return '${item.pieces} pcs · ${item.squareFeet.toStringAsFixed(2)} sq. ft';
  }

  String? _logisticsLabel(Delivery delivery) {
    final parts = <String>[];
    if (delivery.vehicleNumber != null && delivery.vehicleNumber!.isNotEmpty) {
      parts.add(
        '${AppStrings.deliveryVehicleNumber}: ${delivery.vehicleNumber}',
      );
    }
    if (delivery.driverName != null && delivery.driverName!.isNotEmpty) {
      parts.add('${AppStrings.driverName}: ${delivery.driverName}');
    }
    if (delivery.loadingSupervisor != null &&
        delivery.loadingSupervisor!.isNotEmpty) {
      parts.add(
        '${AppStrings.loadingSupervisor}: ${delivery.loadingSupervisor}',
      );
    }
    if (delivery.receiverName != null && delivery.receiverName!.isNotEmpty) {
      parts.add('${AppStrings.receiverName}: ${delivery.receiverName}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }

  Color _accentFor(DeliveryStatus status) {
    return switch (status) {
      DeliveryStatus.scheduled => const Color(0xFF1565C0),
      DeliveryStatus.loaded => const Color(0xFF3949AB),
      DeliveryStatus.inTransit => AppColors.warning,
      DeliveryStatus.delivered => AppColors.success,
      DeliveryStatus.partiallyDelivered => AppColors.success,
      DeliveryStatus.failed => AppColors.error,
    };
  }
}
