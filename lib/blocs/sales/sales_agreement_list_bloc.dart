import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/sales_agreement_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/services/sales_container_sync_helper.dart';
import '../../domain/entities/sales_agreement.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/sales_agreement_enums.dart';

part 'sales_agreement_list_event.dart';
part 'sales_agreement_list_state.dart';

class SalesAgreementListBloc
    extends Bloc<SalesAgreementListEvent, SalesAgreementListState> {
  SalesAgreementListBloc({
    required SalesAgreementRepository agreementRepository,
    required SalesOrderRepository orderRepository,
    required SalesInvoiceRepository invoiceRepository,
  })  : _agreementRepository = agreementRepository,
        _orderRepository = orderRepository,
        _invoiceRepository = invoiceRepository,
        super(const SalesAgreementListState()) {
    on<SalesAgreementListWatchStarted>(_onWatchStarted);
    on<SalesAgreementListSearchChanged>(_onSearchChanged);
    on<SalesAgreementListStatusFilterChanged>(_onStatusFilterChanged);
    on<_SalesAgreementListUpdated>(_onListUpdated);
    on<_SalesAgreementOrdersUpdated>(_onOrdersUpdated);
    on<_SalesAgreementInvoicesUpdated>(_onInvoicesUpdated);
    on<_SalesAgreementListStreamFailed>(_onStreamFailed);
  }

  final SalesAgreementRepository _agreementRepository;
  final SalesOrderRepository _orderRepository;
  final SalesInvoiceRepository _invoiceRepository;
  StreamSubscription<List<SalesAgreement>>? _agreementsSub;
  StreamSubscription<List<SalesOrder>>? _ordersSub;
  StreamSubscription<List<SalesInvoice>>? _invoicesSub;

  Future<void> _onWatchStarted(
    SalesAgreementListWatchStarted event,
    Emitter<SalesAgreementListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SalesAgreementListStatus.loading,
        statusFilter: event.initialFilter ?? state.statusFilter,
      ),
    );
    await _agreementsSub?.cancel();
    await _ordersSub?.cancel();
    await _invoicesSub?.cancel();

    _agreementsSub =
        _agreementRepository.watchAgreements(event.factoryId).listen(
              (agreements) => add(_SalesAgreementListUpdated(agreements)),
              onError: (_) => add(
                const _SalesAgreementListStreamFailed(
                  'Could not load sales agreements. Please try again.',
                ),
              ),
            );

    _ordersSub = _orderRepository.watchSalesOrders(event.factoryId).listen(
          (orders) => add(_SalesAgreementOrdersUpdated(orders)),
          onError: (_) {},
        );

    _invoicesSub =
        _invoiceRepository.watchInvoicesForFactory(event.factoryId).listen(
              (invoices) => add(_SalesAgreementInvoicesUpdated(invoices)),
              onError: (_) {},
            );
  }

  void _onSearchChanged(
    SalesAgreementListSearchChanged event,
    Emitter<SalesAgreementListState> emit,
  ) {
    emit(
      state.copyWith(
        searchQuery: event.query,
        visibleAgreements: _applyFilters(
          state.agreements,
          query: event.query,
          statusFilter: state.statusFilter,
        ),
      ),
    );
  }

  void _onStatusFilterChanged(
    SalesAgreementListStatusFilterChanged event,
    Emitter<SalesAgreementListState> emit,
  ) {
    emit(
      state.copyWith(
        statusFilter: event.statusFilter,
        visibleAgreements: _applyFilters(
          state.agreements,
          query: state.searchQuery,
          statusFilter: event.statusFilter,
        ),
      ),
    );
  }

  void _onListUpdated(
    _SalesAgreementListUpdated event,
    Emitter<SalesAgreementListState> emit,
  ) {
    emit(
      state.copyWith(
        status: SalesAgreementListStatus.loaded,
        agreements: event.agreements,
        visibleAgreements: _applyFilters(
          event.agreements,
          query: state.searchQuery,
          statusFilter: state.statusFilter,
        ),
        errorMessage: null,
      ),
    );
  }

  void _onOrdersUpdated(
    _SalesAgreementOrdersUpdated event,
    Emitter<SalesAgreementListState> emit,
  ) {
    emit(state.copyWith(orders: event.orders));
  }

  void _onInvoicesUpdated(
    _SalesAgreementInvoicesUpdated event,
    Emitter<SalesAgreementListState> emit,
  ) {
    emit(state.copyWith(invoices: event.invoices));
  }

  void _onStreamFailed(
    _SalesAgreementListStreamFailed event,
    Emitter<SalesAgreementListState> emit,
  ) {
    emit(
      state.copyWith(
        status: SalesAgreementListStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  List<SalesAgreement> _applyFilters(
    List<SalesAgreement> agreements, {
    required String query,
    required SalesAgreementListStatusFilter statusFilter,
  }) {
    final normalizedQuery = query.trim().toLowerCase();

    final filtered = agreements.where((agreement) {
      if (!statusFilter.matches(agreement.summaryStatus)) return false;
      if (normalizedQuery.isEmpty) return true;

      final haystack = [
        agreement.agreementNumber,
        agreement.customerName,
        agreement.summaryStatus.label,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();

    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Future<void> close() {
    _agreementsSub?.cancel();
    _ordersSub?.cancel();
    _invoicesSub?.cancel();
    return super.close();
  }
}

enum SalesAgreementListStatusFilter {
  all,
  active,
  pendingDelivery,
  idle,
  cancelled;

  String get label => switch (this) {
        SalesAgreementListStatusFilter.all => 'All',
        SalesAgreementListStatusFilter.active => 'Active',
        SalesAgreementListStatusFilter.pendingDelivery => 'Pending Delivery',
        SalesAgreementListStatusFilter.idle => 'Idle',
        SalesAgreementListStatusFilter.cancelled => 'Cancelled',
      };

  static SalesAgreementListStatusFilter fromQuery(String? value) {
    if (value == null || value.isEmpty) {
      return SalesAgreementListStatusFilter.all;
    }
    return SalesAgreementListStatusFilter.values.firstWhere(
      (filter) => filter.name == value,
      orElse: () => SalesAgreementListStatusFilter.all,
    );
  }

  bool matches(SalesAgreementSummaryStatus status) => switch (this) {
        SalesAgreementListStatusFilter.all => true,
        SalesAgreementListStatusFilter.active =>
          status == SalesAgreementSummaryStatus.active,
        SalesAgreementListStatusFilter.pendingDelivery =>
          status == SalesAgreementSummaryStatus.pendingDelivery,
        SalesAgreementListStatusFilter.idle =>
          status == SalesAgreementSummaryStatus.idle,
        SalesAgreementListStatusFilter.cancelled =>
          status == SalesAgreementSummaryStatus.cancelled,
      };
}

extension SalesAgreementListStateFinanceX on SalesAgreementListState {
  List<SalesOrder> ordersFor(String agreementId) =>
      orders.where((order) => order.agreementId == agreementId).toList();

  List<SalesInvoice> invoicesFor(String agreementId) =>
      invoices.where((invoice) => invoice.agreementId == agreementId).toList();

  ({double charges, double paid, double due, double credit}) financeFor(
    SalesAgreement agreement,
  ) {
    return SalesContainerSyncHelper.rollupInvoiceFinance(
      agreement: agreement,
      orders: ordersFor(agreement.id),
      invoices: invoicesFor(agreement.id),
    );
  }
}
