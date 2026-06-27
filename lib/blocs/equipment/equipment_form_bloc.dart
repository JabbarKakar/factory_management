import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/equipment_repository.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/enums/equipment_enums.dart';

part 'equipment_form_event.dart';
part 'equipment_form_state.dart';

class EquipmentFormBloc extends Bloc<EquipmentFormEvent, EquipmentFormState> {
  EquipmentFormBloc({required EquipmentRepository repository})
      : _repository = repository,
        super(const EquipmentFormState()) {
    on<EquipmentFormInitialized>(_onInitialized);
    on<EquipmentFormLoadRequested>(_onLoadRequested);
    on<EquipmentFormSubmitted>(_onSubmitted);
    on<EquipmentFormDeleteRequested>(_onDeleteRequested);
  }

  final EquipmentRepository _repository;

  Future<void> _onInitialized(
    EquipmentFormInitialized event,
    Emitter<EquipmentFormState> emit,
  ) async {
    emit(
      EquipmentFormState(
        status: EquipmentFormStatus.ready,
        equipment: _emptyEquipment(event.factoryId),
      ),
    );
  }

  Future<void> _onLoadRequested(
    EquipmentFormLoadRequested event,
    Emitter<EquipmentFormState> emit,
  ) async {
    emit(
      state.copyWith(
        status: EquipmentFormStatus.loading,
        isEditing: true,
      ),
    );
    try {
      final equipment = await _repository.getEquipment(event.equipmentId);
      if (equipment == null) {
        emit(
          state.copyWith(
            status: EquipmentFormStatus.failure,
            errorMessage: 'Equipment not found.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: EquipmentFormStatus.ready,
          equipment: equipment,
          isEditing: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: EquipmentFormStatus.failure,
          errorMessage: 'Could not load equipment.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    EquipmentFormSubmitted event,
    Emitter<EquipmentFormState> emit,
  ) async {
    emit(state.copyWith(status: EquipmentFormStatus.saving));
    try {
      if (event.equipment.id.isEmpty) {
        final created = await _repository.createEquipment(event.equipment);
        emit(
          state.copyWith(
            status: EquipmentFormStatus.saved,
            equipment: created,
          ),
        );
      } else {
        await _repository.updateEquipment(event.equipment);
        emit(
          state.copyWith(
            status: EquipmentFormStatus.saved,
            equipment: event.equipment,
          ),
        );
      }
    } on EquipmentException catch (error) {
      emit(
        state.copyWith(
          status: EquipmentFormStatus.failure,
          errorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: EquipmentFormStatus.failure,
          errorMessage: 'Could not save equipment.',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    EquipmentFormDeleteRequested event,
    Emitter<EquipmentFormState> emit,
  ) async {
    emit(state.copyWith(status: EquipmentFormStatus.saving));
    try {
      await _repository.deleteEquipment(event.equipmentId);
      emit(state.copyWith(status: EquipmentFormStatus.deleted));
    } catch (_) {
      emit(
        state.copyWith(
          status: EquipmentFormStatus.failure,
          errorMessage: 'Could not delete equipment.',
        ),
      );
    }
  }

  Equipment _emptyEquipment(String factoryId) {
    return Equipment(
      id: '',
      equipmentNumber: '',
      factoryId: factoryId,
      name: '',
      category: EquipmentCategory.cutting,
      status: EquipmentStatus.running,
      createdAt: DateTime.now(),
    );
  }
}
