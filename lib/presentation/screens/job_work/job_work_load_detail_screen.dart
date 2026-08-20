import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_load_detail_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/job_work_collection_repository.dart';
import '../../../data/repositories/job_work_load_repository.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
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
import '../../widgets/job_work/job_work_invoice_payment_history_section.dart';
import '../../widgets/job_work/job_work_shift_logs_section.dart';
import '../../widgets/job_work/job_work_status_badge.dart';
import '../../widgets/job_work/stock_output_recording_panel.dart';
import '../../widgets/quality/qc_reference_section.dart';
import '../../widgets/tile_options_menu.dart';

class JobWorkLoadDetailScreen extends StatefulWidget {
  const JobWorkLoadDetailScreen({
    required this.jobWorkId,
    required this.loadId,
    super.key,
  });

  final String jobWorkId;
  final String loadId;

  @override
  State<JobWorkLoadDetailScreen> createState() =>
      _JobWorkLoadDetailScreenState();
}

class _JobWorkLoadDetailScreenState extends State<JobWorkLoadDetailScreen> {
  bool _isDeleting = false;

  String get jobWorkId => widget.jobWorkId;
  String get loadId => widget.loadId;

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

  Future<void> _openEditLoad(BuildContext context, JobWorkLoad load) async {
    final saved = await context.push<bool>(
      RoutePaths.jobWorkEditLoad(
        jobWorkId: jobWorkId,
        loadId: load.id,
      ),
    );
    if (saved == true && context.mounted) await _reload(context);
  }

