import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/employee_repository.dart';
import '../../domain/entities/employee.dart';
import '../../domain/enums/labour_enums.dart';

part 'employee_form_event.dart';
part 'employee_form_state.dart';

class EmployeeFormBloc extends Bloc<EmployeeFormEvent, EmployeeFormState> {
  EmployeeFormBloc({required EmployeeRepository repository})
      : _repository = repository,
        super(const EmployeeFormState()) {
    on<EmployeeFormInitialized>(_onInitialized);
    on<EmployeeFormLoadRequested>(_onLoadRequested);
    on<EmployeeFormSubmitted>(_onSubmitted);
    on<EmployeeFormDeleteRequested>(_onDeleteRequested);
    on<_EmployeeFormUpdated>(_onUpdated);
    on<_EmployeeFormStreamFailed>(_onStreamFailed);
  }

  final EmployeeRepository _repository;
  StreamSubscription<Employee?>? _watchSubscription;

  Future<void> _onInitialized(
    EmployeeFormInitialized event,
    Emitter<EmployeeFormState> emit,
  ) async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;

    emit(
      EmployeeFormState(
        status: EmployeeFormStatus.ready,
        employee: Employee(
          id: '',
          employeeNumber: '',
          factoryId: event.factoryId,
          fullName: '',
          phone: '',
          workerCategory: WorkerCategory.helper,
          employmentType: EmploymentType.dailyWage,
          salaryType: SalaryType.dailyRate,
          rateAmount: 0,
          joinDate: DateTime.now(),
          status: EmployeeStatus.active,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onLoadRequested(
    EmployeeFormLoadRequested event,
    Emitter<EmployeeFormState> emit,
  ) async {
    emit(state.copyWith(status: EmployeeFormStatus.loading, isEditing: true));
    await _watchSubscription?.cancel();
    _watchSubscription = _repository.watchEmployee(event.employeeId).listen(
          (employee) {
            if (employee == null) {
              add(const _EmployeeFormStreamFailed('Employee not found.'));
            } else {
              add(_EmployeeFormUpdated(employee));
            }
          },
          onError: (_) => add(
            const _EmployeeFormStreamFailed('Could not load employee.'),
          ),
        );
  }

  void _onUpdated(
    _EmployeeFormUpdated event,
    Emitter<EmployeeFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeFormStatus.ready,
        employee: event.employee,
        isEditing: true,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _EmployeeFormStreamFailed event,
    Emitter<EmployeeFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: EmployeeFormStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onSubmitted(
    EmployeeFormSubmitted event,
    Emitter<EmployeeFormState> emit,
  ) async {
    emit(state.copyWith(status: EmployeeFormStatus.saving));
    try {
      if (event.employee.id.isEmpty) {
        final created = await _repository.createEmployee(event.employee);
        emit(
          state.copyWith(
            status: EmployeeFormStatus.saved,
            employee: created,
          ),
        );
      } else {
        await _repository.updateEmployee(event.employee);
        emit(
          state.copyWith(
            status: EmployeeFormStatus.saved,
            employee: event.employee,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: EmployeeFormStatus.failure,
          errorMessage: 'Could not save employee. Please try again.',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    EmployeeFormDeleteRequested event,
    Emitter<EmployeeFormState> emit,
  ) async {
    emit(state.copyWith(status: EmployeeFormStatus.saving));
    try {
      await _repository.deleteEmployee(event.employeeId);
      await _watchSubscription?.cancel();
      _watchSubscription = null;
      emit(state.copyWith(status: EmployeeFormStatus.deleted));
    } catch (_) {
      emit(
        state.copyWith(
          status: EmployeeFormStatus.failure,
          errorMessage: 'Could not delete employee.',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _watchSubscription?.cancel();
    return super.close();
  }
}

final class _EmployeeFormUpdated extends EmployeeFormEvent {
  const _EmployeeFormUpdated(this.employee);

  final Employee employee;

  @override
  List<Object?> get props => [employee];
}

final class _EmployeeFormStreamFailed extends EmployeeFormEvent {
  const _EmployeeFormStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
