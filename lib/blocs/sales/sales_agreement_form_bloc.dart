import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/sales_agreement_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../domain/entities/customer.dart';
import '../../domain/entities/sales_agreement.dart';
import '../../domain/enums/sales_agreement_enums.dart';

part 'sales_agreement_form_event.dart';
part 'sales_agreement_form_state.dart';

class SalesAgreementFormBloc
    extends Bloc<SalesAgreementFormEvent, SalesAgreementFormState> {
  SalesAgreementFormBloc({
    required SalesAgreementRepository agreementRepository,
    required SalesOrderRepository orderRepository,
  })  : _agreementRepository = agreementRepository,
        _orderRepository = orderRepository,
        super(const SalesAgreementFormState()) {
    on<SalesAgreementFormInitialized>(_onInitialized);
    on<SalesAgreementFormLoadRequested>(_onLoadRequested);
    on<SalesAgreementFormSubmitted>(_onSubmitted);
  }

  final SalesAgreementRepository _agreementRepository;
  final SalesOrderRepository _orderRepository;

  Future<void> _onInitialized(
    SalesAgreementFormInitialized event,
    Emitter<SalesAgreementFormState> emit,
  ) async {
    emit(state.copyWith(status: SalesAgreementFormStatus.loading));
    try {
      final customers =
          await _orderRepository.fetchSalesEligibleCustomers(event.factoryId);
      emit(
        SalesAgreementFormState(
          status: SalesAgreementFormStatus.ready,
          eligibleCustomers: customers,
          agreement: SalesAgreement(
            id: '',
            agreementNumber: '',
            factoryId: event.factoryId,
            customerId: '',
            customerName: '',
            createdAt: DateTime.now(),
            summaryStatus: SalesAgreementSummaryStatus.idle,
            schemaVersion: SalesAgreementSchemaVersion.ordersAuthoritative,
            orderCount: 0,
            activeOrderCount: 0,
            totalAmount: 0,
            paidAmount: 0,
            balanceDue: 0,
          ),
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesAgreementFormStatus.failure,
          errorMessage: 'Could not load customers for sales.',
        ),
      );
    }
  }

  Future<void> _onLoadRequested(
    SalesAgreementFormLoadRequested event,
    Emitter<SalesAgreementFormState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SalesAgreementFormStatus.loading,
        isEditing: true,
      ),
    );
    try {
      final agreement =
          await _agreementRepository.getAgreement(event.agreementId);
      if (agreement == null) {
        emit(
          state.copyWith(
            status: SalesAgreementFormStatus.failure,
            errorMessage: 'Sales agreement not found.',
          ),
        );
        return;
      }
      final customers = await _orderRepository
          .fetchSalesEligibleCustomers(agreement.factoryId);
      emit(
        state.copyWith(
          status: SalesAgreementFormStatus.ready,
          agreement: agreement,
          eligibleCustomers: customers,
          isEditing: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesAgreementFormStatus.failure,
          errorMessage: 'Could not load sales agreement.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    SalesAgreementFormSubmitted event,
    Emitter<SalesAgreementFormState> emit,
  ) async {
    emit(state.copyWith(status: SalesAgreementFormStatus.saving));
    try {
      if (event.agreement.id.isEmpty) {
        final created =
            await _agreementRepository.createAgreement(event.agreement);
        emit(
          state.copyWith(
            status: SalesAgreementFormStatus.saved,
            agreement: created,
          ),
        );
      } else {
        await _agreementRepository.updateAgreement(event.agreement);
        emit(
          state.copyWith(
            status: SalesAgreementFormStatus.saved,
            agreement: event.agreement,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: SalesAgreementFormStatus.failure,
          errorMessage: 'Could not save sales agreement.',
        ),
      );
    }
  }
}
