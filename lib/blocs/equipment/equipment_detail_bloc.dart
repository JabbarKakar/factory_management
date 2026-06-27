import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/equipment_repository.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/maintenance_log.dart';

part 'equipment_detail_event.dart';
part 'equipment_detail_state.dart';

class EquipmentDetailBloc
    extends Bloc<EquipmentDetailEvent, EquipmentDetailState> {
  EquipmentDetailBloc({required EquipmentRepository repository})
      : _repository = repository,
        super(const EquipmentDetailState()) {
    on<EquipmentDetailWatchStarted>(_onWatchStarted);
    on<EquipmentDetailWatchStopped>(_onWatchStopped);
    on<_EquipmentDetailEquipmentUpdated>(_onEquipmentUpdated);
    on<_EquipmentDetailLogsUpdated>(_onLogsUpdated);
    on<_EquipmentDetailStreamFailed>(_onStreamFailed);
  }

  final EquipmentRepository _repository;
  StreamSubscription<Equipment?>? _equipmentSubscription;
  StreamSubscription<List<MaintenanceLog>>? _logsSubscription;

  Future<void> _onWatchStarted(
    EquipmentDetailWatchStarted event,
    Emitter<EquipmentDetailState> emit,
  ) async {
    emit(state.copyWith(status: EquipmentDetailStatus.loading));

    await _equipmentSubscription?.cancel();
    await _logsSubscription?.cancel();

    _equipmentSubscription =
        _repository.watchEquipmentItem(event.equipmentId).listen(
              (equipment) => add(_EquipmentDetailEquipmentUpdated(equipment)),
              onError: (_) => add(
                const _EquipmentDetailStreamFailed(
                  'Could not load equipment details.',
                ),
              ),
            );

    _logsSubscription =
        _repository.watchMaintenanceLogs(event.equipmentId).listen(
              (logs) => add(_EquipmentDetailLogsUpdated(logs)),
              onError: (_) => add(
                const _EquipmentDetailStreamFailed(
                  'Could not load maintenance history.',
                ),
              ),
            );
  }

  Future<void> _onWatchStopped(
    EquipmentDetailWatchStopped event,
    Emitter<EquipmentDetailState> emit,
  ) async {
    await _equipmentSubscription?.cancel();
    await _logsSubscription?.cancel();
    _equipmentSubscription = null;
    _logsSubscription = null;
  }

  void _onEquipmentUpdated(
    _EquipmentDetailEquipmentUpdated event,
    Emitter<EquipmentDetailState> emit,
  ) {
    if (event.equipment == null) {
      emit(
        state.copyWith(
          status: EquipmentDetailStatus.failure,
          errorMessage: 'Equipment not found.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        status: EquipmentDetailStatus.loaded,
        equipment: event.equipment,
        errorMessage: null,
      ),
    );
  }

  void _onLogsUpdated(
    _EquipmentDetailLogsUpdated event,
    Emitter<EquipmentDetailState> emit,
  ) {
    emit(
      state.copyWith(
        maintenanceLogs: event.logs,
        status: state.equipment != null
            ? EquipmentDetailStatus.loaded
            : state.status,
      ),
    );
  }

  void _onStreamFailed(
    _EquipmentDetailStreamFailed event,
    Emitter<EquipmentDetailState> emit,
  ) {
    emit(
      state.copyWith(
        status: EquipmentDetailStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  @override
  Future<void> close() {
    _equipmentSubscription?.cancel();
    _logsSubscription?.cancel();
    return super.close();
  }
}

final class _EquipmentDetailEquipmentUpdated extends EquipmentDetailEvent {
  const _EquipmentDetailEquipmentUpdated(this.equipment);

  final Equipment? equipment;

  @override
  List<Object?> get props => [equipment];
}

final class _EquipmentDetailLogsUpdated extends EquipmentDetailEvent {
  const _EquipmentDetailLogsUpdated(this.logs);

  final List<MaintenanceLog> logs;

  @override
  List<Object?> get props => [logs];
}

final class _EquipmentDetailStreamFailed extends EquipmentDetailEvent {
  const _EquipmentDetailStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
