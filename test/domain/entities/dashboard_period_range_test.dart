import 'package:factory_management/core/utils/dashboard_command_center_builder.dart';
import 'package:factory_management/domain/entities/dashboard_cashflow_metrics.dart';
import 'package:factory_management/domain/entities/delivery.dart';
import 'package:factory_management/domain/entities/payment.dart';
import 'package:factory_management/domain/entities/sales_order.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/dashboard_finance_period.dart';
import 'package:factory_management/domain/enums/delivery_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:factory_management/domain/enums/sales_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DashboardFinancePeriodRange', () {
    final now = DateTime(2026, 8, 17);

    test('yearly uses rolling 12-month window', () {
      final range = DashboardFinancePeriodRange.forPeriod(
        DashboardFinancePeriod.yearly,
        now,
      );

      expect(range.currentStart, DateTime(2025, 8, 1));
      expect(range.currentEnd, DateTime(2026, 8, 17));
      expect(range.previousStart, DateTime(2024, 8, 1));
    });

    test('allTime uses earliestDate when provided', () {
      final earliest = DateTime(2024, 4, 10);
      final range = DashboardFinancePeriodRange.forPeriod(
        DashboardFinancePeriod.allTime,
        now,
        earliestDate: earliest,
      );

      expect(range.currentStart, DateTime(2024, 4, 1));
      expect(range.currentEnd, DateTime(2026, 8, 17));
    });

    test('allTime enforces minimum 6-month window when earliestDate is recent or null', () {
      final range = DashboardFinancePeriodRange.forPeriod(
        DashboardFinancePeriod.allTime,
        now,
      );

      expect(range.currentStart, DateTime(2026, 3, 1));
      expect(range.currentEnd, DateTime(2026, 8, 17));
    });
  });

  group('DashboardCommandCenterBuilder.findEarliestTransactionDate', () {
    test('finds earliest date among payments and factory createdAt', () {
      final p1 = Payment(
        id: 'p1',
        factoryId: 'f1',
        customerId: 'c1',
        customerName: 'Test Customer',
        invoiceId: 'inv1',
        invoiceType: InvoiceType.sales,
        invoiceNumber: 'INV-001',
        amount: 500,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2024, 5, 12),
        createdAt: DateTime(2024, 5, 12),
      );

      final factoryCreated = DateTime(2024, 3, 1);

      final result = DashboardCommandCenterBuilder.findEarliestTransactionDate(
        factoryCreatedAt: factoryCreated,
        payments: [p1],
      );

      expect(result, DateTime(2024, 3, 1));
    });
  });

  group('DashboardCommandCenterBuilder dispatch metrics', () {
    test('correctly categorizes small vs large deliveries by size', () {
      final today = DateTime(2026, 8, 17);
      final d1 = Delivery(
        id: 'd1',
        deliveryNumber: 'DEL-001',
        factoryId: 'f1',
        salesOrderId: 'so1',
        salesOrderNumber: 'SO-001',
        customerId: 'c1',
        customerName: 'Customer 1',
        deliveryAddress: 'Addr',
        scheduledDate: today,
        status: DeliveryStatus.delivered,
        createdAt: today,
        lineItems: const [
          DeliveryLineItem(
            productType: SalesProductType.custom,
            marbleVariety: 'Variety',
            sizeThickness: '12x24',
            pieces: 10,
            squareFeet: 200,
          ),
          DeliveryLineItem(
            productType: SalesProductType.custom,
            marbleVariety: 'Variety',
            sizeThickness: '12x60',
            pieces: 5,
            squareFeet: 250,
          ),
          DeliveryLineItem(
            productType: SalesProductType.tile,
            marbleVariety: 'Variety',
            sizeThickness: '6x24',
            pieces: 20,
            squareFeet: 200,
          ),
        ],
      );

      final cc = DashboardCommandCenterBuilder.build(
        period: DashboardFinancePeriod.monthly,
        now: today,
        payments: const [],
        expenses: const [],
        jobWorkOrders: const [],
        jobWorkLoads: const [],
        jobWorkInvoices: const [],
        salesInvoices: const [],
        salesOrders: const [],
        deliveries: [d1],
        activeJobWorks: 0,
      );

      expect(cc.saleDispatchMetrics.largePieces, 15);
      expect(cc.saleDispatchMetrics.largeSqFt, 450);
      expect(cc.saleDispatchMetrics.smallPieces, 20);
      expect(cc.saleDispatchMetrics.smallSqFt, 200);
    });
  });

  group('DashboardCommandCenterBuilder receivables', () {
    test('includes uninvoiced sales order balance due like the Sales list', () {
      final today = DateTime(2026, 8, 21);
      final order = SalesOrder(
        id: 'so-1',
        orderNumber: 'SO-1',
        factoryId: 'f1',
        customerId: 'c1',
        customerName: 'Hussain',
        status: SalesOrderStatus.ready,
        orderDate: today,
        orderSource: SalesOrderSource.walkIn,
        lineItems: const [],
        subtotal: 16680000,
        orderDiscount: 0,
        tax: 0,
        grandTotal: 16680000,
        paymentTerms: PaymentTerms.cash,
        advanceReceived: 1590000,
        balanceDue: 16680000,
        createdAt: today,
        agreementId: 'sa-1',
      );

      final cc = DashboardCommandCenterBuilder.build(
        period: DashboardFinancePeriod.daily,
        now: today,
        payments: const [],
        expenses: const [],
        jobWorkOrders: const [],
        jobWorkLoads: const [],
        jobWorkInvoices: const [],
        salesInvoices: const [],
        salesOrders: [order],
        deliveries: const [],
        activeJobWorks: 0,
      );

      expect(cc.salesOutstanding, 16680000);
      expect(cc.jobWorkOutstanding, 0);
      expect(cc.outstanding, 16680000);
      expect(cc.outstandingCount, 1);
    });
  });
}
