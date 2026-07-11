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

  /// Returns persisted [loads] when non-empty; otherwise a single virtual Load.
  static List<JobWorkLoad> resolveLoads(
    JobWorkOrder order,
    List<JobWorkLoad> loads,
  ) {
    if (loads.isNotEmpty) {
      final sorted = [...loads]
        ..sort((a, b) => a.loadSequence.compareTo(b.loadSequence));
      return sorted;
    }
    return [synthesizeDefaultLoad(order)];
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
