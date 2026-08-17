import 'package:factory_management/domain/entities/dashboard_analytics.dart';
import 'package:factory_management/domain/entities/dashboard_command_center.dart';
import 'package:factory_management/domain/entities/dashboard_kpis.dart';
import 'package:factory_management/domain/enums/dashboard_finance_period.dart';
import 'package:factory_management/blocs/dashboard/dashboard_bloc.dart';
import 'package:factory_management/presentation/widgets/dashboard/command_center/dashboard_command_center_view.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestWidget({required DashboardFinancePeriod period}) {
    final cashflowSeries = [
      DashboardCashflowPoint(
        date: DateTime(2026, 1, 1),
        income: 150000,
        expenses: 100000,
        label: 'Jan',
      ),
      DashboardCashflowPoint(
        date: DateTime(2026, 2, 1),
        income: 200000,
        expenses: 120000,
        label: 'Feb',
      ),
    ];

    final commandCenter = DashboardCommandCenter(
      period: period,
      income: 350000,
      expenses: 220000,
      previousIncome: 300000,
      previousExpenses: 200000,
      outstanding: 50000,
      outstandingCount: 2,
      collectedInPeriod: 350000,
      incomeSparkline: const [150000, 200000],
      expenseSparkline: const [100000, 120000],
      cashflowSeries: cashflowSeries,
      salesVsJobWorkSeries: const [],
      smallStockSqFt: 100,
      largeStockSqFt: 200,
      wasteYieldSqFt: 10,
      smallStockAmount: 1000,
      largeStockAmount: 2000,
      salesSmallSqFt: 80,
      salesLargeSqFt: 150,
      salesSmallAmount: 800,
      salesLargeAmount: 1500,
      activeJobWorks: 5,
      activeDispatches: 3,
      throughputSqFt: 300,
    );

    final state = DashboardState(
      status: DashboardStatus.loaded,
      commandCenter: commandCenter,
      kpis: DashboardKpis.empty,
      analytics: DashboardAnalytics.empty,
    );

    return MaterialApp(
      home: Scaffold(
        body: DashboardCommandCenterView(
          state: state,
          user: null,
        ),
      ),
    );
  }

  testWidgets('hides bottom X-axis titles when period is allTime', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(period: DashboardFinancePeriod.allTime));
    await tester.pump();

    final lineChartFinder = find.byWidgetPredicate(
      (w) => w is LineChart && w.data.lineBarsData.length == 2,
    );
    expect(lineChartFinder, findsOneWidget);

    final lineChart = tester.widget<LineChart>(lineChartFinder);
    expect(lineChart.data.titlesData.bottomTitles.sideTitles.showTitles, isFalse);
  });

  testWidgets('shows bottom X-axis titles when period is not allTime', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(period: DashboardFinancePeriod.monthly));
    await tester.pump();

    final lineChartFinder = find.byWidgetPredicate(
      (w) => w is LineChart && w.data.lineBarsData.length == 2,
    );
    expect(lineChartFinder, findsOneWidget);

    final lineChart = tester.widget<LineChart>(lineChartFinder);
    expect(lineChart.data.titlesData.bottomTitles.sideTitles.showTitles, isTrue);
  });
}
