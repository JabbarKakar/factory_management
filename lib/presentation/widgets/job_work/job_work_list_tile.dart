import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../tile_options_menu.dart';

class JobWorkListTile extends StatelessWidget {
  const JobWorkListTile({
    required this.order,
    required this.onTap,
    this.loads = const [],
    this.displayStatus,
    this.menuActions = const [],
    this.isBusy = false,
    this.paidAmount,
    this.remainingAmount,
    super.key,
  });

  final JobWorkOrder order;
  final VoidCallback onTap;
  final List<JobWorkLoad> loads;
  /// Drives accent bar / muted opacity from Load rollup (no status badge).
  final JobWorkStatus? displayStatus;
  final List<TileMenuAction> menuActions;
  final bool isBusy;
  final double? paidAmount;
  final double? remainingAmount;

  bool get _showPaymentStrip =>
      paidAmount != null && remainingAmount != null;

  JobWorkStatus get _status => displayStatus ?? order.status;

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
    final loadSummary = _LoadSummary.from(loads);

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
                    Container(width: 3, color: accent),
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
                                _MetaChip(
                                  icon: Icons.inventory_2_outlined,
                                  label:
                                      '${AppStrings.loads}: ${loadSummary.total}',
                                ),
                                if (loadSummary.agreed > 0)
                                  _MetaChip(
                                    icon: Icons.schedule_outlined,
                                    label:
                                        '${JobWorkStatus.agreed.label}: ${loadSummary.agreed}',
                                  ),
                                if (loadSummary.inCutting > 0)
                                  _MetaChip(
                                    icon: Icons.content_cut_outlined,
                                    label:
                                        '${JobWorkStatus.inCutting.label}: ${loadSummary.inCutting}',
                                  ),
                                if (loadSummary.atQc > 0)
                                  _MetaChip(
                                    icon: Icons.fact_check_outlined,
                                    label:
                                        '${JobWorkStatus.qc.label}: ${loadSummary.atQc}',
                                  ),
                                if (loadSummary.ready > 0)
                                  _MetaChip(
                                    icon: Icons.check_circle_outline,
                                    label:
                                        '${JobWorkStatus.ready.label}: ${loadSummary.ready}',
                                  ),
                                if (loadSummary.partiallyCollected > 0)
                                  _MetaChip(
                                    icon: Icons.handshake_outlined,
                                    label:
                                        '${JobWorkStatus.partiallyCollected.label}: ${loadSummary.partiallyCollected}',
                                  ),
                                if (loadSummary.collected > 0)
                                  _MetaChip(
                                    icon: Icons.done_all_outlined,
                                    label:
                                        '${JobWorkStatus.collected.label}: ${loadSummary.collected}',
                                  ),
                                if (loadSummary.closed > 0)
                                  _MetaChip(
                                    icon: Icons.lock_outline,
                                    label:
                                        '${JobWorkStatus.closed.label}: ${loadSummary.closed}',
                                  ),
                              ],
                            ),
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
                            if (loadSummary.total == 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                AppStrings.noLoadsYet,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                  fontSize: 12,
                                ),
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

class _LoadSummary {
  const _LoadSummary({
    required this.total,
    required this.agreed,
    required this.inCutting,
    required this.atQc,
    required this.ready,
    required this.partiallyCollected,
    required this.collected,
    required this.closed,
  });

  factory _LoadSummary.from(List<JobWorkLoad> loads) {
    final persisted =
        loads.where((load) => !load.isVirtual).toList(growable: false);
    var agreed = 0;
    var inCutting = 0;
    var atQc = 0;
    var ready = 0;
    var partiallyCollected = 0;
    var collected = 0;
    var closed = 0;

    for (final load in persisted) {
      switch (load.status) {
        case JobWorkStatus.received:
        case JobWorkStatus.agreed:
          agreed++;
        case JobWorkStatus.inCutting:
          inCutting++;
        case JobWorkStatus.qc:
          atQc++;
        case JobWorkStatus.ready:
        case JobWorkStatus.invoiced:
        case JobWorkStatus.paid:
          ready++;
        case JobWorkStatus.partiallyCollected:
          partiallyCollected++;
        case JobWorkStatus.collected:
          collected++;
        case JobWorkStatus.closed:
        case JobWorkStatus.cancelled:
          closed++;
      }
    }

    return _LoadSummary(
      total: persisted.length,
      agreed: agreed,
      inCutting: inCutting,
      atQc: atQc,
      ready: ready,
      partiallyCollected: partiallyCollected,
      collected: collected,
      closed: closed,
    );
  }

  final int total;
  final int agreed;
  final int inCutting;
  final int atQc;
  final int ready;
  final int partiallyCollected;
  final int collected;
  final int closed;
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
