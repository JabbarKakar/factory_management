import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/job_work_enums.dart';
import 'job_work_status_badge.dart';

class JobWorkTileMenuAction {
  const JobWorkTileMenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
}

class JobWorkListTile extends StatelessWidget {
  const JobWorkListTile({
    required this.order,
    required this.onTap,
    this.menuActions = const [],
    this.isBusy = false,
    this.awaitingQcInspection = false,
    super.key,
  });

  final JobWorkOrder order;
  final VoidCallback onTap;
  final List<JobWorkTileMenuAction> menuActions;
  final bool isBusy;
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
    final hasBlocksStrip =
        order.shiftLogs.isNotEmpty && order.blockCount > 0;
    final hasOutputStrip = order.output?.isRecorded == true;

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
                                  status: order.status,
                                  compact: true,
                                ),
                                if (menuActions.isNotEmpty)
                                  _TileOptionsButton(
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
                                    order.hasFinalCuttingCharges
                                        ? Formatters.currencyPkrWhole(
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
                                            '${order.output!.totalUsableSqFt.toStringAsFixed(0)} sq. ft',
                                        color: theme.colorScheme.primary,
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

class _TileOptionsButton extends StatelessWidget {
  const _TileOptionsButton({
    required this.isBusy,
    required this.actions,
  });

  final bool isBusy;
  final List<JobWorkTileMenuAction> actions;

  Future<void> _openMenu(BuildContext context) async {
    final theme = Theme.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenSize = MediaQuery.sizeOf(context);

    const menuWidth = 168.0;
    var left = offset.dx + size.width - menuWidth;
    final top = offset.dy + size.height + 1;
    left = left.clamp(8.0, screenSize.width - menuWidth - 8.0);

    final selected = await showGeneralDialog<JobWorkTileMenuAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Actions',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final rows = <Widget>[];
        for (final action in actions) {
          if (action.destructive && rows.isNotEmpty) {
            rows.add(
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.18),
              ),
            );
          }
          final color = action.destructive
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface;
          rows.add(
            InkWell(
              onTap: () => Navigator.of(dialogContext).pop(action),
              child: SizedBox(
                width: menuWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Icon(action.icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.1,
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

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                elevation: 2,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: rows,
                ),
              ),
            ),
          ],
        );
      },
    );

    selected?.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (isBusy) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iconColor,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _openMenu(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: iconColor,
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
