part of 'job_work_collection_form_bloc.dart';

sealed class JobWorkCollectionFormEvent extends Equatable {
  const JobWorkCollectionFormEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkCollectionFormInitialized extends JobWorkCollectionFormEvent {
  const JobWorkCollectionFormInitialized({
    required this.jobWorkOrderId,
    this.loadId,
  });

  final String jobWorkOrderId;
  final String? loadId;

  @override
  List<Object?> get props => [jobWorkOrderId, loadId];
}

final class JobWorkCollectionFormSubmitted extends JobWorkCollectionFormEvent {
  const JobWorkCollectionFormSubmitted({
    required this.collectedAt,
    required this.lineItems,
    this.receiverName,
    this.notes,
  });

  final DateTime collectedAt;
  final List<JobWorkCollectionLineItem> lineItems;
  final String? receiverName;
  final String? notes;

  @override
  List<Object?> get props => [collectedAt, lineItems, receiverName, notes];
}
