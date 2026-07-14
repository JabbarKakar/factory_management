import '../../domain/entities/job_work_invoice.dart';
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

  /// Non-cancelled persisted loads used for customer-facing money rollups.
  static List<JobWorkLoad> activeLoadsForFinance(
    JobWorkOrder order,
    List<JobWorkLoad> loads,
  ) {
    return persistedLoadsForOrder(order, loads)
        .where((load) => load.status != JobWorkStatus.cancelled)
        .toList();
  }

  /// Per-Load money for UI (matches grand-invoice cards and list tile).
  static ({double charges, double paid, double due}) financeForLoad({
    required JobWorkLoad load,
    JobWorkInvoice? invoice,
  }) {
    if (invoice != null) {
      return (
        charges: invoice.totalAmount,
        paid: invoice.paidAmount,
        due: invoice.dueAmount,
      );
    }
    return (
      charges: load.finalCuttingCharges,
      paid: load.advanceReceived,
      due: load.balanceDue,
    );
  }

  /// Prefer invoice documents when present (authoritative paid/due/charges).
  /// Only counts active (non-cancelled) Loads so Summary matches visible cards.
  static ({double charges, double paid, double due}) rollupInvoiceFinance({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkInvoice> invoices,
    List<JobWorkLoad>? loadsToSum,
  }) {
    // If there is a grand invoice (loadId is null/empty or matching order's invoiceId),
    // then that single grand invoice is the authoritative source for the whole container's finance!
    final grandInvoice = invoices
        .where((i) =>
            i.loadId == null ||
            i.loadId!.isEmpty ||
            i.id == order.invoiceId)
        .firstOrNull;
    if (grandInvoice != null) {
      return (
        charges: grandInvoice.totalAmount,
        paid: grandInvoice.paidAmount,
        due: grandInvoice.dueAmount,
      );
    }

    final byLoadId = <String, JobWorkInvoice>{};
    for (final invoice in invoices) {
      final loadId = invoice.loadId?.trim();
      if (loadId == null || loadId.isEmpty) continue;
      // Prefer the invoice the Load points at when set.
      byLoadId[loadId] = invoice;
    }
    for (final invoice in invoices) {
      final loadId = invoice.loadId?.trim();
      if (loadId == null || loadId.isEmpty) continue;
      byLoadId.putIfAbsent(loadId, () => invoice);
    }

    final orderLoads = loadsToSum ??
        activeLoadsForFinance(order, loads);
    if (orderLoads.isNotEmpty) {
      var charges = 0.0;
      var paid = 0.0;
      var due = 0.0;
      for (final load in orderLoads) {
        final invoice = byLoadId[load.id];
        if (load.invoiceId != null &&
            load.invoiceId!.isNotEmpty &&
            invoice != null &&
            invoice.id != load.invoiceId) {
          // load.invoiceId wins when it differs from an older duplicate doc.
          final linked = invoices
              .where((item) => item.id == load.invoiceId)
              .firstOrNull;
          final finance = financeForLoad(load: load, invoice: linked);
          charges += finance.charges;
          paid += finance.paid;
          due += finance.due;
          continue;
        }
        final finance = financeForLoad(load: load, invoice: invoice);
        charges += finance.charges;
        paid += finance.paid;
        due += finance.due;
      }
      return (charges: charges, paid: paid, due: due);
    }

    if (invoices.isNotEmpty) {
      return (
        charges: invoices.fold<double>(0, (s, i) => s + i.totalAmount),
        paid: invoices.fold<double>(0, (s, i) => s + i.paidAmount),
        due: invoices.fold<double>(0, (s, i) => s + i.dueAmount),
      );
    }

    return (
      charges: order.finalCuttingCharges,
      paid: order.advanceReceived,
      due: order.balanceDue,
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

  /// Whether a JW-level invoice can be generated.
  static bool canGenerateInvoice({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    if (order.status == JobWorkStatus.cancelled) return false;

    final orderLoads = persistedLoadsForOrder(order, loads);
    if (order.invoiceId != null && order.invoiceId!.isNotEmpty) return true;

    if (orderLoads.isEmpty) {
      return order.finalCuttingCharges > 0;
    }

    // With loads: can generate if any active load can be invoiced (has charges)
    return orderLoads.any((load) => canGenerateInvoiceForLoad(load));
  }

  /// Loads that should appear on the Job Work grand invoice (non-cancelled, with charges).
  static List<JobWorkLoad> billableLoadsForGrandInvoice(
    List<JobWorkLoad> loads,
  ) {
    return loads
        .where(
          (load) =>
              !load.isVirtual &&
              load.status != JobWorkStatus.cancelled &&
              load.finalCuttingCharges > 0,
        )
        .toList()
      ..sort((a, b) => a.loadSequence.compareTo(b.loadSequence));
  }

  /// True when every billable Load already has an invoice (grand invoice ready).
  static bool isGrandInvoiceComplete({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    if (order.status == JobWorkStatus.cancelled) return false;
    final billable = billableLoadsForGrandInvoice(loads);
    if (billable.isEmpty) return false;
    return billable.every(
      (load) => load.invoiceId != null && load.invoiceId!.isNotEmpty,
    );
  }

  /// Show Generate when any billable Load is still missing an invoice.
  static bool canGenerateGrandInvoice({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    if (order.status == JobWorkStatus.cancelled) return false;
    if (isGrandInvoiceComplete(order: order, loads: loads)) return false;
    return billableLoadsForGrandInvoice(loads).any(
      (load) =>
          (load.invoiceId == null || load.invoiceId!.isEmpty) &&
          canGenerateInvoiceForLoad(load),
    );
  }

  /// Show View when the grand invoice is complete (mutually exclusive with Generate).
  static bool canViewGrandInvoice({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    return isGrandInvoiceComplete(order: order, loads: loads);
  }
}
