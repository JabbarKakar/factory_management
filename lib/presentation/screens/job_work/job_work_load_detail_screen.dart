import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_load_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/job_work_collection_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/compact_status_chip.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/job_work/job_work_block_progress_section.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/job_work_shift_logs_section.dart';
import '../../widgets/job_work/job_work_status_badge.dart';
import '../../widgets/job_work/stock_output_recording_panel.dart';
import '../../widgets/quality/qc_reference_section.dart';

class JobWorkLoadDetailScreen extends StatelessWidget {
  const JobWorkLoadDetailScreen({
    required this.jobWorkId,
    required this.loadId,
    super.key,
  });

  final String jobWorkId;
  final String loadId;

  Future<void> _reload(BuildContext context) async {
    context.read<JobWorkLoadDetailBloc>().add(
          JobWorkLoadDetailStarted(jobWorkId: jobWorkId, loadId: loadId),
        );
  }

  Future<void> _openRecordOutput(BuildContext context) async {
    final saved = await context.push<bool>(
      RoutePaths.jobWorkLoadRecordOutput(
        jobWorkId: jobWorkId,
        loadId: loadId,
      ),
    );
    if (saved == true && context.mounted) await _reload(context);
  }

  Future<void> _openCollectMaterial(BuildContext context) async {
    final saved = await context.push<bool>(
      RoutePaths.jobWorkLoadCollectMaterial(
        jobWorkId: jobWorkId,
        loadId: loadId,
      ),
    );
    if (saved == true && context.mounted) await _reload(context);
  }

  Future<void> _openQc(BuildContext context) async {
    final saved = await context.push<bool>(
      RoutePaths.qualityChecksAddForReference(
        refType: QcReferenceType.jobWorkLoad,
        referenceId: loadId,
      ),
    );
    if (saved == true && context.mounted) await _reload(context);
  }

  Future<void> _closeLoad(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.closeLoadTitle,
      message: AppStrings.closeLoadMessage,
      confirmLabel: AppStrings.closeLoad,
    );
    if (confirmed != true || !context.mounted) return;
    context.read<JobWorkLoadDetailBloc>().add(
          const JobWorkLoadDetailAdvanceCompletionRequested(
            JobWorkStatus.closed,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkLoadDetailBloc, JobWorkLoadDetailState>(
      listener: (context, state) {
        if (state.errorMessage != null &&
            state.status == JobWorkLoadDetailStatus.ready) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkLoadDetailStatus.loading ||
            state.status == JobWorkLoadDetailStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.loadDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.order;
        final load = state.load;
        if (order == null || load == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.loadDetails)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.loadNotFound),
            ),
          );
        }

