part of 'sales_agreement_form_bloc.dart';

enum SalesAgreementFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  failure,
}

class SalesAgreementFormState extends Equatable {
  const SalesAgreementFormState({
    this.status = SalesAgreementFormStatus.initial,
    this.agreement,
    this.eligibleCustomers = const [],
    this.errorMessage,
    this.isEditing = false,
  });

  final SalesAgreementFormStatus status;
  final SalesAgreement? agreement;
  final List<Customer> eligibleCustomers;
  final String? errorMessage;
  final bool isEditing;

  SalesAgreementFormState copyWith({
    SalesAgreementFormStatus? status,
    SalesAgreement? agreement,
    List<Customer>? eligibleCustomers,
    String? errorMessage,
    bool? isEditing,
  }) {
    return SalesAgreementFormState(
      status: status ?? this.status,
      agreement: agreement ?? this.agreement,
      eligibleCustomers: eligibleCustomers ?? this.eligibleCustomers,
      errorMessage: errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }

  @override
  List<Object?> get props => [
        status,
        agreement,
        eligibleCustomers,
        errorMessage,
        isEditing,
      ];
}
