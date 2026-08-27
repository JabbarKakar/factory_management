import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/core/utils/dashboard_query_window.dart';
import 'package:factory_management/core/utils/firestore_query_constraints.dart';
import 'package:factory_management/domain/enums/dashboard_finance_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 8, 17);

  group('DashboardQueryWindow', () {
    test('Daily uses the 30-day analytics floor, not years of history', () {
      final window = DashboardQueryWindow.forDashboard(
        financePeriod: DashboardFinancePeriod.daily,
        stockCutPeriod: DashboardFinancePeriod.daily,
        salesSqFtPeriod: DashboardFinancePeriod.daily,
        now: now,
      );

      expect(window.from, DateTime(2026, 7, 18));
    });

    test('Monthly reaches back to the previous-period start', () {
      final window = DashboardQueryWindow.forDashboard(
        financePeriod: DashboardFinancePeriod.monthly,
        stockCutPeriod: DashboardFinancePeriod.daily,
        salesSqFtPeriod: DashboardFinancePeriod.daily,
        now: now,
      );

      expect(window.from, DateTime(2026, 7, 1));
    });

    test('Yearly and All Time do not widen the raw query (S41 rollups)', () {
      final yearly = DashboardQueryWindow.forDashboard(
        financePeriod: DashboardFinancePeriod.yearly,
        stockCutPeriod: DashboardFinancePeriod.yearly,
        salesSqFtPeriod: DashboardFinancePeriod.yearly,
        now: now,
      );
      final allTime = DashboardQueryWindow.forDashboard(
        financePeriod: DashboardFinancePeriod.allTime,
        stockCutPeriod: DashboardFinancePeriod.allTime,
        salesSqFtPeriod: DashboardFinancePeriod.allTime,
        now: now,
      );

      expect(yearly.from, DateTime(2026, 7, 18));
      expect(allTime.from, DateTime(2026, 7, 18));
    });

    test('long stock-cut period does not widen payments or expenses', () {
      final window = DashboardQueryWindow.forDashboard(
        financePeriod: DashboardFinancePeriod.daily,
        stockCutPeriod: DashboardFinancePeriod.yearly,
        salesSqFtPeriod: DashboardFinancePeriod.monthly,
        now: now,
      );

      expect(window.from, DateTime(2026, 7, 1));
    });
  });

  group('DashboardFinancePeriod labels', () {
    test('All Time is labelled as a 24-month window', () {
      expect(DashboardFinancePeriod.allTime.label, 'Last 24 mo');
      expect(DashboardFinancePeriod.allTime.vsPreviousLabel, 'vs prior 24 mo');
    });
  });

  group('constrainFactoryQuery', () {
    test('requires a date field when a lower bound is set', () {
      final query = FakeFirebaseFirestore().collection('payments');
      expect(
        () => constrainFactoryQuery(query, from: DateTime(2026, 8, 1)),
        throwsArgumentError,
      );
    });
  });
}
