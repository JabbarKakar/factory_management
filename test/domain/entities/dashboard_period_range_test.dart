import 'package:factory_management/core/utils/dashboard_command_center_builder.dart';
import 'package:factory_management/domain/entities/dashboard_cashflow_metrics.dart';
import 'package:factory_management/domain/entities/payment.dart';
import 'package:factory_management/domain/enums/dashboard_finance_period.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
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
}
