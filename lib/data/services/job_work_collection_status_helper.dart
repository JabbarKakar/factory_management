import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_enums.dart';
import 'job_work_collection_quantity_helper.dart';

/// Derives automated job-work collection statuses from collected quantities.
///
/// Production statuses ([JobWorkStatus.inCutting], [JobWorkStatus.qc]) are
/// protected so early pickups do not skip cutting/QC. From ready onward,
/// partial pickups become [JobWorkStatus.partiallyCollected] and full pickup
/// becomes [JobWorkStatus.collected].
abstract final class JobWorkCollectionStatusHelper {
  static bool isProtectedFromCollectionSync(JobWorkStatus status) {
    return status == JobWorkStatus.cancelled ||
        status == JobWorkStatus.closed ||
        status == JobWorkStatus.received ||
        status == JobWorkStatus.agreed ||
        status == JobWorkStatus.inCutting ||
        status == JobWorkStatus.qc;
  }

  static bool canCollectMaterial(JobWorkStatus status) {
    return status.canCollectMaterial;
  }

  /// Returns the status the order should have, or `null` when unchanged.
  static JobWorkStatus? resolveTargetStatus({
    required JobWorkOrder order,
    required List<JobWorkCollection> collections,
  }) {
    final current = order.status;
    if (isProtectedFromCollectionSync(current)) return null;

    final totals = JobWorkCollectionQuantityHelper.orderTotals(
      order,
      collections,
    );
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

    // Collections removed / cancelled — leave collection statuses.
    if (current == JobWorkStatus.partiallyCollected ||
        current == JobWorkStatus.collected) {
      return _fallbackWithoutCollections(order);
    }

    return null;
  }

  static JobWorkStatus _fallbackWithoutCollections(JobWorkOrder order) {
    final hasInvoice =
        order.invoiceId != null && order.invoiceId!.isNotEmpty;
    if (!hasInvoice) return JobWorkStatus.ready;
    // Prefer ready so invoice/payment flows can re-derive financial status.
    return JobWorkStatus.ready;
  }
}
