import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/production_batch.dart';
import '../../domain/enums/invoice_enums.dart';

class DashboardAnalyticsService {
  DashboardAnalytics build({
    required List<Payment> payments,
    required List<ProductionBatch> productionBatches,
    required List<JobWorkOrder> jobWorkOrders,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);

    return DashboardAnalytics(
      productionLast7Days: _buildProductionSeries(
        productionBatches: productionBatches,
        jobWorkOrders: jobWorkOrders,
        endDate: today,
        dayCount: 7,
      ),
      revenueLast30Days: _buildRevenueSeries(
        payments: payments,
        endDate: today,
        dayCount: 30,
      ),
      revenueBreakdownThisMonth: _buildRevenueBreakdown(
        payments: payments,
        year: reference.year,
        month: reference.month,
      ),
      recentActivity: _buildRecentActivity(payments),
    );
  }

  List<DailyProductionPoint> _buildProductionSeries({
    required List<ProductionBatch> productionBatches,
    required List<JobWorkOrder> jobWorkOrders,
    required DateTime endDate,
    required int dayCount,
  }) {
    final startDate = endDate.subtract(Duration(days: dayCount - 1));
    final ownByDay = <DateTime, double>{};
    final jobWorkByDay = <DateTime, double>{};

    for (var offset = 0; offset < dayCount; offset++) {
      final day = startDate.add(Duration(days: offset));
      ownByDay[day] = 0;
      jobWorkByDay[day] = 0;
    }

    for (final batch in productionBatches) {
      final day = _dateOnly(batch.productionDate);
      if (day.isBefore(startDate) || day.isAfter(endDate)) continue;
      ownByDay[day] = (ownByDay[day] ?? 0) + batch.totalUsableSqFt;
    }

    for (final order in jobWorkOrders) {
      for (final shift in order.shiftLogs) {
        final day = _dateOnly(shift.shiftDate);
        if (day.isBefore(startDate) || day.isAfter(endDate)) continue;
        jobWorkByDay[day] = (jobWorkByDay[day] ?? 0) + shift.totalUsableSqFt;
      }
    }

    return List.generate(dayCount, (index) {
      final day = startDate.add(Duration(days: index));
      return DailyProductionPoint(
        date: day,
        ownProductionSqFt: ownByDay[day] ?? 0,
        jobWorkSqFt: jobWorkByDay[day] ?? 0,
      );
    });
  }

  List<DailyRevenuePoint> _buildRevenueSeries({
    required List<Payment> payments,
    required DateTime endDate,
    required int dayCount,
  }) {
    final startDate = endDate.subtract(Duration(days: dayCount - 1));
    final salesByDay = <DateTime, double>{};
    final jobWorkByDay = <DateTime, double>{};

    for (var offset = 0; offset < dayCount; offset++) {
      final day = startDate.add(Duration(days: offset));
      salesByDay[day] = 0;
      jobWorkByDay[day] = 0;
    }

    for (final payment in payments) {
      final day = _dateOnly(payment.paymentDate);
      if (day.isBefore(startDate) || day.isAfter(endDate)) continue;

      if (payment.invoiceType == InvoiceType.sales) {
        salesByDay[day] = (salesByDay[day] ?? 0) + payment.amount;
      } else {
        jobWorkByDay[day] = (jobWorkByDay[day] ?? 0) + payment.amount;
      }
    }

    return List.generate(dayCount, (index) {
      final day = startDate.add(Duration(days: index));
      return DailyRevenuePoint(
        date: day,
        salesAmount: salesByDay[day] ?? 0,
        jobWorkAmount: jobWorkByDay[day] ?? 0,
      );
    });
  }

  List<RevenueBreakdownSlice> _buildRevenueBreakdown({
    required List<Payment> payments,
    required int year,
    required int month,
  }) {
    var sales = 0.0;
    var jobWork = 0.0;

    for (final payment in payments) {
      final date = payment.paymentDate;
      if (date.year != year || date.month != month) continue;

      if (payment.invoiceType == InvoiceType.sales) {
        sales += payment.amount;
      } else {
        jobWork += payment.amount;
      }
    }

    return [
      RevenueBreakdownSlice(label: 'Sales', amount: sales),
      RevenueBreakdownSlice(label: 'Job Work', amount: jobWork),
    ];
  }

  List<RecentActivityItem> _buildRecentActivity(List<Payment> payments) {
    final sorted = [...payments]
      ..sort((a, b) {
        final dateCompare = b.paymentDate.compareTo(a.paymentDate);
        if (dateCompare != 0) return dateCompare;
        return b.createdAt.compareTo(a.createdAt);
      });

    return sorted.take(10).map((payment) {
      final typeLabel =
          payment.invoiceType == InvoiceType.sales ? 'Sales' : 'Job Work';
      return RecentActivityItem(
        id: payment.id,
        type: RecentActivityType.payment,
        title: 'Payment — ${payment.customerName}',
        subtitle: '$typeLabel · ${payment.invoiceNumber}',
        timestamp: payment.paymentDate,
        amount: payment.amount,
      );
    }).toList();
  }

  DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
