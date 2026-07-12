import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/job_work_enums.dart';
import 'job_work_status_badge.dart';

class JobWorkDetailHero extends StatelessWidget {
  const JobWorkDetailHero({
    required this.order,
    required this.isSaving,
    required this.hasOutput,
    required this.canRecordOutput,
    required this.onAdvanceStatus,
    required this.onAdvanceCompletion,
    required this.onRecordOutput,
    this.canCollectMaterial = false,
    this.onCollectMaterial,
    this.showOperationalAdvance = true,
    this.showCompletionAdvance = true,
    super.key,
  });

  final JobWorkOrder order;
  final bool isSaving;
  final bool hasOutput;
  final bool canRecordOutput;
  final bool canCollectMaterial;
  final bool showOperationalAdvance;
  final bool showCompletionAdvance;
  final ValueChanged<JobWorkStatus> onAdvanceStatus;
  final ValueChanged<JobWorkStatus> onAdvanceCompletion;
  final VoidCallback onRecordOutput;
  final VoidCallback? onCollectMaterial;

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
    final nextStatus = order.status.nextOperationalStatus;
    final nextCompletionStatus = order.status.nextCompletionStatus;
    final showCloseOrder = showCompletionAdvance &&
        nextCompletionStatus == JobWorkStatus.closed;
    final showAdvance = showOperationalAdvance &&
        order.status.canAdvanceOperationally &&
        nextStatus != null;
    final hasActions = showAdvance ||
        showCloseOrder ||
        canCollectMaterial ||
        canRecordOutput;

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
                      if (hasActions) ...[
                        const SizedBox(height: 10),
                        Divider(
                          height: 1,
                          color: outline.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 10),
                        if (showAdvance)
                          _ActionButton(
                            label: order.status.advanceActionLabel,
                            filled: false,
                            onPressed: isSaving
                                ? null
                                : () => onAdvanceStatus(nextStatus),
                          ),
                        if (canCollectMaterial) ...[
                          if (showAdvance) const SizedBox(height: 6),
                          _ActionButton(
                            label: AppStrings.collectMaterial,
                            filled: true,
                            icon: Icons.handshake_outlined,
                            onPressed: isSaving ? null : onCollectMaterial,
                          ),
                        ],
                        if (showCloseOrder) ...[
                          if (showAdvance || canCollectMaterial)
                            const SizedBox(height: 6),
                          _ActionButton(
                            label: AppStrings.closeJobWorkOrder,
                            filled: true,
                            onPressed: isSaving
                                ? null
                                : () =>
                                    onAdvanceCompletion(JobWorkStatus.closed),
                          ),
                        ],
                        if (canRecordOutput) ...[
                          const SizedBox(height: 6),
                          _ActionButton(
                            label: hasOutput
                                ? AppStrings.editOutput
                                : AppStrings.recordOutput,
                            filled: false,
                            outlined: true,
                            icon: hasOutput
                                ? Icons.edit_note_outlined
                                : Icons.fact_check_outlined,
                            onPressed: isSaving ? null : onRecordOutput,
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
    final style = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
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
