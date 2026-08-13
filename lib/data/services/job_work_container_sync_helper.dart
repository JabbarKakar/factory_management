import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
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

  /// Helper to extract paid amount for a specific load from stored invoice line items.
  /// Line items are formatted as: '$label · Total: Rs X · Paid: Rs Y · Remaining: Rs Z'
  /// Uses label-prefix isolation to prevent false matches against year/amount digits.
  static double? extractPaidFromLineItems(
    List<JobWorkInvoice> invoices,
    JobWorkLoad load, {
    int loadIndex = -1,
  }) {
    final loadNum = load.loadNumber.trim();
    final seqStr = load.loadSequence.toString();

    final paidReg = RegExp(
      r'Paid:\s*(?:Rs|PKR|\$|€|£|AED|SAR|INR|[A-Z]{3})?\s*([\d,]+(?:\.\d+)?)',
      caseSensitive: false,
    );

    for (final inv in invoices) {
      if (inv.lineItems.isEmpty) continue;

      // 1. Try label matching on each line item description
      for (final item in inv.lineItems) {
        final desc = item.description;
        if (!desc.contains(RegExp(r'Paid\s*:', caseSensitive: false))) continue;

        // Isolate the load label before '·' or 'Total:' to avoid matching
        // sequence digits inside amounts (e.g. '1318692' ending in '2').
        final labelPart = desc.split('·').first.split('Total:').first.trim();

        bool isMatch = false;
        if (loadNum.isNotEmpty && labelPart.contains(RegExp(r'\b' + RegExp.escape(loadNum) + r'\b', caseSensitive: false))) {
          isMatch = true;
        } else if (labelPart.contains(RegExp(r'(?:Load|LOAD)\s*#?\s*0*' + seqStr + r'$', caseSensitive: false)) ||
            labelPart.contains(RegExp(r'-0*' + seqStr + r'$', caseSensitive: false))) {
          isMatch = true;
        }

        if (isMatch) {
          final match = paidReg.firstMatch(desc);
          if (match != null) {
            final valStr = match.group(1)?.replaceAll(',', '');
            if (valStr != null) {
              final parsed = double.tryParse(valStr);
              if (parsed != null) {
                return parsed;
              }
            }
          }
        }
      }

      // 2. Try filtered positional match (N-th load header item with "Paid:")
      //    Output detail lines ('└ Output: ...') are excluded so indices align
      //    with the billable load sequence used when generating line items.
      final paidItems = inv.lineItems
          .where((item) => item.description.contains(RegExp(r'Paid\s*:', caseSensitive: false)))
          .toList();

      if (loadIndex >= 0 && loadIndex < paidItems.length) {
        final desc = paidItems[loadIndex].description;
        final match = paidReg.firstMatch(desc);
        if (match != null) {
          final valStr = match.group(1)?.replaceAll(',', '');
          if (valStr != null) {
            final parsed = double.tryParse(valStr);
            if (parsed != null) {
              return parsed;
            }
          }
        }
      }
    }
    return null;
  }

  /// Map of per-load financial breakdown ({double charges, double paid, double due})
  /// giving priority to load-specific invoice payments before distributing general payments.
  static Map<String, ({double charges, double paid, double due})>
      calculatePerLoadFinanceMap({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkInvoice> invoices,
    List<Payment> payments = const [],
  }) {
    final billable = billableLoadsForGrandInvoice(loads);
    final loadsToProcess = billable.isNotEmpty ? billable : loads;

    final invoiceReferenceCounts = <String, int>{};
    for (final load in loadsToProcess) {
      final invoiceId = load.invoiceId?.trim() ?? '';
      if (invoiceId.isNotEmpty) {
        invoiceReferenceCounts[invoiceId] =
            (invoiceReferenceCounts[invoiceId] ?? 0) + 1;
      }
    }
    final sharedInvoiceIds = invoiceReferenceCounts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toSet();

    bool isContainerInvoice(JobWorkInvoice invoice) {
      final loadId = invoice.loadId?.trim() ?? '';
      if (loadId.isEmpty || sharedInvoiceIds.contains(invoice.id)) return true;
      if (loadsToProcess.length <= 1) return false;

      // Some legacy grand invoices were incorrectly stamped with the first
      // Load's ID. Their line items still prove that they cover several Loads.
      final referencedLoadCount = loadsToProcess.where((load) {
        final number = load.loadNumber.trim();
        if (number.isEmpty) return false;
        return invoice.lineItems.any(
          (item) => item.description.contains(number),
        );
      }).length;
      if (referencedLoadCount > 1) return true;

      // Last-resort structural check for old invoices whose descriptions were
      // edited: invoice total equals the combined Load charges, not one Load.
      final combinedCharges = loadsToProcess.fold<double>(
        0,
        (sum, load) => sum + load.finalCuttingCharges,
      );
      return (invoice.totalAmount - combinedCharges).abs() <= 0.01;
    }

    final byLoadId = <String, JobWorkInvoice>{};
    for (final invoice in invoices) {
      final loadId = invoice.loadId?.trim();
      if (loadId != null &&
          loadId.isNotEmpty &&
          !isContainerInvoice(invoice)) {
        byLoadId[loadId] = invoice;
      }
    }

    final grandInvoice = invoices
        .where(isContainerInvoice)
        .firstOrNull;

    final invoiceIds = invoices.map((invoice) => invoice.id).toSet();
    final relevantPayments = payments
        .where((payment) => invoiceIds.contains(payment.invoiceId))
        .toList();
    final usePaymentLedger = relevantPayments.isNotEmpty;
    final ledgerPaid = relevantPayments
        .fold<double>(0, (sum, payment) => sum + payment.amount);
    final totalPaymentsRecorded = usePaymentLedger
        ? ledgerPaid
        : grandInvoice != null
            ? grandInvoice.paidAmount
            : invoices.fold<double>(0, (sum, i) => sum + i.paidAmount);

    final result = <String, ({double charges, double paid, double due})>{};
    var specificPaymentsSum = 0.0;

    // Step 1: Assign specific payments to loads that have their own
    // load-scoped invoice, advanceReceived, or stored line-item paid amount.
    for (var i = 0; i < loadsToProcess.length; i++) {
      final load = loadsToProcess[i];
      final inv = byLoadId[load.id] ??
          (load.invoiceId != null && load.invoiceId!.isNotEmpty
              ? invoices
                  .where((inv) =>
                      inv.id == load.invoiceId &&
                      inv.loadId != null &&
                      inv.loadId!.trim() == load.id)
                  .firstOrNull
              : null);

      final total = load.finalCuttingCharges;
      double specificPaid = 0.0;
      final lineItemPaid = usePaymentLedger
          ? null
          : extractPaidFromLineItems(invoices, load, loadIndex: i);

      if (inv != null) {
        specificPaid = usePaymentLedger
            ? relevantPayments
                .where((payment) => payment.invoiceId == inv.id)
                .fold<double>(0, (sum, payment) => sum + payment.amount)
            : inv.paidAmount;
      } else if (!usePaymentLedger && load.advanceReceived > 0) {
        specificPaid = load.advanceReceived;
      } else if (lineItemPaid != null) {
        specificPaid = lineItemPaid;
      }

      // Mark load as having explicit payment data if ANY source provided a value
      if (inv != null ||
          (!usePaymentLedger && load.advanceReceived > 0) ||
          lineItemPaid != null) {
        final paid = specificPaid.clamp(0.0, total).toDouble();
        final due = (total - paid).clamp(0.0, total).toDouble();
        result[load.id] = (charges: total, paid: paid, due: due);
        specificPaymentsSum += paid;
      }
    }

    // Step 2: Distribute remaining general payments in FIFO sequence
    // ONLY to loads that don't already have explicit payment data.
    var generalPool = (totalPaymentsRecorded - specificPaymentsSum)
        .clamp(0.0, double.infinity)
        .toDouble();

    for (var i = 0; i < loadsToProcess.length; i++) {
      final load = loadsToProcess[i];

      // Check if this load has explicit payment data from any source
      final inv = byLoadId[load.id];
      final lineItemPaid = usePaymentLedger
          ? null
          : extractPaidFromLineItems(invoices, load, loadIndex: i);
      final hasExplicitPayment = ((!usePaymentLedger &&
              load.advanceReceived > 0) ||
          inv != null ||
          (lineItemPaid != null));

      if (result.containsKey(load.id)) {
        final existing = result[load.id]!;
        // Only apply general pool to loads WITHOUT explicit payment data
        if (existing.due > 0 && generalPool > 0 && !hasExplicitPayment) {
          final additionalPaid = generalPool >= existing.due
              ? existing.due
              : generalPool;
          final newPaid = existing.paid + additionalPaid;
          final newDue = (existing.charges - newPaid)
              .clamp(0.0, existing.charges)
              .toDouble();
          generalPool = (generalPool - additionalPaid)
              .clamp(0.0, double.infinity)
              .toDouble();
          result[load.id] = (
            charges: existing.charges,
            paid: newPaid,
            due: newDue,
          );
        }
      } else {
        final total = load.finalCuttingCharges;
        final double paid;
        final double due;
        if (generalPool > 0 && !hasExplicitPayment) {
          paid = generalPool >= total ? total : generalPool;
          due = (total - paid).clamp(0.0, total).toDouble();
          generalPool = (generalPool - paid)
              .clamp(0.0, double.infinity)
              .toDouble();
        } else {
          paid = 0.0;
          due = total;
        }
        result[load.id] = (charges: total, paid: paid, due: due);
      }
    }

    return result;
  }

  /// Reconciles aggregate Job Work finance without relying on per-Load payment
  /// allocation. Loads own charges, payment documents own paid, and due is the
  /// mathematical difference. Invoice fields are only a stream/fallback source.
  ///
  /// When Loads exist (Option A), finance is always rolled up from those Loads /
  /// Load-scoped invoices. A JW-level grand invoice (empty [loadId]) is used only
  /// as a fallback when there are no Loads — never short-circuit Load totals.
  static ({double charges, double paid, double due}) rollupInvoiceFinance({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkInvoice> invoices,
    List<Payment> payments = const [],
    List<JobWorkLoad>? loadsToSum,
  }) {
    final orderLoads = loadsToSum ?? activeLoadsForFinance(order, loads);
    if (orderLoads.isNotEmpty) {
      final charges = orderLoads.fold<double>(
        0,
        (sum, load) => sum + load.finalCuttingCharges,
      );

      final invoiceIds = invoices.map((invoice) => invoice.id).toSet();
      final uniquePayments = <String, Payment>{};
      for (final payment in payments) {
        if (invoiceIds.contains(payment.invoiceId)) {
          uniquePayments[payment.id] = payment;
        }
      }

      final double paid;
      if (uniquePayments.isNotEmpty) {
        // Aggregate screens reconcile directly from the immutable payment
        // ledger. Per-Load allocation must never change Job Work/customer totals.
        paid = uniquePayments.values.fold<double>(
          0,
          (sum, payment) => sum + payment.amount,
        );
      } else {
        // Firestore streams do not arrive atomically. While the payment stream
        // is catching up, prefer the invoice that represents the whole Job Work
        // instead of briefly publishing a misleading per-Load allocation.
        final containerInvoice = invoices.where((invoice) {
          if (invoice.loadId == null || invoice.loadId!.trim().isEmpty) {
            return true;
          }
          if ((invoice.totalAmount - charges).abs() <= 0.01) return true;
          final referencedLoads = orderLoads.where((load) {
            final number = load.loadNumber.trim();
            return number.isNotEmpty &&
                invoice.lineItems.any(
                  (item) => item.description.contains(number),
                );
          }).length;
          return referencedLoads > 1;
        }).firstOrNull;

        if (containerInvoice != null) {
          paid = containerInvoice.paidAmount;
        } else {
          final uniqueInvoices = <String, JobWorkInvoice>{
            for (final invoice in invoices) invoice.id: invoice,
          };
          paid = uniqueInvoices.values.fold<double>(
            0,
            (sum, invoice) => sum + invoice.paidAmount,
          );
        }
      }

      final normalizedPaid = paid.clamp(0.0, double.infinity).toDouble();
      final due = (charges - normalizedPaid)
          .clamp(0.0, double.infinity)
          .toDouble();
      return (
        charges: charges,
        paid: normalizedPaid,
        due: due,
      );
    }

    final grandInvoice = invoices
        .where((i) => i.loadId == null || i.loadId!.trim().isEmpty)
        .firstOrNull;
    if (grandInvoice != null) {
      return (
        charges: grandInvoice.totalAmount,
        paid: grandInvoice.paidAmount,
        due: grandInvoice.dueAmount,
      );
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
