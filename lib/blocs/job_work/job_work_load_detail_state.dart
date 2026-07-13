part of 'job_work_load_detail_bloc.dart';

enum JobWorkLoadDetailStatus { initial, loading, ready, saving, failure }

class JobWorkLoadDetailState extends Equatable {
  const JobWorkLoadDetailState({
    this.status = JobWorkLoadDetailStatus.initial,
    this.order,
    this.load,
    this.siblingLoadCount = 0,
    this.collections = const [],
    this.qualityChecks = const [],
    this.invoice,
    this.payments = const [],
    this.errorMessage,
  });

  final JobWorkLoadDetailStatus status;
  final JobWorkOrder? order;
  final JobWorkLoad? load;
  /// Persisted Loads under the parent JW (source of truth for last-Load checks).
  final int siblingLoadCount;
  final List<JobWorkCollection> collections;
  final List<QualityCheck> qualityChecks;
  final JobWorkInvoice? invoice;
  final List<Payment> payments;
  final String? errorMessage;

  bool get isLastLoad => siblingLoadCount <= 1;

  JobWorkLoadDetailState copyWith({
    JobWorkLoadDetailStatus? status,
    JobWorkOrder? order,
    JobWorkLoad? load,
    int? siblingLoadCount,
    List<JobWorkCollection>? collections,
    List<QualityCheck>? qualityChecks,
    JobWorkInvoice? invoice,
    bool clearInvoice = false,
    List<Payment>? payments,
    String? errorMessage,
  }) {
    return JobWorkLoadDetailState(
      status: status ?? this.status,
      order: order ?? this.order,
      load: load ?? this.load,
      siblingLoadCount: siblingLoadCount ?? this.siblingLoadCount,
      collections: collections ?? this.collections,
      qualityChecks: qualityChecks ?? this.qualityChecks,
      invoice: clearInvoice ? null : (invoice ?? this.invoice),
      payments: payments ?? this.payments,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        order,
        load,
        siblingLoadCount,
        collections,
        qualityChecks,
        invoice,
        payments,
        errorMessage,
      ];
}
