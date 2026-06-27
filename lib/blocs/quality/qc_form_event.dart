part of 'qc_form_bloc.dart';

sealed class QcFormEvent extends Equatable {
  const QcFormEvent();

  @override
  List<Object?> get props => [];
}

final class QcFormInitialized extends QcFormEvent {
  const QcFormInitialized({
    required this.factoryId,
    this.referenceType,
    this.referenceId,
  });

  final String factoryId;
  final QcReferenceType? referenceType;
  final String? referenceId;

  @override
  List<Object?> get props => [factoryId, referenceType, referenceId];
}

final class QcFormReferenceTypeChanged extends QcFormEvent {
  const QcFormReferenceTypeChanged(this.referenceType);

  final QcReferenceType referenceType;

  @override
  List<Object?> get props => [referenceType];
}

final class QcFormReferenceSelected extends QcFormEvent {
  const QcFormReferenceSelected(this.referenceId);

  final String referenceId;

  @override
  List<Object?> get props => [referenceId];
}

final class QcFormSubmitted extends QcFormEvent {
  const QcFormSubmitted(this.check);

  final QualityCheck check;

  @override
  List<Object?> get props => [check];
}
