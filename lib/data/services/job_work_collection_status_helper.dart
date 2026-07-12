import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_enums.dart';
import 'job_work_collection_quantity_helper.dart';

/// Derives automated collection statuses from collected quantities.
///
/// Early statuses without production ([JobWorkStatus.received],
/// [JobWorkStatus.agreed]) stay protected. Once cutting has started and stock
/// is produced, partial pickups become [JobWorkStatus.partiallyCollected] and
/// full pickup becomes [JobWorkStatus.collected] — including from
/// [JobWorkStatus.inCutting] / [JobWorkStatus.qc].
abstract final class JobWorkCollectionStatusHelper {
  static bool isProtectedFromCollectionSync(JobWorkStatus status) {
    return status == JobWorkStatus.cancelled ||
        status == JobWorkStatus.closed ||
        status == JobWorkStatus.received ||
        status == JobWorkStatus.agreed;
  }

  static bool canCollectMaterial(JobWorkStatus status) {
    return status.canCollectMaterial;
  }

  /// Returns the status the order should have, or `null` when unchanged.
  static JobWorkStatus? resolveTargetStatus({
    required JobWorkOrder order,
    required List<JobWorkCollection> collections,
  }) {
    return _resolveTargetStatus(
      current: order.status,
      totals: JobWorkCollectionQuantityHelper.orderTotals(order, collections),
      hasInvoice: order.invoiceId != null && order.invoiceId!.isNotEmpty,
    );
  }

  /// Returns the status the Load should have, or `null` when unchanged.
  static JobWorkStatus? resolveTargetStatusForLoad({
    required JobWorkLoad load,
    required List<JobWorkCollection> collections,
  }) {
    return _resolveTargetStatus(
      current: load.status,
      totals: JobWorkCollectionQuantityHelper.loadTotals(load, collections),
      hasInvoice: load.invoiceId != null && load.invoiceId!.isNotEmpty,
    );
  }

  static JobWorkStatus? _resolveTargetStatus({
    required JobWorkStatus current,
    required JobWorkCollectionTotals totals,
    required bool hasInvoice,
  }) {
    if (isProtectedFromCollectionSync(current)) return null;
    if (!totals.hasProducedStock) return null;

    if (totals.isFullyCollected) {
      return current == JobWorkStatus.collected
          ? null
          : JobWorkStatus.collected;
    }

    if (totals.hasCollections) {
      return current == JobWorkStatus.partiallyCollected
          ? null
          : JobWorkStatus.partiallyCollected;
    }

    if (current == JobWorkStatus.partiallyCollected ||
        current == JobWorkStatus.collected) {
      return hasInvoice ? JobWorkStatus.ready : JobWorkStatus.ready;
    }

    return null;
  }
}
