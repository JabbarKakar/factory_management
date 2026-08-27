import '../../domain/entities/dashboard_monthly_rollup.dart';

class DashboardMonthlyRollupModel {
  const DashboardMonthlyRollupModel({required this.rollup});

  final DashboardMonthlyRollup rollup;

  factory DashboardMonthlyRollupModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final yearMonth = data['yearMonth'] as String? ?? '';
    final parsed = yearMonth.split('-');
    final year = (data['year'] as num?)?.toInt() ??
        (parsed.length == 2 ? int.tryParse(parsed[0]) ?? 0 : 0);
    final month = (data['month'] as num?)?.toInt() ??
        (parsed.length == 2 ? int.tryParse(parsed[1]) ?? 0 : 0);
    return DashboardMonthlyRollupModel(
      rollup: DashboardMonthlyRollup(
        id: id,
        factoryId: data['factoryId'] as String? ?? '',
        yearMonth: yearMonth.isEmpty
            ? DashboardRollupIds.yearMonth(DateTime(year, month, 1))
            : yearMonth,
        year: year,
        month: month,
        income: (data['income'] as num?)?.toDouble() ?? 0,
        incomeSales: (data['incomeSales'] as num?)?.toDouble() ?? 0,
        incomeJobWork: (data['incomeJobWork'] as num?)?.toDouble() ?? 0,
        expenses: (data['expenses'] as num?)?.toDouble() ?? 0,
        stockCutSmallSqFt: (data['stockCutSmallSqFt'] as num?)?.toDouble() ?? 0,
        stockCutLargeSqFt: (data['stockCutLargeSqFt'] as num?)?.toDouble() ?? 0,
        stockCutSmallAmount:
            (data['stockCutSmallAmount'] as num?)?.toDouble() ?? 0,
        stockCutLargeAmount:
            (data['stockCutLargeAmount'] as num?)?.toDouble() ?? 0,
        salesSmallSqFt: (data['salesSmallSqFt'] as num?)?.toDouble() ?? 0,
        salesLargeSqFt: (data['salesLargeSqFt'] as num?)?.toDouble() ?? 0,
        salesSmallAmount: (data['salesSmallAmount'] as num?)?.toDouble() ?? 0,
        salesLargeAmount: (data['salesLargeAmount'] as num?)?.toDouble() ?? 0,
      ),
    );
  }

  DashboardMonthlyRollup toEntity() => rollup;

  Map<String, dynamic> toFirestore() {
    return {
      'factoryId': rollup.factoryId,
      'yearMonth': rollup.yearMonth,
      'year': rollup.year,
      'month': rollup.month,
      'income': rollup.income,
      'incomeSales': rollup.incomeSales,
      'incomeJobWork': rollup.incomeJobWork,
      'expenses': rollup.expenses,
      'stockCutSmallSqFt': rollup.stockCutSmallSqFt,
      'stockCutLargeSqFt': rollup.stockCutLargeSqFt,
      'stockCutSmallAmount': rollup.stockCutSmallAmount,
      'stockCutLargeAmount': rollup.stockCutLargeAmount,
      'salesSmallSqFt': rollup.salesSmallSqFt,
      'salesLargeSqFt': rollup.salesLargeSqFt,
      'salesSmallAmount': rollup.salesSmallAmount,
      'salesLargeAmount': rollup.salesLargeAmount,
    };
  }
}

abstract final class DashboardRollupIds {
  static String yearMonth(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    return '${date.year}-$month';
  }

  static String docId(String factoryId, DateTime date) =>
      '${factoryId}__${yearMonth(date)}';

  static DateTime monthStart(DateTime date) => DateTime(date.year, date.month, 1);
}
