import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_list_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/job_work_repository.dart';
import '../../../data/services/job_work_collection_quantity_helper.dart';
import '../../../data/services/job_work_container_sync_helper.dart';
import '../../../data/services/job_work_load_production_helper.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_list_tile.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/job_work/job_work_stage_filter_bar.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/tile_options_menu.dart';

class JobWorkListScreen extends StatefulWidget {
  const JobWorkListScreen({super.key});

  @override
  State<JobWorkListScreen> createState() => _JobWorkListScreenState();
}

class _JobWorkListScreenState extends State<JobWorkListScreen> {
  final _searchController = TextEditingController();
  String? _busyJobWorkId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context.read<JobWorkListBloc>().add(const JobWorkListSearchChanged(''));
  }

  Future<void> _pickDateRange(
    BuildContext context,
    JobWorkListState state,
  ) async {
    final now = DateTime.now();
    final initialStart = state.fromDate ?? now.subtract(const Duration(days: 30));
    final initialEnd = state.toDate ?? now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: AppStrings.filterByReceivedDate,
    );
    if (range == null || !context.mounted) return;
    context.read<JobWorkListBloc>().add(
          JobWorkListDateRangeChanged(
            fromDate: range.start,
            toDate: range.end,
          ),
        );
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  Future<void> _confirmDelete(JobWorkOrder order) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteJobWorkTitle,
      message: AppStrings.deleteJobWorkMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyJobWorkId = order.id);

    try {
      await getIt<JobWorkRepository>().deleteJobWorkOrder(order.id);
      if (!mounted) return;
      _showSnack(AppStrings.jobWorkDeleted);
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.jobWorkDeleteError, isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyJobWorkId = null);
      }
    }
  }

  Future<void> _confirmCancel(JobWorkOrder order) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.cancelJobWorkTitle,
      message: AppStrings.cancelJobWorkMessage,
      confirmLabel: AppStrings.cancelOrder,
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busyJobWorkId = order.id);

    try {
      await getIt<JobWorkRepository>().cancelJobWorkOrder(order.id);
      if (!mounted) return;
      _showSnack(AppStrings.jobWorkCancelled);
    } catch (_) {
      if (!mounted) return;
      _showSnack(AppStrings.jobWorkCancelError, isError: true);
    } finally {
      if (mounted) {
        setState(() => _busyJobWorkId = null);
      }
    }
  }

  List<TileMenuAction> _menuActionsFor(
    JobWorkOrder order, {
    required bool canEdit,
    required bool canDelete,
    required List<JobWorkLoad> loads,
  }) {
    final displayStatus = JobWorkCollectionQuantityHelper.displayStatusForOrder(
      order: order,
      loads: loads,
    );
    final hasInvoice = order.invoiceId != null && order.invoiceId!.isNotEmpty;
    final actions = <TileMenuAction>[];
    final recordLoad =
        JobWorkLoadProductionHelper.preferredLoadForRecordOutput(loads);
    final canRecordOutput = JobWorkLoadProductionHelper.orderCanRecordOutput(
      order: order,
      loads: loads,
    );

    if (canEdit &&
        (displayStatus == JobWorkStatus.received ||
            displayStatus == JobWorkStatus.agreed)) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editJobWorkOrder,
          icon: Icons.edit_outlined,
          onSelected: () => context.push(RoutePaths.jobWorkEdit(order.id)),
        ),
      );
    }

    if (canEdit && canRecordOutput) {
      final hasRecordedOutput = recordLoad != null
          ? recordLoad.output?.isRecorded == true
          : order.output?.isRecorded == true;
      actions.add(
        TileMenuAction(
          label: hasRecordedOutput
              ? AppStrings.editOutput
              : AppStrings.recordOutput,
          icon: Icons.analytics_outlined,
          onSelected: () {
            if (recordLoad != null) {
              context.push(
                RoutePaths.jobWorkLoadRecordOutput(
                  jobWorkId: order.id,
                  loadId: recordLoad.id,
                ),
              );
            } else {
              context.push(RoutePaths.jobWorkRecordOutput(order.id));
            }
          },
        ),
      );
    }

    final invoicableLoads = loads
        .where(
          (load) =>
              !load.isVirtual &&
              JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(load) &&
              (load.invoiceId == null || load.invoiceId!.isEmpty),
        )
        .toList();
    final loadsWithInvoice = loads
        .where(
          (load) =>
              !load.isVirtual &&
              load.invoiceId != null &&
              load.invoiceId!.isNotEmpty,
        )
        .toList();

    if (invoicableLoads.length == 1) {
      final load = invoicableLoads.first;
      actions.add(
        TileMenuAction(
          label: AppStrings.generateInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () => context.push(
            RoutePaths.jobWorkLoadInvoice(
              jobWorkId: order.id,
              loadId: load.id,
            ),
          ),
        ),
      );
    } else if (invoicableLoads.isEmpty &&
        !hasInvoice &&
        loads.isEmpty &&
        order.defaultLoadId != null &&
        order.defaultLoadId!.isNotEmpty &&
        JobWorkContainerSyncHelper.canGenerateInvoice(
          order: order,
          loads: loads,
        )) {
      actions.add(
        TileMenuAction(
          label: AppStrings.generateInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () => context.push(
            RoutePaths.jobWorkLoadInvoice(
              jobWorkId: order.id,
              loadId: order.defaultLoadId!,
            ),
          ),
        ),
      );
    } else if (invoicableLoads.isEmpty &&
        !hasInvoice &&
        loads.isEmpty &&
        !order.isLoadsAuthoritative &&
        JobWorkContainerSyncHelper.canGenerateInvoice(
          order: order,
          loads: loads,
        )) {
      actions.add(
        TileMenuAction(
          label: AppStrings.generateInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () => context.push(RoutePaths.jobWorkDetail(order.id)),
        ),
      );
    }

    if (loadsWithInvoice.length == 1) {
      final load = loadsWithInvoice.first;
      actions.add(
        TileMenuAction(
          label: AppStrings.viewInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () => context.push(
            RoutePaths.jobWorkLoadInvoice(
              jobWorkId: order.id,
              loadId: load.id,
            ),
          ),
        ),
      );
      if (load.balanceDue > 0) {
        actions.add(
          TileMenuAction(
            label: AppStrings.recordPayment,
            icon: Icons.payments_outlined,
            onSelected: () =>
                context.push(RoutePaths.recordPayment(load.invoiceId!)),
          ),
        );
      }
    } else if (hasInvoice && loadsWithInvoice.isEmpty) {
      final legacyLoadId = order.defaultLoadId;
      actions.add(
        TileMenuAction(
          label: AppStrings.viewInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () {
            if (legacyLoadId != null && legacyLoadId.isNotEmpty) {
              context.push(
                RoutePaths.jobWorkLoadInvoice(
                  jobWorkId: order.id,
                  loadId: legacyLoadId,
                ),
              );
            } else {
              context.push(RoutePaths.jobWorkDetail(order.id));
            }
          },
        ),
      );
      if (displayStatus != JobWorkStatus.paid &&
          displayStatus != JobWorkStatus.collected &&
          displayStatus != JobWorkStatus.closed) {
        actions.add(
          TileMenuAction(
            label: AppStrings.recordPayment,
            icon: Icons.payments_outlined,
            onSelected: () =>
                context.push(RoutePaths.recordPayment(order.invoiceId!)),
          ),
        );
      }
    } else if (loadsWithInvoice.length > 1 || invoicableLoads.length > 1) {
      actions.add(
        TileMenuAction(
          label: AppStrings.viewInvoice,
          icon: Icons.receipt_long_outlined,
          onSelected: () =>
              context.push(RoutePaths.jobWorkDetail(order.id)),
        ),
      );
    }

    if (canEdit && displayStatus.isInProduction) {
      actions.add(
        TileMenuAction(
          label: AppStrings.cancelOrder,
          icon: Icons.cancel_outlined,
          onSelected: () => _confirmCancel(order),
        ),
      );
    }

    if (canDelete) {
      actions.add(
        TileMenuAction(
          label: AppStrings.delete,
          icon: Icons.delete_outline_rounded,
          destructive: true,
          onSelected: () => _confirmDelete(order),
        ),
      );
    }

    return actions;
  }

  ({double paid, double remaining})? _paymentSummaryFor(
    JobWorkOrder order,
    JobWorkListState state,
    List<JobWorkLoad> loads,
  ) {
    final charges = JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
      order: order,
      loads: loads,
    );
    final advance = JobWorkContainerSyncHelper.rollupAdvanceReceived(
      order: order,
      loads: loads,
    );
    final balance = JobWorkContainerSyncHelper.rollupBalanceDue(
      order: order,
      loads: loads,
    );

    final persistedLoads = loads.where((load) => !load.isVirtual).toList();
    if (persistedLoads.isNotEmpty) {
      if (charges <= 0 && advance <= 0 && balance <= 0) return null;
      return (paid: advance, remaining: balance);
    }

    final invoice = state.invoicesByJobWorkId[order.id];
    final showPayment = invoice != null || charges > 0 || advance > 0;
    if (!showPayment) return null;

    return (
      paid: invoice?.paidAmount ?? advance,
      remaining: invoice?.dueAmount ?? balance,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.userCanEdit(AppModule.jobWork);
    final canDelete = context.userCanDelete(AppModule.jobWork);

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<JobWorkListBloc, JobWorkListState>(
          buildWhen: (prev, curr) =>
              prev.visibleOrders.length != curr.visibleOrders.length ||
              prev.stageFilter != curr.stageFilter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.jobWork),
                Text(
                  '${state.visibleOrders.length} orders'
                  '${state.stageFilter != JobWorkListStageFilter.all ? ' · ${state.stageFilter.label}' : ''}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appBarForeground.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            );
          },
        ),
        actions: const [
          NotificationBell(),
          AccountMenuButton(),
        ],
      ),
      floatingActionButton: context.userCanCreate(AppModule.jobWork)
          ? AppExtendedFab(
              heroTag: 'fab-job-work',
              onPressed: () => context.push(RoutePaths.jobWorkAdd),
              icon: Icons.work_outline,
              label: AppStrings.newJobWorkOrder,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: JobWorkSearchBar(
                    controller: _searchController,
                    onChanged: (value) => context
                        .read<JobWorkListBloc>()
                        .add(JobWorkListSearchChanged(value)),
                    onClear: _onSearchClear,
                  ),
                ),
                const SizedBox(width: 8),
                BlocBuilder<JobWorkListBloc, JobWorkListState>(
                  buildWhen: (prev, curr) =>
                      prev.fromDate != curr.fromDate ||
                      prev.toDate != curr.toDate,
                  builder: (context, state) {
                    return IconButton.filledTonal(
                      tooltip: AppStrings.filterByReceivedDate,
                      onPressed: () => _pickDateRange(context, state),
                      icon: Icon(
                        state.hasDateFilter
                            ? Icons.date_range
                            : Icons.calendar_month_outlined,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          BlocBuilder<JobWorkListBloc, JobWorkListState>(
            buildWhen: (prev, curr) =>
                prev.fromDate != curr.fromDate || prev.toDate != curr.toDate,
            builder: (context, state) {
              if (!state.hasDateFilter) return const SizedBox.shrink();
              final fromLabel = state.fromDate != null
                  ? DateFormat.yMMMd().format(state.fromDate!)
                  : '…';
              final toLabel = state.toDate != null
                  ? DateFormat.yMMMd().format(state.toDate!)
                  : '…';
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    avatar: const Icon(Icons.date_range, size: 16),
                    label: Text('$fromLabel – $toLabel'),
                    onDeleted: () => context.read<JobWorkListBloc>().add(
                          const JobWorkListDateRangeChanged(),
                        ),
                    deleteButtonTooltipMessage: AppStrings.clearDateFilter,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<JobWorkListBloc, JobWorkListState>(
              buildWhen: (prev, curr) => prev.stageFilter != curr.stageFilter,
              builder: (context, state) {
                return JobWorkStageFilterBar(
                  selected: state.stageFilter,
                  onChanged: (filter) => context.read<JobWorkListBloc>().add(
                        JobWorkListStageFilterChanged(filter),
                      ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          BlocBuilder<JobWorkListBloc, JobWorkListState>(
            buildWhen: (prev, curr) =>
                prev.awaitingQcCount != curr.awaitingQcCount,
            builder: (context, state) {
              if (state.awaitingQcCount == 0) {
                return const SizedBox.shrink();
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DashboardSurfaceCard(
                  compact: true,
                  borderRadius: 12,
                  padding: EdgeInsets.zero,
                  onTap: () {
                    context.read<JobWorkListBloc>().add(
                          const JobWorkListStageFilterChanged(
                            JobWorkListStageFilter.atQc,
                          ),
                        );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.fact_check_outlined,
                            color: AppColors.warning,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${state.awaitingQcCount} ${AppStrings.jobWorkAwaitingQc}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Expanded(
            child: BlocBuilder<JobWorkListBloc, JobWorkListState>(
              builder: (context, state) {
                if (state.status == JobWorkListStatus.loading &&
                    state.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == JobWorkListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.jobWorkLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<JobWorkListBloc>().add(
                                JobWorkListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleOrders.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.content_cut,
                    title: state.searchQuery.isNotEmpty ||
                            state.stageFilter != JobWorkListStageFilter.all ||
                            state.hasDateFilter
                        ? AppStrings.noJobWorkFound
                        : AppStrings.noJobWorkYet,
                    subtitle: state.searchQuery.isNotEmpty || state.hasDateFilter
                        ? AppStrings.tryDifferentSearch
                        : AppStrings.addFirstJobWork,
                    action: state.searchQuery.isEmpty &&
                            state.stageFilter == JobWorkListStageFilter.all &&
                            !state.hasDateFilter &&
                            context.userCanCreate(AppModule.jobWork)
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.jobWorkAdd),
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.newJobWorkOrder),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<JobWorkListBloc>().add(
                          JobWorkListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: state.visibleOrders.length,
                    itemBuilder: (context, index) {
                      final order = state.visibleOrders[index];
                      final orderLoads = state.loadsForOrder(order.id);
                      final paymentSummary =
                          _paymentSummaryFor(order, state, orderLoads);
                      final displayStatus =
                          JobWorkCollectionQuantityHelper.displayStatusForOrder(
                        order: order,
                        loads: orderLoads,
                      );
                      return JobWorkListTile(
                        order: order,
                        loads: orderLoads,
                        displayStatus: displayStatus,
                        isBusy: _busyJobWorkId == order.id,
                        paidAmount: paymentSummary?.paid,
                        remainingAmount: paymentSummary?.remaining,
                        menuActions: _menuActionsFor(
                          order,
                          canEdit: canEdit,
                          canDelete: canDelete,
                          loads: orderLoads,
                        ),
                        onTap: () => context.push(
                          RoutePaths.jobWorkDetail(order.id),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
