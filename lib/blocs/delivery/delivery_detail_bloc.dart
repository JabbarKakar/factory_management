import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/delivery_repository.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/enums/delivery_enums.dart';

part 'delivery_detail_event.dart';
part 'delivery_detail_state.dart';

class DeliveryDetailBloc extends Bloc<DeliveryDetailEvent, DeliveryDetailState> {
  DeliveryDetailBloc({required DeliveryRepository repository})
      : _repository = repository,
        super(const DeliveryDetailState()) {
    on<DeliveryDetailWatchStarted>(_onWatchStarted);
    on<DeliveryDetailWatchStopped>(_onWatchStopped);
    on<DeliveryDetailStatusAdvanceRequested>(_onStatusAdvance);
    on<DeliveryDetailMarkFailedRequested>(_onMarkFailed);
    on<_DeliveryDetailUpdated>(_onUpdated);
    on<_DeliveryDetailStreamFailed>(_onStreamFailed);
  }

  final DeliveryRepository _repository;
  StreamSubscription<Delivery?>? _subscription;

  Future<void> _onWatchStarted(
    DeliveryDetailWatchStarted event,
    Emitter<DeliveryDetailState> emit,
  ) async {
    emit(state.copyWith(status: DeliveryDetailStatus.loading, clearMessages: true));
    await _subscription?.cancel();
    _subscription = _repository.watchDelivery(event.deliveryId).listen(
          (delivery) {
            if (delivery == null) {
              add(const _DeliveryDetailStreamFailed('Delivery not found.'));
            } else {
              add(_DeliveryDetailUpdated(delivery));
            }
          },
          onError: (_) => add(
            const _DeliveryDetailStreamFailed('Could not load delivery.'),
          ),
        );
  }

  Future<void> _onWatchStopped(
    DeliveryDetailWatchStopped event,
    Emitter<DeliveryDetailState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _onUpdated(
    _DeliveryDetailUpdated event,
    Emitter<DeliveryDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: DeliveryDetailStatus.loaded,
        delivery: event.delivery,
        errorMessage: null,
      ),
    );
  }

  Future<void> _onStatusAdvance(
    DeliveryDetailStatusAdvanceRequested event,
    Emitter<DeliveryDetailState> emit,
  ) async {
    final delivery = state.delivery;
    if (delivery == null) return;

    emit(state.copyWith(status: DeliveryDetailStatus.saving, clearMessages: true));
    try {
      await _repository.advanceStatus(delivery.id, event.newStatus);
      emit(
        state.copyWith(
          status: DeliveryDetailStatus.loaded,
          successMessage: 'Delivery status updated',
        ),
      );
    } on DeliveryException catch (error) {
      emit(
        state.copyWith(
          status: DeliveryDetailStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryDetailStatus.failure,
          errorMessage: 'Could not update delivery status.',
        ),
      );
    }
  }

  Future<void> _onMarkFailed(
    DeliveryDetailMarkFailedRequested event,
    Emitter<DeliveryDetailState> emit,
  ) async {
    final delivery = state.delivery;
    if (delivery == null) return;

    emit(state.copyWith(status: DeliveryDetailStatus.saving, clearMessages: true));
    try {
      await _repository.markFailed(delivery.id, notes: event.notes);
      emit(
        state.copyWith(
          status: DeliveryDetailStatus.loaded,
          successMessage: 'Delivery marked as failed',
        ),
      );
    } on DeliveryException catch (error) {
      emit(
        state.copyWith(
          status: DeliveryDetailStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: DeliveryDetailStatus.failure,
          errorMessage: 'Could not update delivery.',
        ),
      );
    }
  }

  void _onStreamFailed(
    _DeliveryDetailStreamFailed event,
    Emitter<DeliveryDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: DeliveryDetailStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

final class _DeliveryDetailUpdated extends DeliveryDetailEvent {
  const _DeliveryDetailUpdated(this.delivery);

  final Delivery delivery;

  @override
  List<Object?> get props => [delivery];
}

final class _DeliveryDetailStreamFailed extends DeliveryDetailEvent {
  const _DeliveryDetailStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
