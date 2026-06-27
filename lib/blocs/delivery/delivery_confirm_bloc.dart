import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/delivery_repository.dart';
import '../../domain/entities/delivery.dart';

part 'delivery_confirm_event.dart';
part 'delivery_confirm_state.dart';

class DeliveryConfirmBloc extends Bloc<DeliveryConfirmEvent, DeliveryConfirmState> {
  DeliveryConfirmBloc({required DeliveryRepository repository})
      : _repository = repository,
        super(const DeliveryConfirmState()) {
    on<DeliveryConfirmInitialized>(_onInitialized);
    on<DeliveryConfirmSubmitted>(_onSubmitted);
  }

  final DeliveryRepository _repository;

  Future<void> _onInitialized(
    DeliveryConfirmInitialized event,
    Emitter<DeliveryConfirmState> emit,
  ) async {
    emit(state.copyWith(status: DeliveryConfirmStatus.loading));
    try {
      final delivery = await _repository.getDelivery(event.deliveryId);
      if (delivery == null) {
        emit(
          state.copyWith(
            status: DeliveryConfirmStatus.failure,
            errorMessage: 'Delivery not found.',
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: DeliveryConfirmStatus.ready,
          delivery: delivery,
          errorMessage: null,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryConfirmStatus.failure,
          errorMessage: 'Could not load delivery.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    DeliveryConfirmSubmitted event,
    Emitter<DeliveryConfirmState> emit,
  ) async {
    final delivery = state.delivery;
    if (delivery == null) return;

    emit(state.copyWith(status: DeliveryConfirmStatus.saving));
    try {
      await _repository.confirmDelivery(
        id: delivery.id,
        actualDeliveryDate: event.actualDeliveryDate,
        lineItems: event.lineItems,
        notes: event.notes,
      );
      emit(state.copyWith(status: DeliveryConfirmStatus.saved));
    } on DeliveryException catch (error) {
      emit(
        state.copyWith(
          status: DeliveryConfirmStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryConfirmStatus.failure,
          errorMessage: 'Could not confirm delivery.',
        ),
      );
    }
  }
}