  Future<void> _confirmDeleteLoad(
    BuildContext context,
    JobWorkLoad load, {
    required bool isLastLoad,
  }) async {
    if (_isDeleting) return;
    final confirmed = await AppConfirmDialog.show(
      context,
      title: isLastLoad
          ? AppStrings.deleteLastLoadTitle
          : AppStrings.deleteLoadTitle,
      message: isLastLoad
          ? AppStrings.deleteLastLoadMessage
          : AppStrings.deleteLoadMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      final deletedJobWork =
          await getIt<JobWorkLoadRepository>().deleteLoad(load.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            deletedJobWork
                ? AppStrings.loadAndJobWorkDeleted
                : AppStrings.loadDeleted,
          ),
        ),
      );
      if (deletedJobWork) {
        context.go(RoutePaths.jobWork);
      } else {
        context.pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(AppStrings.loadDeleteError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  List<TileMenuAction> _menuActions(
    BuildContext context, {
    required JobWorkLoad load,
    required bool canEdit,
    required bool canDelete,
    required bool isLastLoad,
    required bool canQc,
    required bool canClose,
  }) {
    final actions = <TileMenuAction>[];
    if (canEdit && !load.isVirtual) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editLoad,
          icon: Icons.edit_outlined,
          onSelected: () => _openEditLoad(context, load),
        ),
      );
    }
    // Record / Collect stay on the hero — avoid duplicating them in ⋮.
    if (canQc) {
      actions.add(
        TileMenuAction(
          label: AppStrings.recordQcInspection,
          icon: Icons.verified_outlined,
          onSelected: () => _openQc(context),
        ),
      );
    }
    if (canClose) {
      actions.add(
        TileMenuAction(
          label: AppStrings.closeLoad,
          icon: Icons.lock_outline,
          onSelected: () => _closeLoad(context),
        ),
      );
    }
    if (canDelete && !load.isVirtual) {
      actions.add(
        TileMenuAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onSelected: () => _confirmDeleteLoad(
            context,
            load,
            isLastLoad: isLastLoad,
          ),
        ),
      );
    }
    return actions;
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
        final canDelete = context.userCanDelete(AppModule.jobWork);
        final isCompact = MediaQuery.sizeOf(context).width < 600;
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
        final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
          order: order,
          loads: state.siblingLoads,
          invoices: state.invoices,
          payments: state.payments,
        );
        final fin = financeMap[load.id] ?? (
          charges: load.finalCuttingCharges,
          paid: load.advanceReceived,
          due: load.balanceDue,
          credit: (load.advanceReceived > load.finalCuttingCharges
              ? load.advanceReceived - load.finalCuttingCharges
              : 0.0),
        );

        final loadLabel = load.loadNumber.isEmpty
            ? '${AppStrings.load} #${load.loadSequence}'
            : load.loadNumber;

        final menuActions = _menuActions(
          context,
          load: load,
          canEdit: canEdit,
          canDelete: canDelete,
          isLastLoad: state.isLastLoad,
          canQc: canQc,
          canClose: canClose,
        );

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
              if (menuActions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TileOptionsButton(
                    isBusy: isSaving || _isDeleting,
                    actions: menuActions,
                  ),
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
                    if (fin.due > 0)
                      JobWorkDetailRow(
                        label: AppStrings.balanceDue,
                        value: Formatters.currencyPkr(fin.due),
                        bold: true,
                        highlight: true,
                        color: AppColors.warning,
                      )
                    else if (fin.credit > 0)
                      JobWorkDetailRow(
                        label: 'In Credit',
                        value: Formatters.currencyPkr(fin.credit),
                        bold: true,
                        highlight: true,
                        color: AppColors.success,
                      )
                    else
                      JobWorkDetailRow(
                        label: AppStrings.balanceDue,
                        value: Formatters.currencyPkr(0),
                      ),
                    JobWorkDetailRow(
                      label: AppStrings.paymentTerms,
                      value: load.paymentTerms.label,
                    ),
                  ],
                ),
              ),
              if (canEdit && (JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(load) ||
                      state.invoice != null || (load.invoiceId != null && load.invoiceId!.isNotEmpty))) ...[
                JobWorkDetailSection(
                  title: AppStrings.jobWorkInvoice,
                  icon: Icons.receipt_long_outlined,
                  action: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.invoice == null && (load.invoiceId == null || load.invoiceId!.isEmpty))
                        FilledButton(
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 7 : 10,
                              vertical: isCompact ? 3 : 4,
                            ),
                            minimumSize: Size(0, isCompact ? 26 : 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: TextStyle(
                              fontSize: isCompact ? 10.5 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  await context.push(
                                    RoutePaths.jobWorkLoadInvoice(
                                      jobWorkId: jobWorkId,
                                      loadId: load.id,
                                    ),
                                  );
                                  if (context.mounted) await _reload(context);
                                },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCompact) ...[
                                const Icon(Icons.receipt_long_outlined, size: 14),
                                const SizedBox(width: 4),
                              ],
                              const Text(AppStrings.generateInvoice),
                            ],
                          ),
                        )
                      else ...[
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 7 : 10,
                              vertical: isCompact ? 3 : 4,
                            ),
                            minimumSize: Size(0, isCompact ? 26 : 30),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: TextStyle(
                              fontSize: isCompact ? 10.5 : 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                                  await context.push(
                                    RoutePaths.jobWorkLoadInvoice(jobWorkId: jobWorkId, loadId: load.id),
                                  );
                                  if (context.mounted) await _reload(context);
                                },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isCompact) ...[
                                const Icon(Icons.receipt_long_outlined, size: 14),
                                const SizedBox(width: 4),
                              ],
                              const Text(AppStrings.viewInvoice),
                            ],
                          ),
                        ),
                        if ((state.invoice?.dueAmount ?? load.balanceDue) > 0) ...[
                          const SizedBox(width: 5),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: isCompact ? 7 : 10,
                                vertical: isCompact ? 3 : 4,
                              ),
                              minimumSize: Size(0, isCompact ? 26 : 30),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: TextStyle(
                                fontSize: isCompact ? 10.5 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: isSaving
                                ? null
                                : () async {
                                    final invoiceId = state.invoice?.id ?? load.invoiceId;
                                    if (invoiceId == null || invoiceId.isEmpty) {
                                      return;
                                    }
                                    await context.push(RoutePaths.recordPayment(invoiceId));
                                    if (context.mounted) {
                                      await _reload(context);
                                    }
                                  },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isCompact) ...[
                                  const Icon(Icons.payments_outlined, size: 14),
                                  const SizedBox(width: 4),
                                ],
                                const Text(AppStrings.recordPayment),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                  child: state.invoice != null
                      ? JobWorkDetailRows(
                          rows: [
                            JobWorkDetailRow(
                              label: AppStrings.invoiceNumber,
                              value: state.invoice!.invoiceNumber,
                              bold: true,
                            ),
                            JobWorkDetailRow(
                              label: AppStrings.totalAmountLabel,
                              value: Formatters.currencyPkr(
                                state.invoice!.totalAmount,
                              ),
                            ),
                            JobWorkDetailRow(
                              label: AppStrings.amountPaid,
                              value: Formatters.currencyPkr(
                                state.invoice!.paidAmount,
                              ),
                            ),
                            JobWorkDetailRow(
                              label: AppStrings.balanceDue,
                              value: Formatters.currencyPkr(
                                state.invoice!.dueAmount,
                              ),
                              bold: state.invoice!.dueAmount > 0,
                              highlight: state.invoice!.dueAmount > 0,
                            ),
                            if (state.invoice!.dueDate != null)
                              JobWorkDetailRow(
                                label: AppStrings.paymentDueDate,
                                value: DateFormat.yMMMd().format(state.invoice!.dueDate!),
                              ),
                          ],
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Text(
                            AppStrings.invoiceNotReady,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                ),
                if (state.invoice != null)
                  JobWorkInvoicePaymentHistorySection(
                    payments: state.payments,
                  ),
              ],
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
                          jobWorkId: jobWorkId,
                          loadId: load.id,
                          canEdit: canEdit,
                          onOpenSlip: () => context.push(
                            RoutePaths.jobWorkCollectionSlip(collection.id),
                          ),
                          onReload: () => _reload(context),
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
    required this.jobWorkId,
    required this.loadId,
    required this.canEdit,
    required this.onOpenSlip,
    required this.onReload,
  });

  final JobWorkCollection collection;
  final String jobWorkId;
  final String loadId;
  final bool canEdit;
  final VoidCallback onOpenSlip;
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isCancelled = collection.status == JobWorkCollectionStatus.cancelled;
    final accent = isCancelled ? AppColors.error : AppColors.success;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      leading: Icon(Icons.handshake_outlined, color: accent, size: 20),
      title: Row(
        children: [
          Expanded(
            child: Text(
              collection.collectionNumber,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                decoration: isCancelled ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isCancelled)
            const CompactStatusChip(
              label: 'Cancelled',
              color: AppColors.error,
            ),
        ],
      ),
      subtitle: Text(
        '${DateFormat.yMMMd().format(collection.collectedAt)} · '
        '${collection.totalPieces} pcs · '
        '${collection.totalSquareFeet.toStringAsFixed(2)} sq. ft',
        style: theme.textTheme.labelSmall?.copyWith(color: muted),
      ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert_rounded, size: 20),
        tooltip: 'Actions',
        onSelected: (value) async {
          if (value == 'slip') {
            onOpenSlip();
          } else if (value == 'update') {
            await context.push(
              RoutePaths.jobWorkLoadCollectMaterial(
                jobWorkId: jobWorkId,
                loadId: loadId,
              ),
            );
            onReload();
          } else if (value == 'cancel') {
            await _confirmAndCancel(context);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'slip',
            child: Row(
              children: [
                Icon(Icons.receipt_long_outlined, size: 18),
                SizedBox(width: 10),
                Text(AppStrings.collectionSlip),
              ],
            ),
          ),
          if (canEdit && !isCancelled)
            const PopupMenuItem<String>(
              value: 'update',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, size: 18),
                  SizedBox(width: 10),
                  Text('Update Collection'),
                ],
              ),
            ),
          if (canEdit && !isCancelled)
            const PopupMenuItem<String>(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                  SizedBox(width: 10),
                  Text('Cancel Collection', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmAndCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Collection'),
        content: Text(
          'Are you sure you want to cancel collection ${collection.collectionNumber}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('No'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await getIt<JobWorkCollectionRepository>().cancelCollection(collection.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Collection ${collection.collectionNumber} cancelled.',
              ),
            ),
          );
          onReload();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error cancelling collection: $e')),
          );
        }
      }
    }
  }
}
