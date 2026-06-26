part of 'expense_form_bloc.dart';

enum ExpenseFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  deleted,
  failure,
}

class ExpenseFormState extends Equatable {
  const ExpenseFormState({
    this.status = ExpenseFormStatus.initial,
    this.expense,
    this.errorMessage,
    this.isEditing = false,
  });

  final ExpenseFormStatus status;
  final Expense? expense;
  final String? errorMessage;
  final bool isEditing;

  ExpenseFormState copyWith({
    ExpenseFormStatus? status,
    Expense? expense,
    String? errorMessage,
    bool? isEditing,
  }) {
    return ExpenseFormState(
      status: status ?? this.status,
      expense: expense ?? this.expense,
      errorMessage: errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [status, expense, errorMessage, isEditing];
}
