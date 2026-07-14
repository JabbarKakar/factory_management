import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_load_enums.dart';

/// Dual-read helper: prefer persisted loads, else synthesize a virtual Load #1.
abstract final class JobWorkLoadResolver {
  /// Virtual load id used only in memory (never written as this id).
  static String virtualLoadId(String jobWorkId) => 'virtual_$jobWorkId';

  static String virtualLoadNumber(JobWorkOrder order) {
    final year = order.createdAt.year;
    return 'JWL-$year-VIRTUAL';
  }

  /// Returns persisted [loads] when non-empty.
  ///
  /// Sprint 7: migrated containers never synthesize a virtual Load — empty
  /// means ensure/backfill has not run yet (or data is corrupt). Legacy
  /// (schemaVersion < 2) still gets one virtual Load for dual-read display.
  static List<JobWorkLoad> resolveLoads(
    JobWorkOrder order,
    List<JobWorkLoad> loads,
  ) {
    if (loads.isNotEmpty) {
      final sorted = [...loads]
        ..sort((a, b) => a.loadSequence.compareTo(b.loadSequence));
      return sorted;
    }
    if (order.isLoadsAuthoritative) {
      return const [];
    }
    return [synthesizeDefaultLoad(order)];
  }

  /// Which persisted load is the migration default (ensureDefaultLoad target).
  ///
  /// Prefers [JobWorkOrder.defaultLoadId], then sequence 1, then first sorted.
  static JobWorkLoad preferredDefaultLoad(
    JobWorkOrder order,
    List<JobWorkLoad> loads,
  ) {
    if (loads.isEmpty) {
      throw StateError('preferredDefaultLoad requires at least one load.');
    }
    if (order.defaultLoadId != null) {
      for (final load in loads) {
        if (load.id == order.defaultLoadId) return load;
      }
    }
    final sorted = [...loads]
      ..sort((a, b) => a.loadSequence.compareTo(b.loadSequence));
    for (final load in sorted) {
      if (load.loadSequence == 1) return load;
    }
    return sorted.first;
  }

  /// True when ensureDefaultLoad must not create another Load.
  static bool hasPersistedLoads(List<JobWorkLoad> loads) => loads.isNotEmpty;

  /// Next 1-based sequence for a new Load under this JW.
  static int nextLoadSequence(List<JobWorkLoad> existing) {
    if (existing.isEmpty) return 1;
    var maxSequence = 0;
    for (final load in existing) {
      if (load.loadSequence > maxSequence) maxSequence = load.loadSequence;
    }
    return maxSequence + 1;
  }

  /// In-memory Load #1 from nested JW fields (Phase 0 compatibility).
  static JobWorkLoad synthesizeDefaultLoad(JobWorkOrder order) {
    return JobWorkLoad.fromLegacyOrder(
      order,
      id: virtualLoadId(order.id),
      loadNumber: virtualLoadNumber(order),
      loadSequence: 1,
      migratedFromJobWork: false,
      isVirtual: true,
    );
  }

  static JobWorkSummaryStatus summaryFor(
    JobWorkOrder order,
    List<JobWorkLoad> loads,
  ) {
    final resolved = resolveLoads(order, loads);
    return JobWorkSummaryStatus.fromLoadStatuses(
      resolved.map((load) => load.status),
    );
  }
}
