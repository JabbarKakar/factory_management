import '../../domain/entities/sales_agreement.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/sales_agreement_enums.dart';
import '../../domain/enums/sales_enums.dart';

/// Agreement (container) fields derived from authoritative Sales Orders.
abstract final class SalesContainerSyncHelper {
  static List<SalesOrder> ordersForAgreement(
    SalesAgreement agreement,
    List<SalesOrder> orders,
  ) {
    return orders
        .where((order) => order.agreementId == agreement.id)
        .toList();
  }

  static List<SalesOrder> activeOrdersForFinance(
    SalesAgreement agreement,
    List<SalesOrder> orders,
  ) {
    return ordersForAgreement(agreement, orders)
        .where((order) => order.status != SalesOrderStatus.cancelled)
        .toList();
  }

  /// Per-order money for UI (invoice preferred when present).
  static ({double charges, double paid, double due}) financeForOrder({
    required SalesOrder order,
    SalesInvoice? invoice,
  }) {
    if (invoice != null) {
      return (
        charges: invoice.totalAmount,
        paid: invoice.paidAmount,
        due: invoice.dueAmount,
      );
    }
    return (
      charges: order.grandTotal,
      paid: order.advanceReceived,
      due: order.balanceDue,
    );
  }

  /// Prefer order-scoped invoices; fall back to grand invoice, then order fields.
  static ({double charges, double paid, double due}) rollupInvoiceFinance({
    required SalesAgreement agreement,
    required List<SalesOrder> orders,
    required List<SalesInvoice> invoices,
    List<SalesOrder>? ordersToSum,
  }) {
    final byOrderId = <String, SalesInvoice>{};
    for (final invoice in invoices) {
      if (invoice.isGrandInvoice) continue;
      final orderId = invoice.salesOrderId.trim();
      if (orderId.isEmpty) continue;
      byOrderId.putIfAbsent(orderId, () => invoice);
    }

    final agreementOrders =
        ordersToSum ?? activeOrdersForFinance(agreement, orders);
    if (agreementOrders.isNotEmpty) {
      var charges = 0.0;
      var paid = 0.0;
      var due = 0.0;
      for (final order in agreementOrders) {
        SalesInvoice? invoice = byOrderId[order.id];
        final linkedId = order.invoiceId?.trim();
        if (linkedId != null && linkedId.isNotEmpty) {
          final linked =
              invoices.where((item) => item.id == linkedId).firstOrNull;
          if (linked != null) invoice = linked;
        }
        final finance = financeForOrder(order: order, invoice: invoice);
        charges += finance.charges;
        paid += finance.paid;
        due += finance.due;
      }
      return (charges: charges, paid: paid, due: due);
    }

    final grandInvoice = invoices.where((i) => i.isGrandInvoice).firstOrNull;
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
      charges: agreement.totalAmount ?? 0,
      paid: agreement.paidAmount ?? 0,
      due: agreement.balanceDue ?? 0,
    );
  }

  /// Denormalized Agreement fields from child Orders (+ optional invoices).
  static SalesAgreement applyOrderRollup({
    required SalesAgreement agreement,
    required List<SalesOrder> orders,
    List<SalesInvoice> invoices = const [],
  }) {
    final agreementOrders = ordersForAgreement(agreement, orders);
    final active = agreementOrders
        .where((order) => order.status != SalesOrderStatus.cancelled)
        .toList();
    final finance = rollupInvoiceFinance(
      agreement: agreement,
      orders: agreementOrders,
      invoices: invoices,
      ordersToSum: active,
    );

    return agreement.copyWith(
      summaryStatus: SalesAgreementSummaryStatus.fromOrderStatuses(
        agreementOrders.map((order) => order.status),
      ),
      schemaVersion: SalesAgreementSchemaVersion.ordersAuthoritative,
      orderCount: agreementOrders.length,
      activeOrderCount: active.length,
      totalAmount: finance.charges,
      paidAmount: finance.paid,
      balanceDue: finance.due,
      updatedAt: DateTime.now(),
    );
  }

  /// Agreement summary status derived from child orders (legacy orders = one bucket each).
  static Map<String, SalesAgreementSummaryStatus> summaryStatusByAgreementId(
    Iterable<SalesOrder> orders,
  ) {
    final grouped = <String, List<SalesOrderStatus>>{};
    for (final order in orders) {
      final agreementId = order.agreementId?.trim();
      final key = (agreementId == null || agreementId.isEmpty)
          ? 'legacy:${order.id}'
          : agreementId;
      grouped.putIfAbsent(key, () => []).add(order.status);
    }
    return {
      for (final entry in grouped.entries)
        entry.key: SalesAgreementSummaryStatus.fromOrderStatuses(entry.value),
    };
  }

  /// Non-cancelled orders with charges that belong on the Agreement grand invoice.
  static List<SalesOrder> billableOrdersForGrandInvoice(
    List<SalesOrder> orders,
  ) {
    final billable = orders
        .where(
          (order) =>
              order.status != SalesOrderStatus.cancelled &&
              order.grandTotal > 0,
        )
        .toList();
    billable.sort((a, b) {
      final aSeq = a.orderSequence ?? 0;
      final bSeq = b.orderSequence ?? 0;
      if (aSeq != bSeq) return aSeq.compareTo(bSeq);
      return a.createdAt.compareTo(b.createdAt);
    });
    return billable;
  }

  static SalesInvoice? findGrandInvoice(Iterable<SalesInvoice> invoices) {
    for (final invoice in invoices) {
      if (invoice.isGrandInvoice) return invoice;
    }
    return null;
  }

  /// Show Generate when billable orders exist and no grand invoice yet.
  static bool canGenerateGrandInvoice({
    required SalesAgreement agreement,
    required List<SalesOrder> orders,
    List<SalesInvoice> invoices = const [],
  }) {
    if (agreement.summaryStatus == SalesAgreementSummaryStatus.cancelled) {
      return false;
    }
    if (findGrandInvoice(invoices) != null) return false;
    return billableOrdersForGrandInvoice(orders).isNotEmpty;
  }

  /// Show View when a grand (agreement-scoped) invoice exists.
  static bool canViewGrandInvoice(List<SalesInvoice> invoices) {
    return findGrandInvoice(invoices) != null;
  }

  /// Per-order charges/paid/due for grand invoice line items and UI cards.
  static ({double charges, double paid, double due}) financeForOrderOnGrand({
    required SalesOrder order,
    required List<SalesInvoice> invoices,
  }) {
    final orderInvoice = preferActiveSingleInvoice(
      invoices.where(
        (invoice) =>
            !invoice.isGrandInvoice && invoice.salesOrderId == order.id,
      ),
    );
    return financeForOrder(order: order, invoice: orderInvoice);
  }

  /// One active single-order invoice (Grand excluded; cancelled only as last resort).
  static SalesInvoice? preferActiveSingleInvoice(
    Iterable<SalesInvoice> invoices,
  ) {
    final singles =
        invoices.where((invoice) => !invoice.isGrandInvoice).toList();
    if (singles.isEmpty) return null;
    for (final invoice in singles) {
      if (invoice.status != InvoiceStatus.cancelled) return invoice;
    }
    return singles.first;
  }

  /// Order status transition after invoice payment totals change.
  /// Returns null when status should stay unchanged.
  static SalesOrderStatus? orderStatusAfterPaymentSync({
    required SalesOrderStatus current,
    required double dueAmount,
  }) {
    if (dueAmount <= 0 && current != SalesOrderStatus.paid) {
      return SalesOrderStatus.paid;
    }
    if (dueAmount > 0 && current == SalesOrderStatus.paid) {
      return SalesOrderStatus.invoiced;
    }
    return null;
  }

  /// Denormalized order finance fields after payment sync.
  static ({
    double advanceReceived,
    double balanceDue,
    SalesOrderStatus? status,
  }) orderFinanceAfterPaymentSync({
    required SalesOrder order,
    required double paidAmount,
    required double dueAmount,
  }) {
    return (
      advanceReceived: paidAmount,
      balanceDue: dueAmount,
      status: orderStatusAfterPaymentSync(
        current: order.status,
        dueAmount: dueAmount,
      ),
    );
  }
}
