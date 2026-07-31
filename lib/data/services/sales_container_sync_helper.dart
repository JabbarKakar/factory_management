import '../../domain/entities/sales_agreement.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
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

  /// Sprint 2 CTA gate — full Grand Invoice generation is Sprint 4+.
  static bool canGenerateGrandInvoice({
    required SalesAgreement agreement,
    required List<SalesOrder> orders,
  }) {
    if (agreement.summaryStatus == SalesAgreementSummaryStatus.cancelled) {
      return false;
    }
    return activeOrdersForFinance(agreement, orders)
        .any((order) => order.grandTotal > 0 || order.balanceDue > 0);
  }

  static bool canViewGrandInvoice(List<SalesInvoice> invoices) {
    return invoices.any((invoice) => invoice.isGrandInvoice);
  }
}
