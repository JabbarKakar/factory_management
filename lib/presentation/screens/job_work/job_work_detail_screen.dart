import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_form_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/job_work_charges_calculator.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../domain/entities/job_work_collection.dart';
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
import '../../widgets/job_work/job_work_output_summary.dart';
import '../../widgets/job_work/job_work_size_detail_rows.dart';
import '../../widgets/quality/qc_reference_section.dart';

class JobWorkDetailScreen extends StatelessWidget {
  const JobWorkDetailScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

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

        final invoice = state.invoice;
        final hasInvoice = invoice != null;
        final canEditIntake = (order.status == JobWorkStatus.agreed ||
                order.status == JobWorkStatus.received) &&
            context.userCanEdit(AppModule.jobWork);
        final canRecordOutput = order.status.canRecordOutput &&
            context.userCanEdit(AppModule.jobWork);
        final canCollectMaterial =
            context.userCanEdit(AppModule.jobWork) &&
                JobWorkCollectionQuantityHelper.canOpenCollectMaterial(
                  order,
                  state.collections,
                );
        final collectionTotals = JobWorkCollectionQuantityHelper.orderTotals(
          order,
          state.collections,
        );
        final isPickupOverdue =
            JobWorkCollectionQuantityHelper.isPickupOverdue(
          order,
          state.collections,
        );
        final showCollectionSection = collectionTotals.hasProducedStock ||
            state.collections.isNotEmpty ||
            canCollectMaterial;
        final isSaving = state.status == JobWorkFormStatus.saving;
        final hasOutput = order.output?.isRecorded == true;
        final finalCharges =
            JobWorkChargesCalculator.effectiveFinalCuttingCharges(order);
        final balanceDue = hasInvoice
            ? invoice.dueAmount
            : JobWorkChargesCalculator.effectiveBalanceDue(order);
        final amountPaid = hasInvoice
            ? invoice.paidAmount
            : order.advanceReceived;

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
                onAdvanceStatus: (s) => _advanceStatus(context, s),
                onAdvanceCompletion: (s) => _advanceCompletion(context, s),
                onRecordOutput: () => _openRecordOutput(context),
                onCollectMaterial: () => _openCollectMaterial(context),
              ),
              JobWorkOutputSummary(order: order),
              if (showCollectionSection)
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
              if (state.collections.isNotEmpty)
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
              if (hasOutput)
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
              JobWorkDetailSection(
                title: AppStrings.pricingAgreement,
                icon: Icons.payments_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    if (order.smallStockPrice > 0)
                      JobWorkDetailRow(
                        label: AppStrings.smallStockPrice,
                        value: Formatters.currencyPkr(order.smallStockPrice),
                      ),
                    if (order.largeStockPrice > 0)
                      JobWorkDetailRow(
                        label: AppStrings.largeStockPrice,
                        value: Formatters.currencyPkr(order.largeStockPrice),
                      ),
                    if (order.agreedRate > 0)
                      JobWorkDetailRow(
                        label: AppStrings.agreedRate,
                        value: Formatters.currencyPkr(order.agreedRate),
                      ),
                    if (hasInvoice) ...[
                      JobWorkDetailRow(
                        label: AppStrings.invoiceTotal,
                        value: Formatters.currencyPkr(invoice.totalAmount),
                        bold: true,
                        highlight: true,
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.amountPaid,
                        value: Formatters.currencyPkr(amountPaid),
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.balanceDue,
                        value: Formatters.currencyPkr(balanceDue),
                        bold: true,
                        highlight: balanceDue > 0,
                      ),
                    ] else if (finalCharges > 0) ...[
                      JobWorkDetailRow(
                        label: AppStrings.finalCuttingCharges,
                        value: Formatters.currencyPkr(finalCharges),
                        bold: true,
                        highlight: true,
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.advanceReceived,
                        value: Formatters.currencyPkr(order.advanceReceived),
                      ),
                      JobWorkDetailRow(
                        label: AppStrings.balanceDue,
                        value: Formatters.currencyPkr(balanceDue),
                        bold: true,
                        highlight: balanceDue > 0,
                      ),
                    ] else ...[
                      JobWorkDetailRow(
                        label: AppStrings.finalCuttingCharges,
                        value: AppStrings.chargesPending,
                      ),
                      if (order.advanceReceived > 0)
                        JobWorkDetailRow(
                          label: AppStrings.advanceReceived,
                          value: Formatters.currencyPkr(order.advanceReceived),
                        ),
                    ],
                    JobWorkDetailRow(
                      label: AppStrings.paymentTerms,
                      value: order.paymentTerms.label,
                    ),
                    if (order.paymentDueDate != null)
                      JobWorkDetailRow(
                        label: AppStrings.paymentDueDate,
                        value: DateFormat.yMMMd().format(order.paymentDueDate!),
                      ),
                  ],
                ),
              ),
              if (hasInvoice || order.invoiceId != null)
                JobWorkInvoicePaymentHistorySection(
                  payments: state.payments,
                ),
              JobWorkDetailSection(
                title: AppStrings.inputMaterial,
                icon: Icons.inventory_2_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    if (order.mineLocation != null)
                      JobWorkDetailRow(
                        label: AppStrings.mineLocation,
                        value: order.mineLocation!,
                      ),
                    if (order.mineOwner != null)
                      JobWorkDetailRow(
                        label: AppStrings.mineOwner,
                        value: order.mineOwner!,
                      ),
                    JobWorkDetailRow(
                      label: AppStrings.marbleVariety,
                      value: order.marbleVariety,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.blockCount,
                      value: '${order.blockCount}',
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.totalTons,
                      value: order.totalTons.toStringAsFixed(2),
                    ),
                    if (order.totalVolumeM3 != null)
                      JobWorkDetailRow(
                        label: AppStrings.totalVolume,
                        value: order.totalVolumeM3!.toStringAsFixed(2),
                      ),
                    if (order.blockDimensions != null)
                      JobWorkDetailRow(
                        label: AppStrings.blockDimensions,
                        value: order.blockDimensions!,
                      ),
                    if (order.conditionNotes != null)
                      JobWorkDetailRow(
                        label: AppStrings.conditionNotes,
                        value: order.conditionNotes!,
                      ),
                    if (order.vehicleNumber != null)
                      JobWorkDetailRow(
                        label: AppStrings.vehicleNumber,
                        value: order.vehicleNumber!,
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
                      value: order.cuttingStrategy.label,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.targetProduct,
                      value: order.targetProduct.label,
                    ),
                    ...buildJobWorkSizeDetailRows(
                      smallSizes: order.smallSizes,
                      largeSizes: order.largeSizes,
                      legacySizes: order.legacySizes,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.thickness,
                      value: order.thickness,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.finishRequired,
                      value: order.finish.label,
                    ),
                    if (order.specialInstructions != null)
                      JobWorkDetailRow(
                        label: AppStrings.specialInstructions,
                        value: order.specialInstructions!,
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.customerAndDates,
                icon: Icons.calendar_today_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.receivedDate,
                      value: DateFormat.yMMMd().format(order.receivedDate),
                    ),
                    if (order.expectedCompletionDate != null)
                      JobWorkDetailRow(
                        label: AppStrings.expectedCompletion,
                        value: DateFormat.yMMMd()
                            .format(order.expectedCompletionDate!),
                      ),
                    if (order.collectedAt != null)
                      JobWorkDetailRow(
                        label: AppStrings.collectedDate,
                        value: DateFormat.yMMMd().format(order.collectedAt!),
                      ),
                    if (order.closedAt != null)
                      JobWorkDetailRow(
                        label: AppStrings.closedDate,
                        value: DateFormat.yMMMd().format(order.closedAt!),
                      ),
                  ],
                ),
              ),
              if ((order.status == JobWorkStatus.ready ||
                      order.status == JobWorkStatus.partiallyCollected) &&
                  (order.invoiceId == null || order.invoiceId!.isEmpty))
                _InvoicePromptCard(
                  message: AppStrings.invoiceNotReady,
                  primaryLabel: AppStrings.generateInvoice,
                  primaryIcon: Icons.receipt_long_rounded,
                  onPrimary: () => _openInvoice(context),
                ),
              if (order.invoiceId != null && order.invoiceId!.isNotEmpty)
                _InvoicePromptCard(
                  showViewInvoice: true,
                  showRecordPayment: (hasInvoice ? invoice.dueAmount > 0 : true) &&
                      order.status != JobWorkStatus.paid &&
                      order.status != JobWorkStatus.collected &&
                      order.status != JobWorkStatus.closed,
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
              FilledButton.icon(
                onPressed: onPrimary,
                icon: Icon(primaryIcon, size: 16),
                label: Text(
                  primaryLabel!,
                  style: const TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            if (showViewInvoice) ...[
              OutlinedButton.icon(
                onPressed: onViewInvoice,
                icon: const Icon(Icons.receipt_long_outlined, size: 16),
                label: Text(
                  AppStrings.viewInvoice,
                  style: const TextStyle(fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ],
            if (showRecordPayment) ...[
              const SizedBox(height: 6),
              FilledButton.icon(
                onPressed: onRecordPayment,
                icon: const Icon(Icons.payments_outlined, size: 16),
                label: Text(
                  AppStrings.recordPayment,
                  style: const TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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
              dateLabel,
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
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
          ),
        ],
      ),
    );
  }
}
