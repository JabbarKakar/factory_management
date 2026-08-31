import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_form_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/job_work_sizes.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/job_work_collection_repository.dart';
import '../../../data/repositories/job_work_load_repository.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/entities/payment.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/job_work_collection_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../../domain/enums/quality_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/compact_status_chip.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/job_work/job_work_detail_hero.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/job_work_invoice_payment_history_section.dart';
import '../../widgets/job_work/job_work_load_list_tile.dart';
import '../../widgets/job_work/job_work_output_summary.dart';
import '../../widgets/job_work/stock_output_recording_panel.dart';
import '../../widgets/quality/qc_reference_section.dart';
import '../../widgets/tile_options_menu.dart';

class JobWorkDetailScreen extends StatefulWidget {
  const JobWorkDetailScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

  @override
  State<JobWorkDetailScreen> createState() => _JobWorkDetailScreenState();
}

class _JobWorkDetailScreenState extends State<JobWorkDetailScreen> {
  String? _busyLoadId;

  String get jobWorkId => widget.jobWorkId;

  Future<void> _openAddLoad(BuildContext context) async {
    final saved = await context.push<bool>(
      RoutePaths.jobWorkAddLoad(jobWorkId),
    );
    if (saved == true && context.mounted) {
      context
          .read<JobWorkFormBloc>()
          .add(JobWorkFormLoadRequested(jobWorkId));
    }
  }

  Future<void> _openEditLoad(BuildContext context, JobWorkLoad load) async {
    if (load.isVirtual) return;
    final saved = await context.push<bool>(
      RoutePaths.jobWorkEditLoad(
        jobWorkId: jobWorkId,
        loadId: load.id,
      ),
    );
    if (saved == true && context.mounted) {
      context
          .read<JobWorkFormBloc>()
          .add(JobWorkFormLoadRequested(jobWorkId));
    }
  }

