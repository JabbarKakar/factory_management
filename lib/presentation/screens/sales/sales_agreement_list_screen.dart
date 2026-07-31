import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_agreement_list_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/sales_agreement.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/sales_agreement_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/auth_context.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/account_menu_button.dart';
import '../../widgets/app_extended_fab.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/job_work/job_work_finance_overview_bar.dart';
import '../../widgets/job_work/job_work_search_bar.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/sales/sales_agreement_list_tile.dart';
import '../../widgets/tile_options_menu.dart';

class SalesAgreementListScreen extends StatefulWidget {
  const SalesAgreementListScreen({super.key});

  @override
  State<SalesAgreementListScreen> createState() =>
      _SalesAgreementListScreenState();
}

class _SalesAgreementListScreenState extends State<SalesAgreementListScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchClear() {
    _searchController.clear();
    context
        .read<SalesAgreementListBloc>()
        .add(const SalesAgreementListSearchChanged(''));
  }

  ({double invoiced, double received, double pending}) _financeOverviewFor(
    SalesAgreementListState state,
  ) {
    var invoiced = 0.0;
    var received = 0.0;
    var pending = 0.0;
    for (final agreement in state.visibleAgreements) {
      final finance = state.financeFor(agreement);
      invoiced += finance.charges;
      received += finance.paid;
      pending += finance.due;
    }
    return (invoiced: invoiced, received: received, pending: pending);
  }

  ({double? paid, double? remaining})? _paymentSummaryFor(
    SalesAgreement agreement,
    SalesAgreementListState state,
  ) {
    final finance = state.financeFor(agreement);
    if (finance.charges <= 0 && finance.paid <= 0 && finance.due <= 0) {
      return null;
    }
    return (paid: finance.paid, remaining: finance.due);
  }

  List<TileMenuAction> _menuActionsFor(
    SalesAgreement agreement, {
    required bool canCreate,
    required bool canEdit,
  }) {
    final actions = <TileMenuAction>[
      TileMenuAction(
        label: AppStrings.salesAgreementDetails,
        icon: Icons.visibility_outlined,
        onSelected: () => context.push(RoutePaths.salesDetail(agreement.id)),
      ),
    ];

    if (canEdit) {
      actions.add(
        TileMenuAction(
          label: AppStrings.editSalesAgreement,
          icon: Icons.edit_outlined,
          onSelected: () => context.push(RoutePaths.salesEdit(agreement.id)),
        ),
      );
    }

    if (canCreate &&
        agreement.summaryStatus != SalesAgreementSummaryStatus.cancelled) {
      actions.add(
        TileMenuAction(
          label: AppStrings.addSalesOrder,
          icon: Icons.add_shopping_cart_outlined,
          onSelected: () => context.push(
            RoutePaths.salesAddOrder(agreement.id),
          ),
        ),
      );
    }

    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = context.userCanCreate(AppModule.sales);
    final canEdit = context.userCanEdit(AppModule.sales);

    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<SalesAgreementListBloc, SalesAgreementListState>(
          buildWhen: (prev, curr) =>
              prev.visibleAgreements.length != curr.visibleAgreements.length ||
              prev.statusFilter != curr.statusFilter,
          builder: (context, state) {
            final appBarForeground =
                Theme.of(context).appBarTheme.foregroundColor ??
                    Theme.of(context).colorScheme.onSurface;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.sales),
                Text(
                  '${state.visibleAgreements.length} agreements'
                  '${state.statusFilter != SalesAgreementListStatusFilter.all ? ' · ${state.statusFilter.label}' : ''}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: appBarForeground.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.salesOrdersLabel,
            onPressed: () => context.push(RoutePaths.salesOrders),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
          const NotificationBell(),
          const AccountMenuButton(),
        ],
      ),
      floatingActionButton: canCreate
          ? AppExtendedFab(
              heroTag: 'fab-sales-agreements',
              onPressed: () => context.push(RoutePaths.salesAdd),
              icon: Icons.handshake_outlined,
              label: AppStrings.newSalesAgreement,
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: JobWorkSearchBar(
              controller: _searchController,
              hintText: 'Search agreement #, customer, status...',
              onChanged: (value) => context
                  .read<SalesAgreementListBloc>()
                  .add(SalesAgreementListSearchChanged(value)),
              onClear: _onSearchClear,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BlocBuilder<SalesAgreementListBloc, SalesAgreementListState>(
              buildWhen: (prev, curr) => prev.statusFilter != curr.statusFilter,
              builder: (context, state) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: SalesAgreementListStatusFilter.values
                        .map((filter) {
                      final isSelected = state.statusFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(
                            filter.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          selected: isSelected,
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => context
                              .read<SalesAgreementListBloc>()
                              .add(
                                SalesAgreementListStatusFilterChanged(filter),
                              ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          BlocBuilder<SalesAgreementListBloc, SalesAgreementListState>(
            builder: (context, state) {
              if (state.status == SalesAgreementListStatus.loading &&
                  state.agreements.isEmpty) {
                return const SizedBox.shrink();
              }
              final overview = _financeOverviewFor(state);
              return JobWorkFinanceOverviewBar(
                invoiced: overview.invoiced,
                received: overview.received,
                pending: overview.pending,
              );
            },
          ),
          const SizedBox(height: 2),
          Expanded(
            child: BlocBuilder<SalesAgreementListBloc, SalesAgreementListState>(
              builder: (context, state) {
                if (state.status == SalesAgreementListStatus.loading &&
                    state.agreements.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state.status == SalesAgreementListStatus.failure) {
                  return EmptyStateView(
                    icon: Icons.error_outline,
                    title: AppStrings.salesAgreementLoadError,
                    subtitle: state.errorMessage,
                    action: ElevatedButton(
                      onPressed: () {
                        final factoryId = readFactoryId(context);
                        if (factoryId != null) {
                          context.read<SalesAgreementListBloc>().add(
                                SalesAgreementListWatchStarted(factoryId),
                              );
                        }
                      },
                      child: const Text(AppStrings.retry),
                    ),
                  );
                }

                if (state.visibleAgreements.isEmpty) {
                  return EmptyStateView(
                    icon: Icons.handshake_outlined,
                    title: state.searchQuery.isNotEmpty ||
                            state.statusFilter !=
                                SalesAgreementListStatusFilter.all
                        ? 'No sales agreements found'
                        : AppStrings.noSalesAgreements,
                    subtitle: state.searchQuery.isNotEmpty ||
                            state.statusFilter !=
                                SalesAgreementListStatusFilter.all
                        ? AppStrings.tryDifferentSearch
                        : 'Create a sales agreement, then add orders under it',
                    action: state.searchQuery.isEmpty &&
                            state.statusFilter ==
                                SalesAgreementListStatusFilter.all &&
                            canCreate
                        ? ElevatedButton.icon(
                            onPressed: () =>
                                context.push(RoutePaths.salesAdd),
                            icon: const Icon(Icons.add),
                            label: const Text(AppStrings.newSalesAgreement),
                          )
                        : null,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final factoryId = readFactoryId(context);
                    if (factoryId == null) return;
                    context.read<SalesAgreementListBloc>().add(
                          SalesAgreementListWatchStarted(factoryId),
                        );
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 4, bottom: 88),
                    itemCount: state.visibleAgreements.length,
                    itemBuilder: (context, index) {
                      final agreement = state.visibleAgreements[index];
                      final payment = _paymentSummaryFor(agreement, state);
                      return SalesAgreementListTile(
                        agreement: agreement,
                        paidAmount: payment?.paid,
                        remainingAmount: payment?.remaining,
                        menuActions: _menuActionsFor(
                          agreement,
                          canCreate: canCreate,
                          canEdit: canEdit,
                        ),
                        onTap: () => context.push(
                          RoutePaths.salesDetail(agreement.id),
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
