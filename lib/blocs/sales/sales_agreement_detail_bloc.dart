import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/sales_agreement_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../domain/entities/sales_agreement.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';

part 'sales_agreement_detail_event.dart';
part 'sales_agreement_detail_state.dart';

class SalesAgreementDetailBloc
    extends Bloc<SalesAgreementDetailEvent, SalesAgreementDetailState> {
  SalesAgreementDetailBloc({
    required SalesAgreementRepository agreementRepository,
    required SalesOrderRepository orderRepository,
    required SalesInvoiceRepository invoiceRepository,
  })  : _agreementRepository = agreementRepository,
        _orderRepository = orderRepository,
        _invoiceRepository = invoiceRepository,
        super(const SalesAgreementDetailState()) {
    on<SalesAgreementDetailWatchStarted>(_onWatchStarted);
    on<SalesAgreementDetailRefreshRequested>(_onRefreshRequested);
    on<_SalesAgreementDetailAgreementUpdated>(_onAgreementUpdated);
    on<_SalesAgreementDetailOrdersUpdated>(_onOrdersUpdated);
    on<_SalesAgreementDetailInvoicesUpdated>(_onInvoicesUpdated);
    on<_SalesAgreementDetailFailed>(_onFailed);
  }

  final SalesAgreementRepository _agreementRepository;
  final SalesOrderRepository _orderRepository;
  final SalesInvoiceRepository _invoiceRepository;
  StreamSubscription<SalesAgreement?>? _agreementSub;
  StreamSubscription<List<SalesOrder>>? _ordersSub;
  StreamSubscription<List<SalesInvoice>>? _invoicesSub;
  String? _agreementId;
  String? _factoryId;

  Future<void> _onWatchStarted(
    SalesAgreementDetailWatchStarted event,
    Emitter<SalesAgreementDetailState> emit,
  ) async {
    _agreementId = event.agreementId;
    emit(state.copyWith(status: SalesAgreementDetailStatus.loading));
    await _cancelSubs();

    final existing = await _agreementRepository.getAgreement(event.agreementId);
    if (existing == null) {
      emit(
        state.copyWith(
          status: SalesAgreementDetailStatus.failure,
          errorMessage: 'Sales agreement not found.',
        ),
      );
      return;
    }
    _factoryId = existing.factoryId;

    _agreementSub =
        _agreementRepository.watchAgreement(event.agreementId).listen(
              (agreement) => add(_SalesAgreementDetailAgreementUpdated(agreement)),
              onError: (_) => add(
                const _SalesAgreementDetailFailed(
                  'Could not load sales agreement.',
                ),
              ),
            );

    _ordersSub = _orderRepository
        .watchOrdersForAgreement(
          factoryId: existing.factoryId,
          agreementId: event.agreementId,
        )
        .listen(
          (orders) => add(_SalesAgreementDetailOrdersUpdated(orders)),
          onError: (_) {},
        );

    _invoicesSub = _invoiceRepository
        .watchInvoicesForAgreement(
          factoryId: existing.factoryId,
          agreementId: event.agreementId,
        )
        .listen(
          (invoices) => add(_SalesAgreementDetailInvoicesUpdated(invoices)),
          onError: (_) {},
        );
  }

  Future<void> _onRefreshRequested(
    SalesAgreementDetailRefreshRequested event,
    Emitter<SalesAgreementDetailState> emit,
  ) async {
    final agreementId = _agreementId;
    final factoryId = _factoryId;
    if (agreementId == null || factoryId == null) return;

    try {
      await _agreementRepository.syncAgreementContainer(agreementId);
      final agreement = await _agreementRepository.getAgreement(agreementId);
      final orders = await _orderRepository.getOrdersForAgreement(
        factoryId: factoryId,
        agreementId: agreementId,
      );
      final invoices = await _invoiceRepository.getInvoicesForAgreement(
        factoryId: factoryId,
        agreementId: agreementId,
      );
      emit(
        state.copyWith(
          status: SalesAgreementDetailStatus.ready,
          agreement: agreement,
          orders: orders,
          invoices: invoices,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesAgreementDetailStatus.failure,
          errorMessage: 'Could not refresh agreement.',
        ),
      );
    }
  }

  void _onAgreementUpdated(
    _SalesAgreementDetailAgreementUpdated event,
    Emitter<SalesAgreementDetailState> emit,
  ) {
    if (event.agreement == null) {
      emit(
        state.copyWith(
          status: SalesAgreementDetailStatus.failure,
          errorMessage: 'Sales agreement not found.',
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: SalesAgreementDetailStatus.ready,
        agreement: event.agreement,
        errorMessage: null,
      ),
    );
  }

  void _onOrdersUpdated(
    _SalesAgreementDetailOrdersUpdated event,
    Emitter<SalesAgreementDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: state.agreement == null
            ? state.status
            : SalesAgreementDetailStatus.ready,
        orders: event.orders,
      ),
    );
  }

  void _onInvoicesUpdated(
    _SalesAgreementDetailInvoicesUpdated event,
    Emitter<SalesAgreementDetailState> emit,
  ) {
    emit(state.copyWith(invoices: event.invoices));
  }

  void _onFailed(
    _SalesAgreementDetailFailed event,
    Emitter<SalesAgreementDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: SalesAgreementDetailStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _cancelSubs() async {
    await _agreementSub?.cancel();
    await _ordersSub?.cancel();
    await _invoicesSub?.cancel();
    _agreementSub = null;
    _ordersSub = null;
    _invoicesSub = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubs();
    return super.close();
  }
}
