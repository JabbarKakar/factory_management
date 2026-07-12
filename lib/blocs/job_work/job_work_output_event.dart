part of 'job_work_output_bloc.dart';

sealed class JobWorkOutputEvent extends Equatable {
  const JobWorkOutputEvent();

  @override
  List<Object?> get props => [];
}

/// Loads a Load for output recording.
///
/// Prefer [loadId]. When only [jobWorkId] is provided (legacy route), the
/// default Load is ensured and used.
final class JobWorkOutputLoadRequested extends JobWorkOutputEvent {
  const JobWorkOutputLoadRequested({
    this.jobWorkId,
    this.loadId,
  });

  final String? jobWorkId;
  final String? loadId;

  @override
  List<Object?> get props => [jobWorkId, loadId];
}

final class JobWorkOutputSubmitted extends JobWorkOutputEvent {
  const JobWorkOutputSubmitted(this.load);

  final JobWorkLoad load;

  @override
  List<Object?> get props => [load];
}
