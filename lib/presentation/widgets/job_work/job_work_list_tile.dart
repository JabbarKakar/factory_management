import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/job_work_enums.dart';
import 'job_work_status_badge.dart';

class JobWorkListTile extends StatelessWidget {
  const JobWorkListTile({
    required this.order,
    required this.onTap,
    this.awaitingQcInspection = false,
    super.key,
  });

  final JobWorkOrder order;
  final VoidCallback onTap;
  final bool awaitingQcInspection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isListMuted = order.status.isListMuted;
    final accent = _accentFor(order.status);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    const cardRadius = Radius.circular(14);
    const cardShape = BorderRadius.only(
      topRight: cardRadius,
      bottomRight: cardRadius,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Opacity(
        opacity: isListMuted ? 0.72 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: cardShape,
            child: Ink(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: cardShape,
                border: Border.all(color: outline),
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 3,
                      color: accent,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 11, 10, 11),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    order.customerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      height: 1.2,
                                    ),
                                  ),
                                ),
                                JobWorkStatusBadge(
                                  status: order.status,
                                  compact: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              order.jobWorkNumber,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                if (order.mineLocation != null)
                                  _MetaChip(
                                    icon: Icons.place_outlined,
                                    label: order.mineLocation!,
                                  ),
                                if (order.mineOwner != null)
                                  _MetaChip(
                                    icon: Icons.person_outline,
                                    label: order.mineOwner!,
                                  ),
                                _MetaChip(
                                  icon: Icons.layers_outlined,
                                  label: order.marbleVariety,
                                ),
                                _MetaChip(
                                  icon: Icons.scale_outlined,
                                  label:
                                      '${order.totalTons.toStringAsFixed(2)}t',
                                ),
                                _MetaChip(
                                  icon: Icons.view_module_outlined,
                                  label: '${order.blockCount} blocks',
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.content_cut_outlined,
                                  size: 14,
                                  color: muted,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${order.cuttingStrategy.label} → ${order.targetProduct.label}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                      fontSize: 11,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  order.hasFinalCuttingCharges
                                      ? Formatters.currencyPkr(
                                          order.finalCuttingCharges,
                                        )
                                      : AppStrings.chargesPending,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                    color: order.hasFinalCuttingCharges
                                        ? accent
                                        : muted,
                                  ),
                                ),
                              ],
                            ),
                            if (order.shiftLogs.isNotEmpty &&
                                order.blockCount > 0) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${order.totalBlocksCut} / ${order.blockCount} '
                                  '${AppStrings.blocksCutLabel} · '
                                  '${order.blockCompletionPercent.toStringAsFixed(0)}% '
                                  '${AppStrings.completed.toLowerCase()}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                            if (order.output?.isRecorded == true) ...[
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${order.output!.totalUsableSqFt.toStringAsFixed(0)} sq. ft usable',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                            if (awaitingQcInspection) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.fact_check_outlined,
                                    size: 14,
                                    color: AppColors.warning,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      AppStrings.awaitingQcInspection,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: muted.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _accentFor(JobWorkStatus status) {
    return switch (status) {
      JobWorkStatus.received => AppColors.textSecondary,
      JobWorkStatus.agreed => AppColors.primary,
      JobWorkStatus.inCutting => const Color(0xFF1565C0),
      JobWorkStatus.qc => const Color(0xFF6A1B9A),
      JobWorkStatus.ready => AppColors.success,
      JobWorkStatus.invoiced || JobWorkStatus.paid => AppColors.accent,
      JobWorkStatus.collected || JobWorkStatus.closed => const Color(0xFF455A64),
      JobWorkStatus.cancelled => AppColors.error,
    };
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
