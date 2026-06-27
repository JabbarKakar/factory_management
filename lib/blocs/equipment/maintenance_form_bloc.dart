import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/equipment_repository.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/maintenance_log.dart';

part 'maintenance_form_event.dart';
part 'maintenance_form_state.dart';

class MaintenanceFormBloc
    extends Bloc<MaintenanceFormEvent, MaintenanceFormState> {
  MaintenanceFormBloc({required EquipmentRepository repository})
      : _repository = repository,
        super(const MaintenanceFormState()) {
    on<MaintenanceFormInitialized>(_onInitialized);
    on<MaintenanceFormSubmitted>(_onSubmitted);
  }

  final EquipmentRepository _repository;

  Future<void> _onInitialized(
    MaintenanceFormInitialized event,
    Emitter<MaintenanceFormState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceFormStatus.loading));
    try {
      final equipment = await _repository.getEquipment(event.equipmentId);
      if (equipment == null) {
        emit(
          state.copyWith(
            status: MaintenanceFormStatus.failure,
            errorMessage: 'Equipment not found.',
          ),
        );
        return;
      }

      emit(
        MaintenanceFormState(
          status: MaintenanceFormStatus.ready,
          equipment: equipment,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MaintenanceFormStatus.failure,
          errorMessage: 'Could not load equipment.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    MaintenanceFormSubmitted event,
    Emitter<MaintenanceFormState> emit,
  ) async {
    emit(state.copyWith(status: MaintenanceFormStatus.saving));
    try {
      await _repository.createMaintenanceLog(event.log);
      emit(state.copyWith(status: MaintenanceFormStatus.saved));
    } on EquipmentException catch (error) {
      emit(
        state.copyWith(
          status: MaintenanceFormStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MaintenanceFormStatus.failure,
          errorMessage: 'Could not save maintenance log.',
        ),
      );
    }
  }
}