        final canEdit = context.userCanEdit(AppModule.jobWork);
        final loadCollections =
            JobWorkCollectionQuantityHelper.collectionsForLoad(
          load.id,
          state.collections,
        );
        final totals = JobWorkCollectionQuantityHelper.loadTotals(
          load,
          state.collections,
        );
        final remaining =
            JobWorkCollectionQuantityHelper.remainingLinesForLoad(
          load,
          state.collections,
        );
        final canCollect = canEdit &&
            JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
              load,
              state.collections,
            );
        final hasOutput = load.output?.isRecorded == true;
        // Cutting must start before first Record Output (Agreed → Start Cutting).
        final canRecord = canEdit &&
            !load.isVirtual &&
            load.status.canRecordOutput &&
            (hasOutput || load.status != JobWorkStatus.agreed);
        final canQc = canEdit && !load.isVirtual && hasOutput;
        final nextStatus = load.status.nextOperationalStatus;
        final canAdvance = canEdit &&
            !load.isVirtual &&
            nextStatus != null &&
            (load.status.canAdvanceOperationally ||
                load.status == JobWorkStatus.received) &&
            // Send to QC only after output is recorded.
            (nextStatus != JobWorkStatus.qc || hasOutput);
        final canClose = canEdit &&
            !load.isVirtual &&
            load.status.nextCompletionStatus == JobWorkStatus.closed;
        final overdue = JobWorkCollectionQuantityHelper.isPickupOverdueForLoad(
          load,
          state.collections,
        );
        final isSaving = state.status == JobWorkLoadDetailStatus.saving;
        final loadLabel = load.loadNumber.isEmpty
            ? '${AppStrings.load} #${load.loadSequence}'
            : load.loadNumber;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.loadDetails),
                Text(
                  '$loadLabel · ${order.jobWorkNumber}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color:
                            (Theme.of(context).appBarTheme.foregroundColor ??
                                    Theme.of(context).colorScheme.onSurface)
                                .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            actions: [
              if (canRecord)
                IconButton(
                  onPressed:
                      isSaving ? null : () => _openRecordOutput(context),
                  icon: Icon(
                    hasOutput ? Icons.edit_note : Icons.fact_check_outlined,
                  ),
                  tooltip: hasOutput
                      ? AppStrings.editOutput
                      : AppStrings.recordOutput,
                ),
              if (canCollect)
                IconButton(
                  onPressed:
                      isSaving ? null : () => _openCollectMaterial(context),
                  icon: const Icon(Icons.handshake_outlined),
                  tooltip: AppStrings.collectMaterial,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 28),
            children: [
              _LoadHero(
                load: load,
                loadLabel: loadLabel,
                jobWorkNumber: order.jobWorkNumber,
                isSaving: isSaving,
                canRecordOutput: canRecord,
                hasOutput: hasOutput,
                canCollectMaterial: canCollect,
                canAdvance: canAdvance,
                nextStatus: nextStatus,
                canClose: canClose,
                onRecordOutput: () => _openRecordOutput(context),
                onCollectMaterial: () => _openCollectMaterial(context),
                onAdvanceStatus: (status) {
                  context.read<JobWorkLoadDetailBloc>().add(
                        JobWorkLoadDetailAdvanceStatusRequested(status),
                      );
                },
                onCloseLoad: () => _closeLoad(context),
              ),
              JobWorkDetailSection(
                title: AppStrings.inputMaterial,
                icon: Icons.inventory_2_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.receivedDate,
                      value: DateFormat.yMMMd().format(load.receivedDate),
                    ),
                    if (load.mineLocation != null &&
                        load.mineLocation!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.mineLocation,
                        value: load.mineLocation!,
                      ),
                    if (load.mineOwner != null && load.mineOwner!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.mineOwner,
                        value: load.mineOwner!,
                      ),
                    JobWorkDetailRow(
                      label: AppStrings.marbleVariety,
                      value: load.marbleVariety,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.blocks,
                      value: '${load.blockCount}',
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.totalTons,
                      value: load.totalTons.toStringAsFixed(2),
                    ),
                    if (load.vehicleNumber != null &&
                        load.vehicleNumber!.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.vehicleNumber,
                        value: load.vehicleNumber!,
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.pricingAgreement,
                icon: Icons.payments_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.pricingModel,
                      value: load.pricingModel.label,
                    ),
                    if (load.smallStockPrice > 0)
                      JobWorkDetailRow(
                        label: AppStrings.smallStockPrice,
                        value: Formatters.currencyPkr(load.smallStockPrice),
                      ),
                    if (load.largeStockPrice > 0)
                      JobWorkDetailRow(
                        label: AppStrings.largeStockPrice,
                        value: Formatters.currencyPkr(load.largeStockPrice),
                      ),
                    if (load.agreedRate > 0)
                      JobWorkDetailRow(
                        label: AppStrings.agreedRate,
                        value: Formatters.currencyPkr(load.agreedRate),
                      ),
                    JobWorkDetailRow(
                      label: AppStrings.finalCuttingCharges,
                      value: load.hasFinalCuttingCharges
                          ? Formatters.currencyPkr(load.finalCuttingCharges)
                          : AppStrings.chargesPending,
                      bold: load.hasFinalCuttingCharges,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.advanceReceived,
                      value: Formatters.currencyPkr(load.advanceReceived),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.balanceDue,
                      value: Formatters.currencyPkr(load.balanceDue),
                      bold: load.balanceDue > 0,
                      highlight: load.balanceDue > 0,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.paymentTerms,
                      value: load.paymentTerms.label,
                    ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.cuttingSpecification,
                icon: Icons.content_cut_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.cuttingStrategy,
                      value: load.cuttingStrategy.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.targetProduct,
                      value: load.targetProduct.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.thickness,
                      value: load.thickness,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.finishRequired,
                      value: load.finish.label,
                    ),
                    if (load.smallSizes.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.smallSizes,
                        value: load.smallSizes.join(', '),
                      ),
                    if (load.largeSizes.isNotEmpty)
                      JobWorkDetailRow(
                        label: AppStrings.largeSizes,
                        value: load.largeSizes.join(', '),
                      ),
                  ],
                ),
              ),
              if (load.blockCount > 0)
                JobWorkBlockProgressSection(
                  blockCount: load.blockCount,
                  shiftLogs: load.shiftLogs,
                ),
              JobWorkDetailSection(
                title: AppStrings.recordOutput,
                icon: Icons.analytics_outlined,
                child: hasOutput && load.output != null
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (overdue) ...[
                              const CompactStatusChip(
                                label: AppStrings.pickupOverdue,
                                color: AppColors.overdue,
                              ),
                              const SizedBox(height: 10),
                            ],
                            if (load.output!.hasStockOutputs)
                              StockOutputReadOnlyPanel(
                                smallOutputs: load.output!.smallStockOutputs,
                                largeOutputs: load.output!.largeStockOutputs,
                                remainingPiecesBySize: {
                                  for (final line in remaining)
                                    line.size: line.remainingPieces,
                                },
                                remainingSquareFeetBySize: {
                                  for (final line in remaining)
                                    line.size: line.remainingSquareFeet,
                                },
                              )
                            else
                              JobWorkDetailRows(
                                rows: [
                                  JobWorkDetailRow(
                                    label: AppStrings.totalUsableOutput,
                                    value: load.output!.totalUsableSqFt
                                        .toStringAsFixed(2),
                                    bold: true,
                                  ),
                                  JobWorkDetailRow(
                                    label: AppStrings.piecesRemaining,
                                    value: '${totals.remainingPieces}',
                                  ),
                                  JobWorkDetailRow(
                                    label: AppStrings.squareFeetRemaining,
                                    value: totals.remainingSquareFeet
                                        .toStringAsFixed(2),
                                  ),
                                ],
                              ),
                            JobWorkDetailRows(
                              rows: [
                                JobWorkDetailRow(
                                  label: AppStrings.blocksCut,
                                  value: '${load.totalBlocksCut}',
                                ),
                                JobWorkDetailRow(
                                  label: AppStrings.remainingBlocks,
                                  value: '${load.remainingBlocks}',
                                ),
                              ],
                            ),
                            if (canCollect) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: isSaving
                                    ? null
                                    : () => _openCollectMaterial(context),
                                icon: const Icon(Icons.handshake_outlined),
                                label: const Text(AppStrings.collectMaterial),
                              ),
                            ],
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          AppStrings.outputNotRecordedYet,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
              ),
              if (load.shiftLogs.isNotEmpty)
                JobWorkShiftLogsSection(
                  shiftLogs: load.shiftLogs,
                  totalBlocks: load.blockCount,
                ),
              if (loadCollections.isNotEmpty)
                JobWorkDetailSection(
                  title: AppStrings.collectionHistory,
                  icon: Icons.history_outlined,
                  child: Column(
                    children: [
                      for (final collection in loadCollections)
                        _LoadCollectionRow(
                          collection: collection,
                          onOpenSlip: () => context.push(
                            RoutePaths.jobWorkCollectionSlip(collection.id),
                          ),
                        ),
                    ],
                  ),
                ),
              if (hasOutput)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: QcReferenceSection(
                    checks: state.qualityChecks,
                    onRecordQc: () {
                      if (canQc) _openQc(context);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadHero extends StatelessWidget {
  const _LoadHero({
    required this.load,
    required this.loadLabel,
    required this.jobWorkNumber,
    required this.isSaving,
    required this.canRecordOutput,
    required this.hasOutput,
    required this.canCollectMaterial,
    required this.canAdvance,
    required this.nextStatus,
    required this.canClose,
    required this.onRecordOutput,
    required this.onCollectMaterial,
    required this.onAdvanceStatus,
    required this.onCloseLoad,
  });

  final JobWorkLoad load;
  final String loadLabel;
  final String jobWorkNumber;
  final bool isSaving;
  final bool canRecordOutput;
  final bool hasOutput;
  final bool canCollectMaterial;
  final bool canAdvance;
  final JobWorkStatus? nextStatus;
  final bool canClose;
  final VoidCallback onRecordOutput;
  final VoidCallback onCollectMaterial;
  final ValueChanged<JobWorkStatus> onAdvanceStatus;
  final VoidCallback onCloseLoad;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outline = theme.colorScheme.outline.withValues(alpha: 0.35);
    final hasActions =
        canRecordOutput || canCollectMaterial || canAdvance || canClose;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          border: Border.all(color: outline),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 3, color: theme.colorScheme.primary),
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
                              load.customerName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          JobWorkStatusBadge(
                            status: load.status,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$loadLabel · $jobWorkNumber',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          DateFormat.yMMMd().format(load.receivedDate),
                          '${load.blockCount} ${AppStrings.blocks}',
                          if (load.marbleVariety.isNotEmpty) load.marbleVariety,
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (hasActions) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (canAdvance && nextStatus != null)
                              FilledButton(
                                onPressed: isSaving
                                    ? null
                                    : () => onAdvanceStatus(nextStatus!),
                                child: Text(
                                  load.status.advanceActionLabel,
                                ),
                              ),
                            if (canRecordOutput)
                              FilledButton.tonalIcon(
                                onPressed: isSaving ? null : onRecordOutput,
                                icon: Icon(
                                  hasOutput
                                      ? Icons.edit_note
                                      : Icons.fact_check_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  hasOutput
                                      ? AppStrings.editOutput
                                      : AppStrings.recordOutput,
                                ),
                              ),
                            if (canCollectMaterial)
                              FilledButton.icon(
                                onPressed:
                                    isSaving ? null : onCollectMaterial,
                                icon: const Icon(
                                  Icons.handshake_outlined,
                                  size: 18,
                                ),
                                label: const Text(AppStrings.collectMaterial),
                              ),
                            if (canClose)
                              OutlinedButton(
                                onPressed: isSaving ? null : onCloseLoad,
                                child: const Text(AppStrings.closeLoad),
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
    );
  }
}

class _LoadCollectionRow extends StatelessWidget {
  const _LoadCollectionRow({
    required this.collection,
    required this.onOpenSlip,
  });

  final JobWorkCollection collection;
  final VoidCallback onOpenSlip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final accent = collection.status == JobWorkCollectionStatus.cancelled
        ? AppColors.error
        : AppColors.success;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(Icons.handshake_outlined, color: accent, size: 20),
      title: Text(
        collection.collectionNumber,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
      subtitle: Text(
        '${DateFormat.yMMMd().format(collection.collectedAt)} · '
        '${collection.totalPieces} pcs · '
        '${collection.totalSquareFeet.toStringAsFixed(2)} sq. ft',
        style: theme.textTheme.labelSmall?.copyWith(color: muted),
      ),
      trailing: IconButton(
        onPressed: onOpenSlip,
        icon: const Icon(Icons.receipt_long_outlined, size: 20),
        tooltip: AppStrings.collectionSlip,
      ),
    );
  }
}
