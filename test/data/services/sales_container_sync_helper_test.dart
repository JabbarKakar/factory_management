import 'package:factory_management/data/services/sales_container_sync_helper.dart';
import 'package:factory_management/domain/entities/sales_agreement.dart';
import 'package:factory_management/domain/entities/sales_invoice.dart';
import 'package:factory_management/domain/entities/sales_order.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:factory_management/domain/enums/sales_agreement_enums.dart';
import 'package:factory_management/domain/enums/sales_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SalesAgreement buildAgreement({
    String id = 'sa-1',
    SalesAgreementSummaryStatus summaryStatus =
        SalesAgreementSummaryStatus.active,
    double? totalAmount,
    double? paidAmount,
    double? balanceDue,
  }) {
    return SalesAgreement(
      id: id,
      agreementNumber: 'SA-2026-0001',
      factoryId: 'factory-1',
      customerId: 'customer-1',
      customerName: 'Hussain',
      createdAt: DateTime(2026, 1, 1),
      summaryStatus: summaryStatus,
      schemaVersion: SalesAgreementSchemaVersion.ordersAuthoritative,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      balanceDue: balanceDue,
    );
  }

  SalesOrder buildOrder({
    required String id,
    String agreementId = 'sa-1',
    SalesOrderStatus status = SalesOrderStatus.received,
    double grandTotal = 1000,
    double advanceReceived = 0,
    double balanceDue = 1000,
    String? invoiceId,
  }) {
    return SalesOrder(
      id: id,
      orderNumber: 'ORD-2026-0001',
      factoryId: 'factory-1',
      customerId: 'customer-1',
      customerName: 'Hussain',
      status: status,
      orderDate: DateTime(2026, 1, 2),
      orderSource: SalesOrderSource.walkIn,
      lineItems: const [],
      subtotal: grandTotal,
      orderDiscount: 0,
      tax: 0,
      grandTotal: grandTotal,
      paymentTerms: PaymentTerms.cash,
      advanceReceived: advanceReceived,
      balanceDue: balanceDue,
      createdAt: DateTime(2026, 1, 2),
      agreementId: agreementId,
      agreementNumber: 'SA-2026-0001',
      invoiceId: invoiceId,
    );
  }

  SalesInvoice buildInvoice({
    required String id,
    required String salesOrderId,
    String agreementId = 'sa-1',
    double totalAmount = 1000,
    double paidAmount = 0,
    double dueAmount = 1000,
  }) {
    return SalesInvoice(
      id: id,
      invoiceNumber: 'INV-2026-0001',
      factoryId: 'factory-1',
      agreementId: agreementId,
      agreementNumber: 'SA-2026-0001',
      salesOrderId: salesOrderId,
      orderNumber: 'ORD-2026-0001',
      customerId: 'customer-1',
      customerName: 'Hussain',
      lineItems: const [],
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      dueAmount: dueAmount,
      status: InvoiceStatus.partial,
      createdAt: DateTime(2026, 1, 3),
    );
  }

  group('applyOrderRollup', () {
    test('counts orders and derives pendingDelivery summary', () {
      final agreement = buildAgreement();
      final rolled = SalesContainerSyncHelper.applyOrderRollup(
        agreement: agreement,
        orders: [
          buildOrder(id: 'o1', status: SalesOrderStatus.ready),
          buildOrder(id: 'o2', status: SalesOrderStatus.received),
          buildOrder(
            id: 'o3',
            status: SalesOrderStatus.cancelled,
            grandTotal: 500,
            balanceDue: 0,
          ),
        ],
      );

      expect(rolled.orderCount, 3);
      expect(rolled.activeOrderCount, 2);
      expect(rolled.summaryStatus, SalesAgreementSummaryStatus.pendingDelivery);
      expect(rolled.schemaVersion, SalesAgreementSchemaVersion.ordersAuthoritative);
      expect(rolled.totalAmount, 2000);
      expect(rolled.balanceDue, 2000);
    });

    test('marks cancelled when every order is cancelled', () {
      final rolled = SalesContainerSyncHelper.applyOrderRollup(
        agreement: buildAgreement(),
        orders: [
          buildOrder(id: 'o1', status: SalesOrderStatus.cancelled),
          buildOrder(id: 'o2', status: SalesOrderStatus.cancelled),
        ],
      );

      expect(rolled.summaryStatus, SalesAgreementSummaryStatus.cancelled);
      expect(rolled.activeOrderCount, 0);
      expect(rolled.totalAmount, 0);
    });

    test('marks idle when non-cancelled orders are terminal', () {
      final rolled = SalesContainerSyncHelper.applyOrderRollup(
        agreement: buildAgreement(),
        orders: [
          buildOrder(id: 'o1', status: SalesOrderStatus.paid, balanceDue: 0),
          buildOrder(
            id: 'o2',
            status: SalesOrderStatus.delivered,
            balanceDue: 0,
          ),
        ],
      );

      expect(rolled.summaryStatus, SalesAgreementSummaryStatus.idle);
    });
  });

  group('rollupInvoiceFinance', () {
    test('prefers order invoices over order field amounts', () {
      final agreement = buildAgreement(
        totalAmount: 50,
        paidAmount: 10,
        balanceDue: 40,
      );
      final finance = SalesContainerSyncHelper.rollupInvoiceFinance(
        agreement: agreement,
        orders: [
          buildOrder(id: 'o1', grandTotal: 1000, balanceDue: 1000),
          buildOrder(id: 'o2', grandTotal: 2000, balanceDue: 2000),
        ],
        invoices: [
          buildInvoice(
            id: 'inv-1',
            salesOrderId: 'o1',
            totalAmount: 1000,
            paidAmount: 400,
            dueAmount: 600,
          ),
          buildInvoice(
            id: 'inv-2',
            salesOrderId: 'o2',
            totalAmount: 2000,
            paidAmount: 500,
            dueAmount: 1500,
          ),
        ],
      );

      expect(finance.charges, 3000);
      expect(finance.paid, 900);
      expect(finance.due, 2100);
    });

    test('excludes cancelled orders from finance rollup', () {
      final finance = SalesContainerSyncHelper.rollupInvoiceFinance(
        agreement: buildAgreement(),
        orders: [
          buildOrder(id: 'o1', grandTotal: 1000, balanceDue: 1000),
          buildOrder(
            id: 'o2',
            status: SalesOrderStatus.cancelled,
            grandTotal: 9999,
            balanceDue: 9999,
          ),
        ],
        invoices: const [],
      );

      expect(finance.charges, 1000);
      expect(finance.due, 1000);
    });

    test('falls back to grand invoice when no active orders', () {
      final finance = SalesContainerSyncHelper.rollupInvoiceFinance(
        agreement: buildAgreement(),
        orders: [
          buildOrder(id: 'o1', status: SalesOrderStatus.cancelled),
        ],
        invoices: [
          buildInvoice(
            id: 'grand-1',
            salesOrderId: '',
            totalAmount: 5000,
            paidAmount: 2000,
            dueAmount: 3000,
          ),
        ],
      );

      expect(finance.charges, 5000);
      expect(finance.paid, 2000);
      expect(finance.due, 3000);
    });
  });

  group('grand invoice gates', () {
    test('canGenerateGrandInvoice when active order has charges', () {
      final can = SalesContainerSyncHelper.canGenerateGrandInvoice(
        agreement: buildAgreement(),
        orders: [
          buildOrder(id: 'o1', grandTotal: 1200, balanceDue: 1200),
        ],
      );
      expect(can, isTrue);
    });

    test('cannot generate grand invoice for cancelled agreement', () {
      final can = SalesContainerSyncHelper.canGenerateGrandInvoice(
        agreement: buildAgreement(
          summaryStatus: SalesAgreementSummaryStatus.cancelled,
        ),
        orders: [
          buildOrder(id: 'o1', grandTotal: 1200, balanceDue: 1200),
        ],
      );
      expect(can, isFalse);
    });

    test('canViewGrandInvoice when a grand invoice exists', () {
      expect(
        SalesContainerSyncHelper.canViewGrandInvoice([
          buildInvoice(id: 'g1', salesOrderId: ''),
        ]),
        isTrue,
      );
      expect(
        SalesContainerSyncHelper.canViewGrandInvoice([
          buildInvoice(id: 's1', salesOrderId: 'o1'),
        ]),
        isFalse,
      );
    });
  });
}
