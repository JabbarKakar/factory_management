import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/job_work_load_enums.dart';

/// Production helpers shared by list/dashboard/repo for Load-scoped cutting.
abstract final class JobWorkLoadProductionHelper {
  /// Auto status after output/shifts are saved on a Load.
  static LoadStatus statusAfterOutputSaved(JobWorkLoad load) {
    final output = load.output;
    if (output == null || !output.isRecorded) return load.status;

    final hasCompletion = load.execution?.cuttingCompletionDate != null;
    final hasStart = load.execution?.cuttingStartDate != null;

    if (hasCompletion) {
      return switch (load.status) {
        LoadStatus.qc => LoadStatus.ready,
        LoadStatus.inCutting || LoadStatus.agreed => LoadStatus.qc,
        _ => load.status,
      };
    }

    if (load.status == LoadStatus.agreed &&
        (hasStart || output.totalUsableSqFt > 0)) {
      return LoadStatus.inCutting;
    }

    return load.status;
  }

  /// Best Load to open for Record/Edit Output from a JW list row.
  static JobWorkLoad? preferredLoadForRecordOutput(
    Iterable<JobWorkLoad> loads,
  ) {
    final candidates = loads
        .where((load) => !load.isVirtual && load.status.canRecordOutput)
        .toList();
    if (candidates.isEmpty) return null;

    int rank(JobWorkLoad load) => switch (load.status) {
          JobWorkStatus.inCutting => 0,
          JobWorkStatus.agreed => 1,
          JobWorkStatus.qc => 2,
          _ => 3,
        };

    candidates.sort((a, b) {
      final byRank = rank(a).compareTo(rank(b));
      if (byRank != 0) return byRank;
      return a.loadSequence.compareTo(b.loadSequence);
    });
    return candidates.first;
  }

  static bool orderCanRecordOutput({
    required JobWorkOrder order,
    required Iterable<JobWorkLoad> loads,
  }) {
    final orderLoads =
        loads.where((load) => load.jobWorkId == order.id).toList();
    if (orderLoads.isNotEmpty) {
      return preferredLoadForRecordOutput(orderLoads) != null;
    }
    return order.status.canRecordOutput;
  }

  static bool isAwaitingQcInspection({
    required JobWorkOrder order,
    required Iterable<JobWorkLoad> loads,
    required Set<String> loadIdsWithQc,
    required Set<String> jobWorkIdsWithQc,
  }) {
    final orderLoads =
        loads.where((load) => load.jobWorkId == order.id).toList();
    final loadsInQc = orderLoads
        .where((load) => load.status == JobWorkStatus.qc)
        .toList();
    if (loadsInQc.isNotEmpty) {
      return loadsInQc.any((load) => !loadIdsWithQc.contains(load.id));
    }
    return order.status == JobWorkStatus.qc &&
        !jobWorkIdsWithQc.contains(order.id);
  }

  static int awaitingQcCount({
    required Iterable<JobWorkOrder> orders,
    required Iterable<JobWorkLoad> loads,
    required Set<String> loadIdsWithQc,
    required Set<String> jobWorkIdsWithQc,
  }) {
    return orders
        .where(
          (order) => isAwaitingQcInspection(
            order: order,
            loads: loads,
            loadIdsWithQc: loadIdsWithQc,
            jobWorkIdsWithQc: jobWorkIdsWithQc,
          ),
        )
        .length;
  }
}
