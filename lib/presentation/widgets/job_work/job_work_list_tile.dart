import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../compact_status_chip.dart';
import '../tile_options_menu.dart';
import 'job_work_status_badge.dart';

class JobWorkListTile extends StatelessWidget {
  const JobWorkListTile({
    required this.order,
    required this.onTap,
    this.displayStatus,
    this.displayCuttingCharges,
    this.displayUsableSqFt,
    this.menuActions = const [],
    this.isBusy = false,
    this.awaitingQcInspection = false,
    this.isPickupOverdue = false,
    this.remainingPieces,
    this.lastReceiverName,
    this.paidAmount,
    this.remainingAmount,
    super.key,
  });

  final JobWorkOrder order;
  final VoidCallback onTap;
  /// When Loads are authoritative, list status may differ from [order.status].
  final JobWorkStatus? displayStatus;
  /// Rolled-up charges from Loads when available.
  final double? displayCuttingCharges;
  /// Rolled-up usable output from Loads when available.
  final double? displayUsableSqFt;
  final List<TileMenuAction> menuActions;
  final bool isBusy;
  final bool awaitingQcInspection;
  final bool isPickupOverdue;
  final int? remainingPieces;
  final String? lastReceiverName;
  final double? paidAmount;
  final double? remainingAmount;

  bool get _showPaymentStrip =>
      paidAmount != null && remainingAmount != null;

  bool get _showRemainingStrip =>
      remainingPieces != null && remainingPieces! > 0;

  JobWorkStatus get _status => displayStatus ?? order.status;

  double get _cuttingCharges =>
      displayCuttingCharges ?? order.finalCuttingCharges;

  bool get _hasCuttingCharges => _cuttingCharges > 0;

  double? get _usableSqFt {
    if (displayUsableSqFt != null && displayUsableSqFt! > 0) {
      return displayUsableSqFt;
    }
    final nested = order.output?.totalUsableSqFt;
    if (nested != null && nested > 0) return nested;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final status = _status;
    final isListMuted = status.isListMuted;
    final accent = _accentFor(status);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    const cardRadius = Radius.circular(14);
    const cardShape = BorderRadius.only(
      topRight: cardRadius,
      bottomRight: cardRadius,
    );
    final hasBlocksStrip =
        order.shiftLogs.isNotEmpty && order.blockCount > 0;
    final usableSqFt = _usableSqFt;
    final hasOutputStrip = usableSqFt != null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Opacity(
        opacity: isListMuted ? 0.72 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isBusy ? null : onTap,
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
                        padding: EdgeInsets.fromLTRB(
                          12,
                          11,
                          menuActions.isNotEmpty ? 2 : 6,
                          11,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
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
                                  status: status,
                                  compact: true,
                                ),
                                if (isPickupOverdue) ...[
                                  const SizedBox(width: 6),
                                  const CompactStatusChip(
                                    label: AppStrings.pickupOverdue,
                                    color: AppColors.overdue,
                                  ),
                                ],
                                if (menuActions.isNotEmpty)
                                  TileOptionsButton(
                                    isBusy: isBusy,
                                    actions: menuActions,
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
                                if (lastReceiverName != null &&
                                    lastReceiverName!.isNotEmpty)
                                  _MetaChip(
                                    icon: Icons.handshake_outlined,
                                    label:
                                        '${AppStrings.receiverName}: $lastReceiverName',
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
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Text(
                                    _hasCuttingCharges
                                        ? Formatters.currencyPkrWhole(
                                            _cuttingCharges,
                                          )
                                        : AppStrings.chargesPending,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: _hasCuttingCharges
                                          ? accent
                                          : muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (hasBlocksStrip || hasOutputStrip) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (hasBlocksStrip)
                                    Expanded(
                                      child: _SummaryStrip(
                                        label:
                                            '${order.totalBlocksCut}/${order.blockCount} '
                                            '${AppStrings.blocksCutLabel} · '
                                            '${order.blockCompletionPercent.toStringAsFixed(0)}%',
                                        color: theme.colorScheme.secondary,
                                      ),
                                    ),
                                  if (hasBlocksStrip && hasOutputStrip)
                                    const SizedBox(width: 6),
                                  if (hasOutputStrip)
                                    Expanded(
                                      child: _SummaryStrip(
                                        label:
                                            '${usableSqFt.toStringAsFixed(0)} sq. ft',
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            if (_showRemainingStrip) ...[
                              const SizedBox(height: 8),
                              _SummaryStrip(
                                label:
                                    '${AppStrings.remainingToCollect}: $remainingPieces pcs',
                                color: isPickupOverdue
                                    ? AppColors.overdue
                                    : AppColors.warning,
                              ),
                            ],
                            if (_showPaymentStrip) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryStrip(
                                      label:
                                          '${AppStrings.amountPaid}: ${Formatters.currencyPkrWhole(paidAmount!)}',
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: _SummaryStrip(
                                      label:
                                          '${AppStrings.balanceDue}: ${Formatters.currencyPkrWhole(remainingAmount!)}',
                                      color: remainingAmount! > 0
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
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
      JobWorkStatus.partiallyCollected => AppColors.warning,
      JobWorkStatus.collected || JobWorkStatus.closed => const Color(0xFF455A64),
      JobWorkStatus.cancelled => AppColors.error,
    };
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
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
