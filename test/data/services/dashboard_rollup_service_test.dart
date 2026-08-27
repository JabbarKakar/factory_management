import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/data/models/dashboard_monthly_rollup_model.dart';
import 'package:factory_management/data/repositories/dashboard_rollup_repository.dart';
import 'package:factory_management/data/services/dashboard_rollup_service.dart';
import 'package:factory_management/domain/entities/dashboard_monthly_rollup.dart';
import 'package:factory_management/domain/entities/payment.dart';
import 'package:factory_management/domain/enums/dashboard_finance_period.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factoryId = 'factory-s41';
  final august = DateTime(2026, 8, 10);

  DashboardRollupService serviceFor(FakeFirebaseFirestore firestore) {
    return DashboardRollupService(
      firestore: firestore,
      repository: DashboardRollupRepository(firestore: firestore),
    );
  }

  Payment payment({
    required double amount,
    required DateTime date,
    InvoiceType type = InvoiceType.sales,
  }) {
    return Payment(
      id: 'p-${amount.toInt()}',
      factoryId: factoryId,
      customerId: 'c1',
      customerName: 'A',
      invoiceId: 'inv',
      invoiceType: type,
      invoiceNumber: 'INV',
      amount: amount,
      method: PaymentMethod.cash,
      paymentDate: date,
      createdAt: date,
    );
  }

  test('model round-trips factory month totals', () {
    const rollup = DashboardMonthlyRollup(
      id: 'factory-s41__2026-08',
      factoryId: factoryId,
      yearMonth: '2026-08',
      year: 2026,
      month: 8,
      income: 100,
      expenses: 40,
    );
    final map = DashboardMonthlyRollupModel(rollup: rollup).toFirestore();
    final parsed =
        DashboardMonthlyRollupModel.fromFirestore(rollup.id, map).toEntity();
    expect(parsed, rollup);
  });

  test('payment increment lands on the payment month', () async {
    final firestore = FakeFirebaseFirestore();
    final service = serviceFor(firestore);

    await service.applyPayment(payment: payment(amount: 250, date: august));

    final months = await service.getRange(
      factoryId: factoryId,
      from: DateTime(2026, 8, 1),
      to: DateTime(2026, 8, 1),
    );
    expect(months, hasLength(1));
    expect(months.single.income, 250);
    expect(months.single.incomeSales, 250);
    expect(months.single.incomeJobWork, 0);
  });

  test('backfill matches a raw recompute and reports no drift', () async {
    final firestore = FakeFirebaseFirestore();
    await firestore.collection('payments').doc('pay').set({
      'factoryId': factoryId,
      'customerId': 'c1',
      'customerName': 'A',
      'invoiceId': 'inv',
      'invoiceType': 'sales',
      'invoiceNumber': 'INV',
      'amount': 400,
      'method': 'cash',
      'date': Timestamp.fromDate(august),
      'status': 'completed',
      'createdAt': Timestamp.fromDate(august),
    });
    await firestore.collection('expenses').doc('exp').set({
      'factoryId': factoryId,
      'expenseNumber': 'EXP',
      'expenseDate': Timestamp.fromDate(august),
      'category': 'electricity',
      'description': 'bill',
      'amount': 75,
      'paymentMethod': 'cash',
      'createdAt': Timestamp.fromDate(august),
    });

    final service = serviceFor(firestore);
    final report = await service.backfill(
      factoryId,
      now: DateTime(2026, 8, 27),
    );
    expect(report.isComplete, isTrue);
    expect(report.monthsWritten, greaterThan(0));

    final drift = await service.detectDrift(
      factoryId: factoryId,
      month: august,
    );
    expect(drift.hasDrift, isFalse);
    expect(drift.recomputed.income, 400);
    expect(drift.recomputed.expenses, 75);
  });

  test('yearly cashflow sums overlapping month rollups', () {
    final rollups = [
      DashboardMonthlyRollup(
        id: 'a',
        factoryId: factoryId,
        yearMonth: '2025-08',
        year: 2025,
        month: 8,
        income: 10,
        expenses: 1,
      ),
      DashboardMonthlyRollup(
        id: 'b',
        factoryId: factoryId,
        yearMonth: '2026-08',
        year: 2026,
        month: 8,
        income: 90,
        expenses: 9,
      ),
    ];
    final metrics = DashboardRollupService.cashflow(
      period: DashboardFinancePeriod.yearly,
      now: DateTime(2026, 8, 27),
      rollups: rollups,
    );
    expect(metrics.income, 100);
    expect(metrics.expenses, 10);
  });
}
