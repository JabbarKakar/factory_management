part of 'supplier_form_bloc.dart';

enum SupplierFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  deleted,
  failure,
}

class SupplierFormState extends Equatable {
  const SupplierFormState({
    this.status = SupplierFormStatus.initial,
    this.supplier,
    this.isEditing = false,
    this.errorMessage,
  });

  final SupplierFormStatus status;
  final Supplier? supplier;
  final bool isEditing;
  final String? errorMessage;

  SupplierFormState copyWith({
    SupplierFormStatus? status,
    Supplier? supplier,
    bool? isEditing,
    String? errorMessage,
  }) {
    return SupplierFormState(
      status: status ?? this.status,
      supplier: supplier ?? this.supplier,
      isEditing: isEditing ?? this.isEditing,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, supplier, isEditing, errorMessage];
}
