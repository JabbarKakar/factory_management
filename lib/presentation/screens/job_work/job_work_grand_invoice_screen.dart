import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/job_work_collection_repository.dart';
import '../../../data/repositories/job_work_invoice_repository.dart';
import '../../../data/repositories/job_work_load_repository.dart';
import '../../../data/repositories/job_work_repository.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
import '../../../domain/entities/job_work_collection.dart';
import '../../../domain/entities/job_work_invoice.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/job_work_status_badge.dart';

/// Consolidated Job Work invoice view across all Loads (Option A wrap-up).
///
/// Each Load keeps its own invoice document; this screen lists finance +
/// collection progress per Load and totals for the whole Job Work.
class JobWorkGrandInvoiceScreen extends StatefulWidget {
  const JobWorkGrandInvoiceScreen({
    required this.jobWorkId,
    this.generateMissing = false,
    super.key,
  });

  final String jobWorkId;
  final bool generateMissing;

  @override
  State<JobWorkGrandInvoiceScreen> createState() =>
      _JobWorkGrandInvoiceScreenState();
}

class _JobWorkGrandInvoiceScreenState extends State<JobWorkGrandInvoiceScreen> {
  var _loading = true;
  var _generating = false;
  String? _error;
  JobWorkOrder? _order;
  List<JobWorkLoad> _loads = const [];
  List<JobWorkCollection> _collections = const [];
  Map<String, JobWorkInvoice> _invoicesByLoadId = const {};

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.generateMissing) {
        setState(() => _generating = true);
        await getIt<JobWorkInvoiceRepository>()
            .generateMissingInvoicesForJobWork(widget.jobWorkId);
      }
      await _reload();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generating = false;
        _error = error is StateError
            ? error.message
            : AppStrings.grandInvoiceIncomplete;
      });
    }
  }

  Future<void> _reload() async {
    final order =
        await getIt<JobWorkRepository>().getJobWorkOrder(widget.jobWorkId);
    if (order == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _generating = false;
        _error = 'Job work order not found.';
      });
      return;
    }

    final loads = await getIt<JobWorkLoadRepository>().fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: order.id,
    );
    final collections =
        await getIt<JobWorkCollectionRepository>().fetchCollectionsForJobWork(
      factoryId: order.factoryId,
      jobWorkOrderId: order.id,
    );
    final invoices =
        await getIt<JobWorkInvoiceRepository>().getInvoicesByJobWorkId(
      factoryId: order.factoryId,
      jobWorkId: order.id,
    );

    final byLoad = <String, JobWorkInvoice>{};
    for (final invoice in invoices) {
      final loadId = invoice.loadId;
      if (loadId == null || loadId.isEmpty) continue;
      byLoad.putIfAbsent(loadId, () => invoice);
    }

    if (!mounted) return;
    setState(() {
      _order = order;
      _loads = loads.where((load) => !load.isVirtual).toList()
        ..sort((a, b) => a.loadSequence.compareTo(b.loadSequence));
      _collections = collections;
      _invoicesByLoadId = byLoad;
      _loading = false;
      _generating = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(AppStrings.grandInvoiceTitle),
            if (order != null)
              Text(
                order.jobWorkNumber,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: (theme.appBarTheme.foregroundColor ??
                          theme.colorScheme.onSurface)
                      .withValues(alpha: 0.78),
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
      body: _loading || _generating
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  if (_generating) ...[
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.grandInvoiceGenerating,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            )
          : _error != null
              ? EmptyStateView(
                  icon: Icons.receipt_long_outlined,
                  title: _error!,
                  action: FilledButton(
                    onPressed: () => context.pop(),
                    child: const Text(AppStrings.close),
                  ),
                )
              : order == null
                  ? const EmptyStateView(
                      icon: Icons.error_outline,
                      title: 'Job work order not found.',
                    )
                  : _buildBody(context, order),
    );
  }

  Widget _buildBody(BuildContext context, JobWorkOrder order) {
    final billable =
        JobWorkContainerSyncHelper.billableLoadsForGrandInvoice(_loads);
    final displayLoads = billable.isNotEmpty ? billable : _loads;
    final totalCharges =
        JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
      order: order,
      loads: _loads,
    );
    final totalPaid = JobWorkContainerSyncHelper.rollupAdvanceReceived(
      order: order,
      loads: _loads,
    );
    final totalDue = JobWorkContainerSyncHelper.rollupBalanceDue(
      order: order,
      loads: _loads,
    );
    final allTotals = JobWorkCollectionQuantityHelper.aggregateTotals(
      order: order,
      collections: _collections,
      loads: _loads,
    );

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Text(
            AppStrings.grandInvoiceSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            order.customerName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          JobWorkDetailSection(
            title: AppStrings.summary,
            icon: Icons.summarize_outlined,
            child: JobWorkDetailRows(
              rows: [
                JobWorkDetailRow(
                  label: AppStrings.charges,
                  value: Formatters.currencyPkr(totalCharges),
                  bold: true,
                ),
                JobWorkDetailRow(
                  label: AppStrings.amountPaid,
                  value: Formatters.currencyPkr(totalPaid),
                ),
                JobWorkDetailRow(
                  label: AppStrings.balanceDue,
                  value: Formatters.currencyPkr(totalDue),
                  bold: totalDue > 0,
                  highlight: totalDue > 0,
                ),
                JobWorkDetailRow(
                  label: AppStrings.loadCollected,
                  value:
                      '${allTotals.collectedPieces} pcs · ${allTotals.collectedSquareFeet.toStringAsFixed(1)} sq.ft',
                ),
                JobWorkDetailRow(
                  label: AppStrings.loadRemaining,
                  value:
                      '${allTotals.remainingPieces} pcs · ${allTotals.remainingSquareFeet.toStringAsFixed(1)} sq.ft',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (displayLoads.isEmpty)
            const EmptyStateView(
              icon: Icons.inventory_2_outlined,
              title: AppStrings.noLoadsYet,
            )
          else
            for (final load in displayLoads) ...[
              _LoadInvoiceCard(
                load: load,
                invoice: _invoicesByLoadId[load.id],
                collections: _collections,
                canOpenInvoice: context.userCanEdit(AppModule.jobWork) ||
                    context.userCanView(AppModule.jobWork),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ),
    );
  }
}

class _LoadInvoiceCard extends StatelessWidget {
  const _LoadInvoiceCard({
    required this.load,
    required this.invoice,
    required this.collections,
    required this.canOpenInvoice,
  });

  final JobWorkLoad load;
  final JobWorkInvoice? invoice;
  final List<JobWorkCollection> collections;
  final bool canOpenInvoice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totals = JobWorkCollectionQuantityHelper.loadTotals(
      load,
      collections,
    );
    final paid = invoice?.paidAmount ?? load.advanceReceived;
    final due = invoice?.dueAmount ?? load.balanceDue;
    final charges = invoice?.totalAmount ?? load.finalCuttingCharges;

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(
          RoutePaths.jobWorkLoadDetail(
            jobWorkId: load.jobWorkId,
            loadId: load.id,
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        load.loadNumber.isNotEmpty
                            ? load.loadNumber
                            : '${AppStrings.load} ${load.loadSequence}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    JobWorkStatusBadge(status: load.status, compact: true),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label:
                          '${AppStrings.charges}: ${Formatters.currencyPkrWhole(charges)}',
                      color: theme.colorScheme.primary,
                    ),
                    _Chip(
                      label:
                          '${AppStrings.loadPaid}: ${Formatters.currencyPkrWhole(paid)}',
                      color: AppColors.success,
                    ),
                    _Chip(
                      label:
                          '${AppStrings.loadPending}: ${Formatters.currencyPkrWhole(due)}',
                      color:
                          due > 0 ? AppColors.warning : AppColors.success,
                    ),
                    _Chip(
                      label:
                          '${AppStrings.loadCollected}: ${totals.collectedPieces} pcs',
                      color: AppColors.accent,
                    ),
                    _Chip(
                      label:
                          '${AppStrings.loadRemaining}: ${totals.remainingPieces} pcs',
                      color: totals.remainingPieces > 0
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ],
                ),
                if (invoice != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    invoice!.invoiceNumber,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (canOpenInvoice &&
                    invoice != null &&
                    invoice!.id.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => context.push(
                        RoutePaths.jobWorkLoadInvoice(
                          jobWorkId: load.jobWorkId,
                          loadId: load.id,
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 18),
                      label: const Text(AppStrings.openLoadInvoice),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
      ),
    );
  }
}
