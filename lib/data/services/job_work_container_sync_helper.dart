import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_enums.dart';
import 'job_work_collection_quantity_helper.dart';

/// Container (Job Work) fields derived from authoritative Loads.
abstract final class JobWorkContainerSyncHelper {
  /// Status to persist on the Job Work when Loads exist.
  static JobWorkStatus resolveContainerStatus({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    if (order.status == JobWorkStatus.cancelled) {
      return JobWorkStatus.cancelled;
    }

    final derived = JobWorkCollectionQuantityHelper.displayStatusForOrder(
      order: order,
      loads: loads,
    );

    // Collection / completion always wins over invoice/payment labels.
    if (derived == JobWorkStatus.partiallyCollected ||
        derived == JobWorkStatus.collected ||
        derived == JobWorkStatus.closed ||
        derived == JobWorkStatus.cancelled) {
      return derived;
    }

    // Keep finance labels until Sprint 5 per-Load invoices own them.
    if (order.status == JobWorkStatus.invoiced ||
        order.status == JobWorkStatus.paid) {
      return order.status;
    }

    return derived;
  }

  static List<JobWorkLoad> persistedLoadsForOrder(
    JobWorkOrder order,
    List<JobWorkLoad> loads,
  ) {
    return loads
        .where((load) => load.jobWorkId == order.id && !load.isVirtual)
        .toList();
  }

  /// Cutting charges rollup: prefer Load totals when any Load exists.
  static double rollupFinalCuttingCharges({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    final orderLoads = persistedLoadsForOrder(order, loads);
    if (orderLoads.isEmpty) return order.finalCuttingCharges;
    return orderLoads.fold<double>(
      0,
      (sum, load) => sum + load.finalCuttingCharges,
    );
  }

  static double rollupAdvanceReceived({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    final orderLoads = persistedLoadsForOrder(order, loads);
    if (orderLoads.isEmpty) return order.advanceReceived;
    return orderLoads.fold<double>(
      0,
      (sum, load) => sum + load.advanceReceived,
    );
  }

  static double rollupBalanceDue({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    final orderLoads = persistedLoadsForOrder(order, loads);
    if (orderLoads.isEmpty) return order.balanceDue;
    return orderLoads.fold<double>(
      0,
      (sum, load) => sum + load.balanceDue,
    );
  }

  /// Whether a Load-scoped invoice can be generated (Option A).
  /// Allowed at any operational stage (including collected/closed) when
  /// cutting charges exist; only cancelled / virtual loads are blocked.
  static bool canGenerateInvoiceForLoad(JobWorkLoad load) {
    if (load.isVirtual) return false;
    if (load.status == JobWorkStatus.cancelled) return false;
    if (load.invoiceId != null && load.invoiceId!.isNotEmpty) return true;
    return load.finalCuttingCharges > 0;
  }

  /// Finance status after invoice create / payment sync — never clobber collection.
  static JobWorkStatus? financeStatusForLoad({
    required JobWorkLoad load,
    required double dueAmount,
  }) {
    if (load.status == JobWorkStatus.cancelled ||
        load.status == JobWorkStatus.closed ||
        load.status.isCollectionStatus) {
      return null;
    }
    if (dueAmount <= 0) return JobWorkStatus.paid;
    if (load.status == JobWorkStatus.paid) return JobWorkStatus.invoiced;
    if (load.status == JobWorkStatus.invoiced) return null;
    return JobWorkStatus.invoiced;
  }

  /// Whether a JW-level invoice can be generated (legacy / single-Load shortcut).
  static bool canGenerateInvoice({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    if (order.status == JobWorkStatus.cancelled) return false;

    final orderLoads = persistedLoadsForOrder(order, loads);
    if (orderLoads.length == 1) {
      return canGenerateInvoiceForLoad(orderLoads.first);
    }
    if (orderLoads.length > 1) {
      // Multi-Load JW: generate from each Load, not a JW rollup invoice.
      return false;
    }

    if (order.invoiceId != null && order.invoiceId!.isNotEmpty) return true;

    // Any stage is fine; only charges (and cancelled above) gate generation.
    return rollupFinalCuttingCharges(order: order, loads: loads) > 0;
  }
}
