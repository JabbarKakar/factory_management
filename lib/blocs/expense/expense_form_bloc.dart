import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/expense_repository.dart';
import '../../domain/entities/expense.dart';
import '../../domain/enums/expense_enums.dart';
import '../../domain/enums/invoice_enums.dart';

part 'expense_form_event.dart';
part 'expense_form_state.dart';

class ExpenseFormBloc extends Bloc<ExpenseFormEvent, ExpenseFormState> {
  ExpenseFormBloc({required ExpenseRepository repository})
      : _repository = repository,
        super(const ExpenseFormState()) {
    on<ExpenseFormInitialized>(_onInitialized);
    on<ExpenseFormLoadRequested>(_onLoadRequested);
    on<ExpenseFormSubmitted>(_onSubmitted);
    on<ExpenseFormDeleteRequested>(_onDeleteRequested);
  }

  final ExpenseRepository _repository;

  Future<void> _onInitialized(
    ExpenseFormInitialized event,
    Emitter<ExpenseFormState> emit,
  ) async {
    emit(
      ExpenseFormState(
        status: ExpenseFormStatus.ready,
        expense: _emptyExpense(event.factoryId),
      ),
    );
  }

  Future<void> _onLoadRequested(
    ExpenseFormLoadRequested event,
    Emitter<ExpenseFormState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseFormStatus.loading, isEditing: true));
    try {
      final expense = await _repository.getExpense(event.expenseId);
      if (expense == null) {
        emit(
          state.copyWith(
            status: ExpenseFormStatus.failure,
            errorMessage: 'Expense not found.',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: ExpenseFormStatus.ready,
          expense: expense,
          isEditing: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: ExpenseFormStatus.failure,
          errorMessage: 'Could not load expense.',
        ),
      );
    }
  }

  Future<void> _onSubmitted(
    ExpenseFormSubmitted event,
    Emitter<ExpenseFormState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseFormStatus.saving));
    try {
      if (event.expense.id.isEmpty) {
        final created = await _repository.createExpense(event.expense);
        emit(
          state.copyWith(
            status: ExpenseFormStatus.saved,
            expense: created,
          ),
        );
      } else {
        await _repository.updateExpense(event.expense);
        emit(
          state.copyWith(
            status: ExpenseFormStatus.saved,
            expense: event.expense,
          ),
        );
      }
    } catch (_) {
      emit(
        state.copyWith(
          status: ExpenseFormStatus.failure,
          errorMessage: 'Could not save expense.',
        ),
      );
    }
  }

  Future<void> _onDeleteRequested(
    ExpenseFormDeleteRequested event,
    Emitter<ExpenseFormState> emit,
  ) async {
    emit(state.copyWith(status: ExpenseFormStatus.saving));
    try {
      await _repository.deleteExpense(event.expenseId);
      emit(state.copyWith(status: ExpenseFormStatus.deleted));
    } catch (_) {
      emit(
        state.copyWith(
          status: ExpenseFormStatus.failure,
          errorMessage: 'Could not delete expense.',
        ),
      );
    }
  }

  Expense _emptyExpense(String factoryId) {
    return Expense(
      id: '',
      expenseNumber: '',
      factoryId: factoryId,
      expenseDate: DateTime.now(),
      category: ExpenseCategory.miscellaneous,
      description: '',
      amount: 0,
      paymentMethod: PaymentMethod.cash,
      createdAt: DateTime.now(),
    );
  }
}
