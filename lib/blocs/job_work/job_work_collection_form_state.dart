part of 'job_work_collection_form_bloc.dart';

enum JobWorkCollectionFormStatus {
  initial,
  loading,
  ready,
  saving,
  saved,
  failure,
}

class JobWorkCollectionFormState extends Equatable {
  const JobWorkCollectionFormState({
    this.status = JobWorkCollectionFormStatus.initial,
    this.order,
    this.load,
    this.customer,
    this.collections = const [],
    this.errorMessage,
  });

  final JobWorkCollectionFormStatus status;
  final JobWorkOrder? order;
  final JobWorkLoad? load;
  final Customer? customer;
  final List<JobWorkCollection> collections;
  final String? errorMessage;

  JobWorkCollectionFormState copyWith({
    JobWorkCollectionFormStatus? status,
    JobWorkOrder? order,
    JobWorkLoad? load,
    Customer? customer,
    List<JobWorkCollection>? collections,
    String? errorMessage,
  }) {
    return JobWorkCollectionFormState(
      status: status ?? this.status,
      order: order ?? this.order,
      load: load ?? this.load,
      customer: customer ?? this.customer,
      collections: collections ?? this.collections,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, order, load, customer, collections, errorMessage];
}
