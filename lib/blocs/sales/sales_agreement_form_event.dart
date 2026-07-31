part of 'sales_agreement_form_bloc.dart';

sealed class SalesAgreementFormEvent extends Equatable {
  const SalesAgreementFormEvent();

  @override
  List<Object?> get props => [];
}

final class SalesAgreementFormInitialized extends SalesAgreementFormEvent {
  const SalesAgreementFormInitialized({required this.factoryId});

  final String factoryId;

  @override
  List<Object?> get props => [factoryId];
}

final class SalesAgreementFormLoadRequested extends SalesAgreementFormEvent {
  const SalesAgreementFormLoadRequested(this.agreementId);

  final String agreementId;

  @override
  List<Object?> get props => [agreementId];
}

final class SalesAgreementFormSubmitted extends SalesAgreementFormEvent {
  const SalesAgreementFormSubmitted(this.agreement);

  final SalesAgreement agreement;

  @override
  List<Object?> get props => [agreement];
}