  Future<void> _confirmDeleteLoad(
    BuildContext context,
    JobWorkLoad load, {
    required bool isLastLoad,
  }) async {
    if (load.isVirtual || _busyLoadId != null) return;
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

    setState(() => _busyLoadId = load.id);
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
        context
            .read<JobWorkFormBloc>()
            .add(JobWorkFormLoadRequested(jobWorkId));
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
        setState(() => _busyLoadId = null);
      }
    }
  }

  List<TileMenuAction> _loadMenuActions(
    BuildContext context,
    JobWorkLoad load, {
    required bool canEdit,
    required bool canDelete,
    required bool isLastLoad,
    required List<JobWorkCollection> collections,
  }) {
    if (load.isVirtual) return const [];

    final actions = <TileMenuAction>[];
    final hasOutput = load.output?.isRecorded == true;
    final canRecord = canEdit &&
        load.status.canRecordOutput &&
        (hasOutput || load.status != JobWorkStatus.agreed);
    final canCollect = canEdit &&
        JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
          load,
          collections,
        );
    final canQc = canEdit && hasOutput;

    if (canEdit) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editLoad,
          icon: Icons.edit_outlined,
          onSelected: () => _openEditLoad(context, load),
        ),
      );
    }
    if (canRecord) {
      actions.add(
        TileMenuAction(
          label: hasOutput ? AppStrings.editOutput : AppStrings.recordOutput,
          icon: Icons.analytics_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.jobWorkLoadRecordOutput(
                jobWorkId: jobWorkId,
                loadId: load.id,
              ),
            );
            if (context.mounted) {
              context
                  .read<JobWorkFormBloc>()
                  .add(JobWorkFormLoadRequested(jobWorkId));
            }
          },
        ),
      );
    }
    if (canCollect) {
      actions.add(
        TileMenuAction(
          label: AppStrings.collectMaterial,
          icon: Icons.handshake_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.jobWorkLoadCollectMaterial(
                jobWorkId: jobWorkId,
                loadId: load.id,
              ),
            );
            if (context.mounted) {
              context
                  .read<JobWorkFormBloc>()
                  .add(JobWorkFormLoadRequested(jobWorkId));
            }
          },
        ),
      );
    }
    if (canQc) {
      actions.add(
        TileMenuAction(
          label: AppStrings.recordQcInspection,
          icon: Icons.verified_outlined,
          onSelected: () async {
            await context.push(
              RoutePaths.qualityChecksAddForReference(
                refType: QcReferenceType.jobWorkLoad,
                referenceId: load.id,
              ),
            );
            if (context.mounted) {
              context
                  .read<JobWorkFormBloc>()
                  .add(JobWorkFormLoadRequested(jobWorkId));
            }
          },
        ),
      );
    }
    if (canDelete) {
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

  Future<void> _openCollectMaterial(BuildContext context) async {
    final saved = await context.push<bool>(
      RoutePaths.jobWorkCollectMaterial(jobWorkId),
    );
    if (saved == true && context.mounted) {
      context
          .read<JobWorkFormBloc>()
          .add(JobWorkFormLoadRequested(jobWorkId));
    }
  }

  Future<void> _openRecordOutput(BuildContext context) async {
    final saved = await context.push<bool>(
      RoutePaths.jobWorkRecordOutput(jobWorkId),
    );
    if (saved == true && context.mounted) {
      context
          .read<JobWorkFormBloc>()
          .add(JobWorkFormLoadRequested(jobWorkId));
    }
  }

  Future<void> _openInvoice(BuildContext context) async {
    await context.push(RoutePaths.jobWorkInvoice(jobWorkId));
    if (context.mounted) {
      context
          .read<JobWorkFormBloc>()
          .add(JobWorkFormLoadRequested(jobWorkId));
    }
  }

  List<Widget> _buildLoadsGroupedByYear(
    BuildContext context, {
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkLoad> allLoads,
    required List<JobWorkInvoice> invoices,
    List<Payment> payments = const [],
    required bool isSaving,
    required bool canEditJobWork,
    required bool canDeleteJobWork,
    required List<JobWorkCollection> collections,
  }) {
    final theme = Theme.of(context);
    final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
      order: order,
      loads: allLoads,
      invoices: invoices,
      payments: payments,
      alreadyScoped: true,
    );
    final byYear = <int, List<JobWorkLoad>>{};
    for (final load in loads) {
      byYear.putIfAbsent(load.receivedDate.year, () => []).add(load);
    }
    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));
    final showYearHeaders = years.length > 1;
    final widgets = <Widget>[];

    for (var yearIndex = 0; yearIndex < years.length; yearIndex++) {
      final year = years[yearIndex];
      final yearLoads = byYear[year]!
        ..sort((a, b) => b.receivedDate.compareTo(a.receivedDate));

      if (showYearHeaders) {
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '$year',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      }

      for (var i = 0; i < yearLoads.length; i++) {
        final load = yearLoads[i];
        final fin = financeMap[load.id];
        widgets.add(
          JobWorkLoadListTile(
            load: load,
            paidAmount: fin?.paid,
            dueAmount: fin?.due,
            creditAmount: fin?.credit,
            isBusy: isSaving || _busyLoadId == load.id,
            padding: EdgeInsets.zero,
            menuActions: _loadMenuActions(
              context,
              load,
              canEdit: canEditJobWork,
              canDelete: canDeleteJobWork,
              isLastLoad: allLoads.length <= 1,
              collections: collections,
            ),
            onTap: load.isVirtual
                ? null
                : () async {
                    await context.push(
                      RoutePaths.jobWorkLoadDetail(
                        jobWorkId: jobWorkId,
                        loadId: load.id,
                      ),
                    );
                    if (context.mounted) {
                      context.read<JobWorkFormBloc>().add(
                            JobWorkFormLoadRequested(jobWorkId),
                          );
                    }
                  },
          ),
        );
        if (i < yearLoads.length - 1) {
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    return widgets;
  }

  Future<void> _openRecordPayment(
    BuildContext context,
    String invoiceId,
  ) async {
    final recorded = await context.push<bool>(
      RoutePaths.recordPayment(invoiceId),
    );
    if (recorded == true && context.mounted) {
      context
          .read<JobWorkFormBloc>()
          .add(JobWorkFormLoadRequested(jobWorkId));
    }
  }

  Future<void> _editPayment(BuildContext context, Payment payment) async {
    final updated = await context.push<bool>(
      RoutePaths.recordPaymentEdit(payment.invoiceId, payment.id),
    );
    if (updated == true && context.mounted) {
      context
          .read<JobWorkFormBloc>()
          .add(JobWorkFormLoadRequested(jobWorkId));
    }
  }

  Future<void> _deletePayment(BuildContext context, Payment payment) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deletePaymentTitle,
      message: AppStrings.deletePaymentMessage,
      confirmLabel: AppStrings.deletePayment,
      destructive: true,
      onConfirm: () async {
        await getIt<PaymentRepository>().deletePayment(payment.id);
      },
    );
    if (!confirmed || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.paymentDeleted)),
    );
    context.read<JobWorkFormBloc>().add(JobWorkFormLoadRequested(jobWorkId));
  }

  void _advanceStatus(BuildContext context, JobWorkStatus nextStatus) {
    context.read<JobWorkFormBloc>().add(
          JobWorkFormStatusAdvanceRequested(
            jobWorkId: jobWorkId,
            newStatus: nextStatus,
          ),
        );
  }

  Future<void> _advanceCompletion(
    BuildContext context,
    JobWorkStatus nextStatus,
  ) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.closeJobWorkTitle,
      message: AppStrings.closeJobWorkMessage,
      confirmLabel: AppStrings.closeJobWorkOrder,
    );
    if (confirmed != true || !context.mounted) return;

    context.read<JobWorkFormBloc>().add(
          JobWorkFormCompletionRequested(
            jobWorkId: jobWorkId,
            newStatus: nextStatus,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkFormBloc, JobWorkFormState>(
      listener: (context, state) {
        if (state.status == JobWorkFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.successMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkFormStatus.loading ||
            state.status == JobWorkFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.jobWorkDetails)),
            body: Center(
              child: Text(state.errorMessage ?? 'Job work order not found'),
            ),
          );
        }

        final canEditJobWork = context.userCanEdit(AppModule.jobWork);
        final canDeleteJobWork = context.userCanDelete(AppModule.jobWork);
        final canEditIntake = canEditJobWork &&
            order.status != JobWorkStatus.cancelled &&
            order.status != JobWorkStatus.closed;
        final hasLoads = state.loads.isNotEmpty;
        final previewLoads = state.loads.take(5).toList();
        final canAddLoad =
            canEditJobWork && order.status != JobWorkStatus.cancelled;
        final usesLegacyJwOps =
            JobWorkContainerSyncHelper.persistedLoadsForOrder(
          order,
          state.loads,
        ).isEmpty;
        final isPickupOverdue = usesLegacyJwOps &&
            JobWorkCollectionQuantityHelper.isPickupOverdue(
              order,
              state.collections,
            );
        final canRecordOutput = usesLegacyJwOps &&
            canEditJobWork &&
            order.status.canRecordOutput &&
            order.status != JobWorkStatus.cancelled;
        final canCollectMaterial = usesLegacyJwOps &&
            canEditJobWork &&
            JobWorkCollectionQuantityHelper.canOpenCollectMaterial(
              order,
              state.collections,
            );
        final invoice = state.invoice;
        final hasInvoice = invoice != null;
        final collectionTotals =
            JobWorkCollectionQuantityHelper.aggregateTotals(
          order: order,
          collections: state.collections,
          loads: state.loads,
        );
        final showCollectionSection = collectionTotals.hasProducedStock ||
            state.collections.isNotEmpty ||
            canCollectMaterial;
        final isSaving = state.status == JobWorkFormStatus.saving;
        final hasOutput = order.output?.isRecorded == true;
        final finance = JobWorkContainerSyncHelper.rollupInvoiceFinance(
          order: order,
          loads: state.loads,
          invoices: state.invoices.isNotEmpty
              ? state.invoices
              : (hasInvoice ? [invoice] : const []),
          payments: state.payments,
          alreadyScoped: true,
        );
        final outstandingBalance = finance.due;
        final canGenerateInvoice =
            JobWorkContainerSyncHelper.canGenerateInvoice(
          order: order,
          loads: state.loads,
        );
        final canCorrectPayments =
            context.userCanEdit(AppModule.jobWork) && state.payments.isNotEmpty;

        final displayStatus = JobWorkCollectionQuantityHelper.displayStatusForOrder(
          order: order,
          loads: state.loads,
        );

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.jobWorkDetails),
                Text(
                  order.jobWorkNumber,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            actions: [
              if (canAddLoad)
                IconButton(
                  onPressed: isSaving ? null : () => _openAddLoad(context),
                  icon: const Icon(Icons.add_box_outlined),
                  tooltip: AppStrings.addLoad,
                ),
              if (canRecordOutput)
                IconButton(
                  onPressed:
                      isSaving ? null : () => _openRecordOutput(context),
                  icon: Icon(
                    hasOutput ? Icons.edit_note : Icons.fact_check_outlined,
                  ),
                  tooltip:
                      hasOutput ? AppStrings.editOutput : AppStrings.recordOutput,
                ),
              if (canEditIntake)
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () => context.push(RoutePaths.jobWorkEdit(order.id)),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editJobWorkOrder,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              JobWorkDetailHero(
                order: order,
                isSaving: isSaving,
                hasOutput: hasOutput,
                canRecordOutput: canRecordOutput,
                canCollectMaterial: canCollectMaterial,
                showOperationalAdvance: usesLegacyJwOps,
                showCompletionAdvance: usesLegacyJwOps,
                hasInvoice: hasInvoice,
                onOpenInvoice: () => _openInvoice(context),
                onAdvanceStatus: (s) => _advanceStatus(context, s),
                onAdvanceCompletion: (s) => _advanceCompletion(context, s),
                onRecordOutput: () => _openRecordOutput(context),
                onCollectMaterial: () => _openCollectMaterial(context),
              ),
              JobWorkDetailSection(
                title: AppStrings.loadsSummary,
                icon: Icons.analytics_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.loads,
                      value: '${state.loads.length}',
                      bold: true,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.activeLoads,
                      value: '${state.activeLoadCount}',
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.completedLoads,
                      value: '${state.completedLoadCount}',
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.totalCuttingCharges,
                      value: Formatters.currencyPkr(finance.charges),
                      bold: true,
                    ),
                    if (outstandingBalance > 0)
                      JobWorkDetailRow(
                        label: AppStrings.outstandingBalance,
                        value: Formatters.currencyPkr(outstandingBalance),
                        bold: true,
                        highlight: true,
                        color: AppColors.warning,
                      )
                    else if (finance.credit > 0)
                      JobWorkDetailRow(
                        label: 'In Credit',
                        value: Formatters.currencyPkr(finance.credit),
                        bold: true,
                        highlight: true,
                        color: AppColors.success,
                      )
                    else
                      JobWorkDetailRow(
                        label: AppStrings.outstandingBalance,
                        value: Formatters.currencyPkr(0),
                      ),
                    if (order.summaryStatus != null)
                      JobWorkDetailRow(
                        label: AppStrings.containerStatus,
                        value: order.summaryStatus!.label,
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: '${AppStrings.allLoads} (${state.loads.length})',
                icon: Icons.local_shipping_outlined,
                action: canAddLoad
                    ? FilledButton.tonalIcon(
                        onPressed:
                            isSaving ? null : () => _openAddLoad(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: const Size(0, 28),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text(
                          AppStrings.addLoad,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (state.loads.isEmpty)
                        Text(
                          AppStrings.noLoadsYet,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        ..._buildLoadsGroupedByYear(
                          context,
                          order: order,
                          loads: previewLoads,
                          allLoads: state.loads,
                          invoices: state.invoices.isNotEmpty
                              ? state.invoices
                              : (hasInvoice ? [invoice] : const []),
                          payments: state.payments,
                          isSaving: isSaving,
                          canEditJobWork: canEditJobWork,
                          canDeleteJobWork: canDeleteJobWork,
                          collections: state.collections,
                        ),
                      if (state.loads.length > 5)
                        Center(
                        child: TextButton(
                          onPressed: () => context.push(
                            RoutePaths.jobWorkAllLoads(jobWorkId),
                          ),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            '${AppStrings.showAllLoads} (${state.loads.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (order.isLoadsAuthoritative && !hasLoads)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: Theme.of(context)
                        .colorScheme
                        .errorContainer
                        .withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.sync_problem_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AppStrings.loadsMigrationIncomplete,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (hasLoads)
                JobWorkDetailSection(
                  title: AppStrings.allLoadsProduction,
                  icon: Icons.analytics_outlined,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Builder(
                      builder: (context) {
                        final produced =
                            JobWorkCollectionQuantityHelper
                                .producedStockAcrossLoads(state.loads);
                        final remainingPiecesBySize =
                            JobWorkCollectionQuantityHelper
                                .remainingPiecesBySizeAcrossLoads(
                          loads: state.loads,
                          collections: state.collections,
                        );
                        final remainingSquareFeetBySize =
                            JobWorkCollectionQuantityHelper
                                .remainingSquareFeetBySizeAcrossLoads(
                          loads: state.loads,
                          collections: state.collections,
                        );
                        final smallOutputs = produced
                            .where((o) => JobWorkSizes.isSmall(o.size))
                            .toList();
                        final largeOutputs = produced
                            .where((o) => !JobWorkSizes.isSmall(o.size))
                            .toList();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (isPickupOverdue) ...[
                              const CompactStatusChip(
                                label: AppStrings.pickupOverdue,
                                color: AppColors.overdue,
                              ),
                              const SizedBox(height: 10),
                            ],
                            StockOutputReadOnlyPanel(
                              smallOutputs: smallOutputs,
                              largeOutputs: largeOutputs,
                              remainingPiecesBySize: remainingPiecesBySize,
                              remainingSquareFeetBySize:
                                  remainingSquareFeetBySize,
                              showCollected: true,
                              sizesInExpansionTile: true,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              if (usesLegacyJwOps) JobWorkOutputSummary(order: order),
              if (usesLegacyJwOps && showCollectionSection)
                JobWorkDetailSection(
                  title: AppStrings.materialCollectionSummary,
                  icon: Icons.inventory_2_outlined,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isPickupOverdue) ...[
                        const CompactStatusChip(
                          label: AppStrings.pickupOverdue,
                          color: AppColors.overdue,
                        ),
                        const SizedBox(height: 10),
                      ],
                      JobWorkDetailRows(
                        rows: [
                          JobWorkDetailRow(
                            label: AppStrings.totalPieces,
                            value: '${collectionTotals.totalPieces}',
                          ),
                          JobWorkDetailRow(
                            label: AppStrings.piecesCollected,
                            value: '${collectionTotals.collectedPieces}',
                          ),
                          JobWorkDetailRow(
                            label: AppStrings.piecesRemaining,
                            value: '${collectionTotals.remainingPieces}',
                            bold: collectionTotals.remainingPieces > 0,
                            highlight: collectionTotals.remainingPieces > 0,
                          ),
                          JobWorkDetailRow(
                            label: AppStrings.totalSquareFeet,
                            value: collectionTotals.totalSquareFeet
                                .toStringAsFixed(2),
                          ),
                          JobWorkDetailRow(
                            label: AppStrings.squareFeetCollected,
                            value: collectionTotals.collectedSquareFeet
                                .toStringAsFixed(2),
                          ),
                          JobWorkDetailRow(
                            label: AppStrings.squareFeetRemaining,
                            value: collectionTotals.remainingSquareFeet
                                .toStringAsFixed(2),
                            bold: collectionTotals.remainingSquareFeet > 0.001,
                            highlight:
                                collectionTotals.remainingSquareFeet > 0.001,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (usesLegacyJwOps && state.collections.isNotEmpty)
                JobWorkDetailSection(
                  title: AppStrings.collectionHistory,
                  icon: Icons.history_outlined,
                  child: Column(
                    children: [
                      for (final collection in state.collections)
                        _CollectionHistoryRow(collection: collection),
                    ],
                  ),
                ),
              if (usesLegacyJwOps && hasOutput)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: QcReferenceSection(
                    checks: state.qualityChecks,
                    onRecordQc: () async {
                      final saved = await context.push<bool>(
                        RoutePaths.qualityChecksAddForReference(
                          refType: QcReferenceType.jobWork,
                          referenceId: order.id,
                        ),
                      );
                      if (saved == true && context.mounted) {
                        context
                            .read<JobWorkFormBloc>()
                            .add(JobWorkFormLoadRequested(jobWorkId));
                      }
                    },
                  ),
                ),
              if (state.payments.isNotEmpty)
                JobWorkInvoicePaymentHistorySection(
                  payments: state.payments,
                  charges: finance.charges,
                  canCorrect: canCorrectPayments,
                  onEdit: canCorrectPayments
                      ? (payment) => _editPayment(context, payment)
                      : null,
                  onDelete: canCorrectPayments
                      ? (payment) => _deletePayment(context, payment)
                      : null,
                ),
              if (canGenerateInvoice &&
                  (order.invoiceId == null || order.invoiceId!.isEmpty))
                _InvoicePromptCard(
                  message: AppStrings.invoiceNotReady,
                  primaryLabel: AppStrings.generateInvoice,
                  primaryIcon: Icons.receipt_long_rounded,
                  onPrimary: () => _openInvoice(context),
                ),
              if (order.invoiceId != null &&
                  order.invoiceId!.isNotEmpty)
                _InvoicePromptCard(
                  showViewInvoice: true,
                  showRecordPayment: (hasInvoice ? invoice.dueAmount > 0 : true) &&
                      displayStatus != JobWorkStatus.paid &&
                      displayStatus != JobWorkStatus.collected &&
                      displayStatus != JobWorkStatus.closed,
                  onViewInvoice: () => _openInvoice(context),
                  onRecordPayment: () =>
                      _openRecordPayment(context, order.invoiceId!),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _InvoicePromptCard extends StatelessWidget {
  const _InvoicePromptCard({
    this.message,
    this.primaryLabel,
    this.primaryIcon,
    this.onPrimary,
    this.showViewInvoice = false,
    this.showRecordPayment = false,
    this.onViewInvoice,
    this.onRecordPayment,
  });

  final String? message;
  final String? primaryLabel;
  final IconData? primaryIcon;
  final VoidCallback? onPrimary;
  final bool showViewInvoice;
  final bool showRecordPayment;
  final VoidCallback? onViewInvoice;
  final VoidCallback? onRecordPayment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.sizeOf(context).width < 600;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (message != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (primaryLabel != null && onPrimary != null)
              FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCompact && primaryIcon != null) ...[
                      Icon(primaryIcon, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      primaryLabel!,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            if (showViewInvoice) ...[
              OutlinedButton(
                onPressed: onViewInvoice,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCompact) ...[
                      const Icon(Icons.receipt_long_outlined, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      AppStrings.viewInvoice,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
            if (showRecordPayment) ...[
              if (showViewInvoice) const SizedBox(height: 6),
              FilledButton(
                onPressed: onRecordPayment,
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCompact) ...[
                      const Icon(Icons.payments_outlined, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      AppStrings.recordPayment,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CollectionHistoryRow extends StatelessWidget {
  const _CollectionHistoryRow({required this.collection});

  final JobWorkCollection collection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final dateLabel = DateFormat.yMMMd().format(collection.collectedAt);
    final accent = collection.status == JobWorkCollectionStatus.cancelled
        ? AppColors.error
        : AppColors.success;

    return Theme(
      data: theme.copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        leading: Icon(Icons.handshake_outlined, size: 20, color: accent),
        title: Row(
          children: [
            Expanded(
              child: Text(
                collection.collectionNumber,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            CompactStatusChip(
              label: collection.status.label,
              color: accent,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              [
                dateLabel,
                if (collection.loadNumber != null &&
                    collection.loadNumber!.isNotEmpty)
                  collection.loadNumber!,
              ].join(' · '),
              style: theme.textTheme.labelSmall?.copyWith(
                color: muted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${collection.totalPieces} pcs · '
              '${collection.totalSquareFeet.toStringAsFixed(2)} sq. ft',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: muted,
              ),
            ),
            if (collection.receiverName != null &&
                collection.receiverName!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                '${AppStrings.receiverName}: ${collection.receiverName}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: muted,
                ),
              ),
            ],
          ],
        ),
        children: [
          for (final item in collection.lineItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.size,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                    ),
                  ),
                  Text(
                    '${item.pieces} pcs · ${item.squareFeet.toStringAsFixed(2)} sq. ft',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: muted,
                    ),
                  ),
                ],
              ),
            ),
          if (collection.notes != null && collection.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                collection.notes!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: muted,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context.push(
                    RoutePaths.jobWorkCollectionSlip(collection.id),
                  ),
                  icon: const Icon(Icons.description_outlined, size: 16),
                  label: const Text(AppStrings.viewCollectionSlip),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  tooltip: 'Actions',
                  onSelected: (value) async {
                    if (value == 'slip') {
                      context.push(
                        RoutePaths.jobWorkCollectionSlip(collection.id),
                      );
                    } else if (value == 'update') {
                      final loadId = collection.loadId;
                      if (loadId != null && loadId.isNotEmpty) {
                        context.push(
                          RoutePaths.jobWorkLoadCollectMaterial(
                            jobWorkId: collection.jobWorkOrderId,
                            loadId: loadId,
                          ),
                        );
                      } else {
                        context.push(
                          RoutePaths.jobWorkCollectMaterial(
                            collection.jobWorkOrderId,
                          ),
                        );
                      }
                    } else if (value == 'cancel') {
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
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.error,
                              ),
                              onPressed: () => Navigator.of(ctx).pop(true),
                              child: const Text('Yes, Cancel'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && context.mounted) {
                        try {
                          await getIt<JobWorkCollectionRepository>()
                              .cancelCollection(collection.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Collection ${collection.collectionNumber} cancelled.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error cancelling collection: $e'),
                              ),
                            );
                          }
                        }
                      }
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
                    if (collection.status != JobWorkCollectionStatus.cancelled)
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
                    if (collection.status != JobWorkCollectionStatus.cancelled)
                      const PopupMenuItem<String>(
                        value: 'cancel',
                        child: Row(
                          children: [
                            Icon(
                              Icons.cancel_outlined,
                              size: 18,
                              color: AppColors.error,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Cancel Collection',
                              style: TextStyle(color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
