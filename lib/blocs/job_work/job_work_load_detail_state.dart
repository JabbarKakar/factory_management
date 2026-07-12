part of 'job_work_load_detail_bloc.dart';

enum JobWorkLoadDetailStatus { initial, loading, ready, saving, failure }

class JobWorkLoadDetailState extends Equatable {
  const JobWorkLoadDetailState({
    this.status = JobWorkLoadDetailStatus.initial,
    this.order,
    this.load,
    this.collections = const [],
    this.qualityChecks = const [],
    this.errorMessage,
  });

  final JobWorkLoadDetailStatus status;
  final JobWorkOrder? order;
  final JobWorkLoad? load;
  final List<JobWorkCollection> collections;
  final List<QualityCheck> qualityChecks;
  final String? errorMessage;

  JobWorkLoadDetailState copyWith({
    JobWorkLoadDetailStatus? status,
    JobWorkOrder? order,
    JobWorkLoad? load,
    List<JobWorkCollection>? collections,
    List<QualityCheck>? qualityChecks,
    String? errorMessage,
  }) {
    return JobWorkLoadDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      load: load ?? this.load,
      collections: collections ?? this.collections,
      qualityChecks: qualityChecks ?? this.qualityChecks,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        order,
        load,
        collections,
        qualityChecks,
        errorMessage,
      ];
}
