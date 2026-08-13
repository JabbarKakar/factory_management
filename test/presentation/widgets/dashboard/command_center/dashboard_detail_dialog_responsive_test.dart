import 'package:factory_management/domain/entities/job_work_dispatch_metrics.dart';
import 'package:factory_management/domain/enums/dashboard_finance_period.dart';
import 'package:factory_management/presentation/widgets/dashboard/command_center/job_work_sale_dispatch_detail_dialog.dart';
import 'package:factory_management/presentation/widgets/dashboard/command_center/stock_cut_detail_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const phoneSize = Size(360, 800);

  Future<void> pumpOnPhone(WidgetTester tester, Widget dialog) async {
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: dialog)));
    await tester.pumpAndSettle();
  }

  testWidgets('job work and dispatch dialog fits a phone viewport', (
    tester,
  ) async {
    final metrics = {
      for (final period in DashboardFinancePeriod.values)
        period: const JobWorkDispatchCategoryMetrics(
          largePieces: 120,
          largeSqFt: 184.56,
          smallPieces: 40,
          smallSqFt: 61.52,
        ),
    };

    await pumpOnPhone(
      tester,
      JobWorkSaleDispatchDetailDialog(
        jobWorkMetricsMap: metrics,
        saleDispatchMetricsMap: metrics,
        initialPeriod: DashboardFinancePeriod.monthly,
      ),
    );

    expect(find.text('Job Work Collection Detail'), findsOneWidget);
    expect(find.text('PERIOD:'), findsNothing);
    for (final period in DashboardFinancePeriod.values) {
      expect(find.text(period.label), findsNothing);
    }
    expect(find.textContaining('(MONTHLY)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('stock cut and sold dialog fits a phone viewport', (
    tester,
  ) async {
    await pumpOnPhone(
      tester,
      const StockCutDetailDialog(
        smallSqFt: 450,
        largeSqFt: 1200,
        wasteSqFt: 80,
        smallAmount: 45000,
        largeAmount: 120000,
        salesSmallSqFt: 300,
        salesLargeSqFt: 900,
        salesSmallAmount: 30000,
        salesLargeAmount: 90000,
      ),
    );

    expect(find.text('Stock Cut Distribution'), findsOneWidget);
    expect(find.text('Sold'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
