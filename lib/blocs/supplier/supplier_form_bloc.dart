import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/supplier_repository.dart';
import '../../domain/entities/supplier.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/supplier_enums.dart';

part 'supplier_form_event.dart';
part 'supplier_form_state.dart';

class SupplierFormBloc extends Bloc<SupplierFormEvent, SupplierFormState> {
  SupplierFormBloc({required SupplierRepository repository})
      : _repository = repository,
        super(const SupplierFormState()) {
    on<SupplierFormInitialized>(_onInitialized);
    on<SupplierFormLoadRequested>(_onLoadRequested);
    on<SupplierFormSubmitted>(_onSubmitted);
    on<SupplierFormDeleteRequested>(_onDeleteRequested);
    on<_SupplierFormUpdated>(_onUpdated);
    on<_SupplierFormStreamFailed>(_onStreamFailed);
  }

  final SupplierRepository _repository;
  StreamSubscription<Supplier?>? _watchSubscription;

  Future<void> _onInitialized(
    SupplierFormInitialized event,
    Emitter<SupplierFormState> emit,
  ) async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;

    emit(
      SupplierFormState(
        status: SupplierFormStatus.ready,
        supplier: Supplier(
          id: '',
          supplierNumber: '',
          factoryId: event.factoryId,
          name: '',
          supplierType: SupplierType.marbleBlockSlab,
          phone: '',
          paymentTerms: PaymentTerms.cash,
          createdAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onLoadRequested(
    SupplierFormLoadRequested event,
    Emitter<SupplierFormState> emit,
  ) async {
    emit(state.copyWith(status: SupplierFormStatus.loading, isEditing: true));
    await _watchSubscription?.cancel();
    _watchSubscription = _repository.watchSupplier(event.supplierId).listen(
          (supplier) {
            if (supplier == null) {
              add(const _SupplierFormStreamFailed('Supplier not found.'));
            } else {
              add(_SupplierFormUpdated(supplier));
            }
          },
          onError: (_) => add(
            const _SupplierFormStreamFailed('Could not load supplier.'),
          ),
        );
  }

  void _onUpdated(
    _SupplierFormUpdated event,
    Emitter<SupplierFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: SupplierFormStatus.ready,
        supplier: event.supplier,
        isEditing: true,
        errorMessage: null,
      ),
    );
  }

  void _onStreamFailed(
    _SupplierFormStreamFailed event,
    Emitter<SupplierFormState> emit,
  ) {
    emit(
      state.copyWith(
        status: SupplierFormStatus.failure,
        errorMessage: event.message,
      ),
    );
  }

  Future<void> _onSubmitted(
    SupplierFormSubmitted event,
    Emitter<SupplierFormState> emit,
  ) async {
    emit(state.copyWith(status: SupplierFormStatus.saving));
    try {
      if (event.supplier.id.isEmpty) {
        final created = await _repository.createSupplier(event.supplier);
        emit(
          state.copyWith(
            status: SupplierFormStatus.saved,
            supplier: created,
          ),
        );
      } else {
        await _repository.updateSupplier(event.supplier);
        emit(
          state.copyWith(
            status: SupplierFormStatus.saved,
            supplier: event.supplier,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: SupplierFormStatus.failure,
          errorMessage: 'Could not save supplier. Please try again.',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    SupplierFormDeleteRequested event,
    Emitter<SupplierFormState> emit,
  ) async {
    emit(state.copyWith(status: SupplierFormStatus.saving));
    try {
      await _repository.deleteSupplier(event.supplierId);
      await _watchSubscription?.cancel();
      _watchSubscription = null;
      emit(state.copyWith(status: SupplierFormStatus.deleted));
    } catch (_) {
      emit(
        state.copyWith(
          status: SupplierFormStatus.failure,
          errorMessage: 'Could not delete supplier.',
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

final class _SupplierFormUpdated extends SupplierFormEvent {
  const _SupplierFormUpdated(this.supplier);

  final Supplier supplier;

  @override
  List<Object?> get props => [supplier];
}

final class _SupplierFormStreamFailed extends SupplierFormEvent {
  const _SupplierFormStreamFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
