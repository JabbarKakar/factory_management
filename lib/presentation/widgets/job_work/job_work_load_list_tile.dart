import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../tile_options_menu.dart';
import 'job_work_status_badge.dart';

/// Load row for the Job Work Loads Summary — matches [JobWorkListTile] card UI.
class JobWorkLoadListTile extends StatelessWidget {
  const JobWorkLoadListTile({
    required this.load,
    this.paidAmount,
    this.dueAmount,
    this.onTap,
    this.menuActions = const [],
    this.isBusy = false,
    super.key,
  });

  final JobWorkLoad load;
  final double? paidAmount;
  final double? dueAmount;
  final VoidCallback? onTap;
  final List<TileMenuAction> menuActions;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = _accentFor(load.status);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    const cardRadius = Radius.circular(14);
    const cardShape = BorderRadius.only(
      topRight: cardRadius,
      bottomRight: cardRadius,
    );
    final isMuted = load.status.isListMuted;
    final loadLabel = load.loadNumber.isEmpty
        ? '${AppStrings.load} #${load.loadSequence}'
        : load.loadNumber;
    final dateLabel = DateFormat.yMMMd().format(load.receivedDate);
    final hasBlocksProgress =
        load.shiftLogs.isNotEmpty && load.blockCount > 0;
    final hasOutput = load.output?.isRecorded == true;
    final totalCharges = load.finalCuttingCharges;
    final paid = paidAmount ?? load.advanceReceived;
    final due = dueAmount ?? load.balanceDue;

    return Opacity(
      opacity: isMuted ? 0.72 : 1,
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
                        menuActions.isNotEmpty ? 2 : 8,
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
                                  loadLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              JobWorkStatusBadge(
                                status: load.status,
                                compact: true,
                              ),
                              if (menuActions.isNotEmpty)
                                TileOptionsButton(
                                  isBusy: isBusy,
                                  actions: menuActions,
                                )
                              else if (onTap != null) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right,
                                  size: 20,
                                  color: muted.withValues(alpha: 0.7),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel,
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
                              if (load.mineLocation != null &&
                                  load.mineLocation!.isNotEmpty)
                                _MetaChip(
                                  icon: Icons.place_outlined,
                                  label: load.mineLocation!,
                                ),
                              if (load.marbleVariety.isNotEmpty)
                                _MetaChip(
                                  icon: Icons.layers_outlined,
                                  label: load.marbleVariety,
                                ),
                              _MetaChip(
                                icon: Icons.view_module_outlined,
                                label:
                                    '${load.blockCount} ${AppStrings.blocks}',
                              ),
                              if (load.totalTons > 0)
                                _MetaChip(
                                  icon: Icons.scale_outlined,
                                  label:
                                      '${load.totalTons.toStringAsFixed(2)}t',
                                ),
                            ],
                          ),
                          if (load.hasFinalCuttingCharges) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme
                                    .colorScheme.surfaceContainerHighest
                                    .withValues(alpha: isDark ? 0.35 : 0.45),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Total: ',
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            color: muted,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          Formatters.currencyPkrWhole(
                                            totalCharges,
                                          ),
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: theme.colorScheme.outline
                                        .withValues(alpha: 0.2),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Paid: ',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: muted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            Formatters.currencyPkrWhole(paid),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: paid > 0
                                                  ? AppColors.success
                                                  : muted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 14,
                                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Remaining: ',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              color: muted,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            Formatters.currencyPkrWhole(due),
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: due > 0
                                                  ? AppColors.warning
                                                  : AppColors.success,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme
                                    .colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.pending_actions_outlined,
                                    size: 13,
                                    color: muted,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    AppStrings.chargesPending,
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: muted,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (hasBlocksProgress || hasOutput) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                if (hasBlocksProgress)
                                  Expanded(
                                    child: _SummaryStrip(
                                      label:
                                          '${load.totalBlocksCut}/${load.blockCount} '
                                          '${AppStrings.blocksCutLabel} · '
                                          '${load.blockCompletionPercent.toStringAsFixed(0)}%',
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                if (hasBlocksProgress && hasOutput)
                                  const SizedBox(width: 6),
                                if (hasOutput)
                                  Expanded(
                                    child: _SummaryStrip(
                                      label:
                                          '${load.output!.totalUsableSqFt.toStringAsFixed(0)} sq. ft',
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          if (load.isVirtual || load.migratedFromJobWork) ...[
                            const SizedBox(height: 6),
                            Text(
                              load.isVirtual
                                  ? AppStrings.virtualLoadHint
                                  : AppStrings.migratedLoadHint,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted,
                                fontSize: 10,
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
    final muted = theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: muted),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
