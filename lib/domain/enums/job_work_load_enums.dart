import 'job_work_enums.dart';

/// Load lifecycle — identical Firestore values to [JobWorkStatus] (Phase 0 freeze).
///
/// Kept as a typedef in Sprint 1 so migration is a field move, not a remapping.
/// Call sites should prefer the name [LoadStatus] when operating on Loads.
typedef LoadStatus = JobWorkStatus;

/// Derived Job Work container status (not the cutting FSM).
enum JobWorkSummaryStatus {
  active,
  pendingPickup,
  idle,
  cancelled;

  String get firestoreValue => name;

  String get label => switch (this) {
        JobWorkSummaryStatus.active => 'Active',
        JobWorkSummaryStatus.pendingPickup => 'Pending Pickup',
        JobWorkSummaryStatus.idle => 'Idle',
        JobWorkSummaryStatus.cancelled => 'Cancelled',
      };

  static JobWorkSummaryStatus fromString(String? value) {
    return JobWorkSummaryStatus.values.firstWhere(
      (status) => status.firestoreValue == value,
      orElse: () => JobWorkSummaryStatus.active,
    );
  }

  /// Derive summary from load statuses.
  ///
  /// [pendingPickup] wins over [active] when any load is in a pickup-facing
  /// status. Remaining-qty gating is applied by callers that have collections.
  static JobWorkSummaryStatus fromLoadStatuses(Iterable<LoadStatus> statuses) {
    final list = statuses.toList();
    if (list.isEmpty) return JobWorkSummaryStatus.idle;

    if (list.every((status) => status == JobWorkStatus.cancelled)) {
      return JobWorkSummaryStatus.cancelled;
    }

    final nonCancelled =
        list.where((status) => status != JobWorkStatus.cancelled);
    if (nonCancelled.isEmpty) return JobWorkSummaryStatus.cancelled;

    if (nonCancelled.every((status) => status.isCompleted)) {
      return JobWorkSummaryStatus.idle;
    }

    if (nonCancelled.any((status) => status.isPendingPickup)) {
      return JobWorkSummaryStatus.pendingPickup;
    }

    return JobWorkSummaryStatus.active;
  }
}

/// Schema versions on [jobWorkOrders] (Phase 0).
abstract final class JobWorkSchemaVersion {
  /// Nested work fields on the JW doc are still the source of truth (or dual-read).
  static const int legacy = 1;

  /// [jobWorkLoads] are authoritative; nested JW work fields are archive.
  static const int loadsAuthoritative = 2;
}
