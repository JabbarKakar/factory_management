part of 'job_work_load_detail_bloc.dart';

sealed class JobWorkLoadDetailEvent extends Equatable {
  const JobWorkLoadDetailEvent();

  @override
  List<Object?> get props => [];
}

final class JobWorkLoadDetailStarted extends JobWorkLoadDetailEvent {
  const JobWorkLoadDetailStarted({
    required this.jobWorkId,
    required this.loadId,
  });

  final String jobWorkId;
  final String loadId;

  @override
  List<Object?> get props => [jobWorkId, loadId];
}

final class _JobWorkLoadDetailLoadUpdated extends JobWorkLoadDetailEvent {
  const _JobWorkLoadDetailLoadUpdated(this.load);

  final JobWorkLoad? load;

  @override
  List<Object?> get props => [load];
}

final class _JobWorkLoadDetailCollectionsUpdated extends JobWorkLoadDetailEvent {
  const _JobWorkLoadDetailCollectionsUpdated(this.collections);

  final List<JobWorkCollection> collections;

  @override
  List<Object?> get props => [collections];
}

final class _JobWorkLoadDetailQualityUpdated extends JobWorkLoadDetailEvent {
  const _JobWorkLoadDetailQualityUpdated(this.qualityChecks);

  final List<QualityCheck> qualityChecks;

  @override
  List<Object?> get props => [qualityChecks];
}

final class _JobWorkLoadDetailInvoiceUpdated extends JobWorkLoadDetailEvent {
  const _JobWorkLoadDetailInvoiceUpdated(this.invoice);

  final JobWorkInvoice? invoice;

  @override
  List<Object?> get props => [invoice];
}

final class _JobWorkLoadDetailPaymentsUpdated extends JobWorkLoadDetailEvent {
  const _JobWorkLoadDetailPaymentsUpdated(this.payments);

  final List<Payment> payments;

  @override
  List<Object?> get props => [payments];
}

final class JobWorkLoadDetailAdvanceStatusRequested
    extends JobWorkLoadDetailEvent {
  const JobWorkLoadDetailAdvanceStatusRequested(this.nextStatus);

  final JobWorkStatus nextStatus;

  @override
  List<Object?> get props => [nextStatus];
}

final class JobWorkLoadDetailAdvanceCompletionRequested
    extends JobWorkLoadDetailEvent {
  const JobWorkLoadDetailAdvanceCompletionRequested(this.nextStatus);

  final JobWorkStatus nextStatus;

  @override
  List<Object?> get props => [nextStatus];
}
