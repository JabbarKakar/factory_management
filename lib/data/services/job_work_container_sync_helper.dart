import 'dart:math' as math;

import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/enums/invoice_enums.dart';
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

  /// Whether a payment belongs on this Job Work for list/detail finance.
  ///
  /// Migrated orders often have a payment whose `orderId` / `loadId` still
  /// point at a legacy id, while the live invoice lives on `order.invoiceId`
  /// or `load.invoiceId`. Those rows must still settle remaining due.
  ///
  /// [siblingOrderIds] are other live Job Work ids for the same customer.
  /// A payment whose `orderId` is empty or unknown (deleted invoice / legacy
  /// container) still belongs here when this is that customer's only JW.
  static bool paymentBelongsToJobWork({
    required Payment payment,
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkInvoice> invoices,
    Set<String> siblingOrderIds = const {},
    bool attachDanglingCustomerPayments = false,
  }) {
    if (payment.status == PaymentStatus.voided) return false;

    final orderId = payment.orderId?.trim() ?? '';
    if (orderId.isNotEmpty &&
        (orderId == order.id || orderId == order.jobWorkNumber)) {
      return true;
    }

    final loadId = payment.loadId?.trim() ?? '';
    if (loadId.isNotEmpty && loads.any((load) => load.id == loadId)) {
      return true;
    }

    final invoiceId = payment.invoiceId.trim();
    if (invoiceId.isNotEmpty) {
      if (invoices.any((invoice) => invoice.id == invoiceId)) return true;
      final orderInvoiceId = order.invoiceId?.trim() ?? '';
      if (orderInvoiceId.isNotEmpty && orderInvoiceId == invoiceId) {
        return true;
      }
      if (loads.any((load) => (load.invoiceId?.trim() ?? '') == invoiceId)) {
        return true;
      }
    }

    if (payment.customerId != order.customerId) return false;
    if (payment.invoiceType == InvoiceType.sales) return false;

    final invoiceNumber = payment.invoiceNumber.trim();
    if (order.jobWorkNumber.isNotEmpty &&
        invoiceNumber.contains(order.jobWorkNumber)) {
      return true;
    }
    for (final load in loads) {
      if (load.loadNumber.isNotEmpty &&
          invoiceNumber.contains(load.loadNumber)) {
        return true;
      }
    }
    for (final invoice in invoices) {
      if (invoice.invoiceNumber.isNotEmpty &&
          invoiceNumber == invoice.invoiceNumber) {
        return true;
      }
    }

    // Empty or dangling orderId (deleted invoice) still belongs when this
    // is the customer's only live Job Work.
    if (!attachDanglingCustomerPayments) return false;
    if (orderId.isNotEmpty && siblingOrderIds.contains(orderId)) {
      return false;
    }
    return true;
  }

  static List<Payment> relevantPaymentsForJobWork({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkInvoice> invoices,
    required Iterable<Payment> payments,
    Set<String> siblingOrderIds = const {},
    bool alreadyScoped = false,
    bool attachDanglingCustomerPayments = false,
  }) {
    final unique = <String, Payment>{};
    for (final payment in payments) {
      if (alreadyScoped) {
        if (payment.status != PaymentStatus.voided) {
          unique[payment.id] = payment;
        }
        continue;
      }
      if (paymentBelongsToJobWork(
        payment: payment,
        order: order,
        loads: loads,
        invoices: invoices,
        siblingOrderIds: siblingOrderIds,
        attachDanglingCustomerPayments: attachDanglingCustomerPayments,
      )) {
        unique[payment.id] = payment;
      }
    }
    return unique.values.toList();
  }

  /// Applied cash that should settle this Job Work's charges.
  ///
  /// Rows with [Payment.appliedAmount] use that value. Rows that target this
  /// Job Work but stored applied=0 (broken overpay write) contribute cash up
  /// to leftover due. Unallocated leftover on a correct overpay is not
  /// silently applied.
  static double settledPaidForJobWork({
    required double charges,
    required Iterable<Payment> payments,
  }) {
    var applied = 0.0;
    var unappliedCash = 0.0;
    for (final payment in payments) {
      if (payment.status == PaymentStatus.voided) continue;
      if (payment.appliedAmount > 0.005) {
        applied += payment.appliedAmount;
      } else if (payment.amount > 0.005) {
        unappliedCash += payment.amount;
      }
    }
    final leftoverDue = (charges - applied).clamp(0.0, double.infinity);
    final healed = math.min(unappliedCash, leftoverDue);
    return applied + healed;
  }

  /// Remaining due to apply a new payment against. Uses the larger of load
  /// vs invoice remaining when one denormalized field was incorrectly zeroed.
  static double remainingDueForPayment({
    required JobWorkInvoice invoice,
    JobWorkLoad? load,
  }) {
    final charges = load != null && load.finalCuttingCharges > 0.005
        ? load.finalCuttingCharges
        : invoice.totalAmount;
    final invoiceRemaining = invoice.dueAmount > 0.005
        ? invoice.dueAmount
        : (charges - invoice.paidAmount).clamp(0.0, charges).toDouble();
    if (load == null) {
      return invoiceRemaining.clamp(0.0, charges).toDouble();
    }
    final loadRemaining = load.balanceDue;
    if (loadRemaining > 0.005 && invoiceRemaining > 0.005) {
      return math.min(loadRemaining, invoiceRemaining).clamp(0.0, charges);
    }
    return math
        .max(loadRemaining, invoiceRemaining)
        .clamp(0.0, charges)
        .toDouble();
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
              if (parsed != null && parsed > 0) {
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
            if (parsed != null && parsed > 0) {
              return parsed;
            }
          }
        }
      }
    }
    return null;
  }

  /// Map of per-load financial breakdown ({double charges, double paid, double due, double credit})
  /// giving priority to load-specific invoice payments before distributing general payments.
  static Map<String, ({double charges, double paid, double due, double credit})>
      calculatePerLoadFinanceMap({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkInvoice> invoices,
    List<Payment> payments = const [],
    Set<String> siblingOrderIds = const {},
    bool alreadyScoped = false,
    bool attachDanglingCustomerPayments = false,
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

    final relevantPayments = relevantPaymentsForJobWork(
      order: order,
      loads: loadsToProcess,
      invoices: invoices,
      payments: payments,
      siblingOrderIds: siblingOrderIds,
      alreadyScoped: alreadyScoped,
      attachDanglingCustomerPayments: attachDanglingCustomerPayments,
    );
    final usePaymentLedger = relevantPayments.isNotEmpty;
    final chargesTotal = loadsToProcess.fold<double>(
      0,
      (sum, load) => sum + load.finalCuttingCharges,
    );
    final ledgerPaid = settledPaidForJobWork(
      charges: chargesTotal,
      payments: relevantPayments,
    );
    final totalPaymentsRecorded = usePaymentLedger
        ? ledgerPaid
        : grandInvoice != null
            ? grandInvoice.paidAmount
            : (invoices.isNotEmpty
                ? invoices.fold<double>(0, (sum, i) => sum + i.paidAmount)
                : loadsToProcess.fold<double>(0, (sum, l) => sum + l.advanceReceived));

    final result = <String, ({double charges, double paid, double due, double credit})>{};
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

      if (usePaymentLedger) {
        final seen = <String>{};
        for (final payment in relevantPayments) {
          final matchesLoadInvoice =
              inv != null && payment.invoiceId == inv.id;
          final matchesLoad = payment.loadId == load.id;
          if (!matchesLoadInvoice && !matchesLoad) continue;
          if (!seen.add(payment.id)) continue;
          specificPaid += payment.appliedAmount;
        }
        if (specificPaid <= 0.005 && load.advanceReceived > 0) {
          specificPaid = load.advanceReceived;
        }
      } else if (inv != null) {
        specificPaid = inv.paidAmount;
      } else if (load.advanceReceived > 0) {
        specificPaid = load.advanceReceived;
      } else if (lineItemPaid != null && lineItemPaid > 0) {
        specificPaid = lineItemPaid;
      }

      // Mark load as having explicit payment data if ANY source provided a positive value
      if (inv != null ||
          load.advanceReceived > 0 ||
          specificPaid > 0 ||
          (lineItemPaid != null && lineItemPaid > 0)) {
        final paid = specificPaid >= total ? total : specificPaid;
        final due = (total - specificPaid).clamp(0.0, total).toDouble();
        final credit = (specificPaid - total).clamp(0.0, double.infinity).toDouble();
        result[load.id] = (charges: total, paid: paid, due: due, credit: credit);
        specificPaymentsSum += specificPaid;
      }
    }

    // Step 2: Remaining applied cash (not already assigned to a load) settles
    // leftover due in load sequence — including loads that already have advance.
    var generalPool = (totalPaymentsRecorded - specificPaymentsSum)
        .clamp(0.0, double.infinity)
        .toDouble();

    for (var i = 0; i < loadsToProcess.length; i++) {
      final load = loadsToProcess[i];

      if (result.containsKey(load.id)) {
        final existing = result[load.id]!;
        // Leftover applied cash (e.g. a grand-invoice overpay) still settles
        // remaining due, even when the load already has advance / its own invoice.
        if (existing.due > 0 && generalPool > 0) {
          final additionalPaid = generalPool >= existing.due
              ? existing.due
              : generalPool;
          final newPaid = existing.paid + additionalPaid;
          final newDue = (existing.charges - newPaid)
              .clamp(0.0, existing.charges)
              .toDouble();
          final newCredit = (newPaid - existing.charges)
              .clamp(0.0, double.infinity)
              .toDouble();
          generalPool = (generalPool - additionalPaid)
              .clamp(0.0, double.infinity)
              .toDouble();
          result[load.id] = (
            charges: existing.charges,
            paid: newPaid,
            due: newDue,
            credit: newCredit,
          );
        }
      } else {
        final total = load.finalCuttingCharges;
        final double paid;
        final double due;
        final double credit;
        if (generalPool > 0) {
          paid = generalPool >= total ? total : generalPool;
          due = (total - paid).clamp(0.0, total).toDouble();
          credit = (generalPool - total).clamp(0.0, double.infinity).toDouble();
          generalPool = (generalPool - paid)
              .clamp(0.0, double.infinity)
              .toDouble();
        } else {
          paid = 0.0;
          due = total;
          credit = 0.0;
        }
        result[load.id] = (charges: total, paid: paid, due: due, credit: credit);
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
  static ({double charges, double paid, double due, double credit}) rollupInvoiceFinance({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
    required List<JobWorkInvoice> invoices,
    List<Payment> payments = const [],
    List<JobWorkLoad>? loadsToSum,
    Set<String> siblingOrderIds = const {},
    bool alreadyScoped = false,
    bool attachDanglingCustomerPayments = false,
  }) {
    final orderLoads = loadsToSum ?? activeLoadsForFinance(order, loads);
    if (orderLoads.isNotEmpty) {
      final charges = orderLoads.fold<double>(
        0,
        (sum, load) => sum + load.finalCuttingCharges,
      );

      final uniquePayments = relevantPaymentsForJobWork(
        order: order,
        loads: orderLoads,
        invoices: invoices,
        payments: payments,
        siblingOrderIds: siblingOrderIds,
        alreadyScoped: alreadyScoped,
        attachDanglingCustomerPayments: attachDanglingCustomerPayments,
      );

      final double paid;
      if (uniquePayments.isNotEmpty) {
        // Aggregate screens reconcile directly from the immutable payment
        // ledger. Per-Load allocation must never change Job Work/customer totals.
        paid = settledPaidForJobWork(
          charges: charges,
          payments: uniquePayments,
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
        } else if (invoices.isNotEmpty) {
          final uniqueInvoices = <String, JobWorkInvoice>{
            for (final invoice in invoices) invoice.id: invoice,
          };
          paid = uniqueInvoices.values.fold<double>(
            0,
            (sum, invoice) => sum + invoice.paidAmount,
          );
        } else {
          paid = orderLoads.fold<double>(
            0,
            (sum, load) => sum + load.advanceReceived,
          );
        }
      }

      final normalizedPaid = paid.clamp(0.0, double.infinity).toDouble();
      final due = (charges - normalizedPaid)
          .clamp(0.0, double.infinity)
          .toDouble();
      final credit = (normalizedPaid - charges)
          .clamp(0.0, double.infinity)
          .toDouble();
      return (
        charges: charges,
        paid: normalizedPaid,
        due: due,
        credit: credit,
      );
    }

    final grandInvoice = invoices
        .where((i) => i.loadId == null || i.loadId!.trim().isEmpty)
        .firstOrNull;
    if (grandInvoice != null) {
      final credit = (grandInvoice.paidAmount - grandInvoice.totalAmount)
          .clamp(0.0, double.infinity)
          .toDouble();
      return (
        charges: grandInvoice.totalAmount,
        paid: grandInvoice.paidAmount,
        due: grandInvoice.dueAmount,
        credit: credit,
      );
    }

    if (invoices.isNotEmpty) {
      final charges = invoices.fold<double>(0, (s, i) => s + i.totalAmount);
      final paid = invoices.fold<double>(0, (s, i) => s + i.paidAmount);
      final due = (charges - paid).clamp(0.0, double.infinity).toDouble();
      final credit = (paid - charges).clamp(0.0, double.infinity).toDouble();
      return (
        charges: charges,
        paid: paid,
        due: due,
        credit: credit,
      );
    }

    final charges = order.finalCuttingCharges;
    final paid = order.advanceReceived;
    final due = (charges - paid).clamp(0.0, double.infinity).toDouble();
    final credit = (paid - charges).clamp(0.0, double.infinity).toDouble();
    return (
      charges: charges,
      paid: paid,
      due: due,
      credit: credit,
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
