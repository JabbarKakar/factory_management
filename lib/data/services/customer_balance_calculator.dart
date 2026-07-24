import 'package:equatable/equatable.dart';

import '../../domain/entities/customer.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/entities/sales_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/sales_enums.dart';
import 'job_work_container_sync_helper.dart';

class CustomerFinancialSummary extends Equatable {
  const CustomerFinancialSummary({
    required this.customerId,
    required this.openingBalance,
    required this.totalRevenue,
    required this.totalPaid,
    required this.totalDue,
    required this.balanceStatus,
    this.nextDueDate,
    this.jobWorkOrderCount = 0,
    this.salesOrderCount = 0,
  });

  final String customerId;
  final double openingBalance;
  final double totalRevenue;
  final double totalPaid;
  final double totalDue;
  final CustomerBalanceStatus balanceStatus;
  final DateTime? nextDueDate;
  final int jobWorkOrderCount;
  final int salesOrderCount;

  @override
  List<Object?> get props => [
        customerId,
        openingBalance,
        totalRevenue,
        totalPaid,
        totalDue,
        balanceStatus,
        nextDueDate,
        jobWorkOrderCount,
        salesOrderCount,
      ];
}

abstract final class CustomerBalanceCalculator {
  static T? _firstWhereOrNull<T>(Iterable<T> items, bool Function(T) test) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }

  /// Calculates real-time financial summary for a customer combining both Sales and Job Work.
  static CustomerFinancialSummary calculateCustomerSummary({
    required Customer customer,
    required List<SalesOrder> salesOrders,
    required List<SalesInvoice> salesInvoices,
    required List<JobWorkOrder> jobWorkOrders,
    required List<JobWorkLoad> jobWorkLoads,
    required List<JobWorkInvoice> jobWorkInvoices,
    required List<Payment> payments,
  }) {
    final customerId = customer.id;

    // Filter active records for this customer
    final customerSalesOrders = salesOrders
        .where((o) => o.customerId == customerId && o.status != SalesOrderStatus.cancelled)
        .toList();
    final customerSalesInvoices = salesInvoices
        .where((i) => i.customerId == customerId && i.status != InvoiceStatus.cancelled)
        .toList();

    final customerJobWorkOrders = jobWorkOrders
        .where((o) => o.customerId == customerId && o.status != JobWorkStatus.cancelled)
        .toList();
    final customerJobWorkLoads = jobWorkLoads
        .where((l) => l.customerId == customerId && l.status != JobWorkStatus.cancelled)
        .toList();
    final customerJobWorkInvoices = jobWorkInvoices
        .where((i) => i.customerId == customerId && i.status != InvoiceStatus.cancelled)
        .toList();

    var salesRevenue = 0.0;
    var salesPaid = 0.0;
    var salesDue = 0.0;

    DateTime? nextDueDate;

    // 1. Calculate Sales
    for (final order in customerSalesOrders) {
      final matchingInvoice = _firstWhereOrNull(
        customerSalesInvoices,
        (i) => i.salesOrderId == order.id,
      );

      if (matchingInvoice != null) {
        salesRevenue += matchingInvoice.totalAmount;
        salesPaid += matchingInvoice.paidAmount;
        salesDue += matchingInvoice.dueAmount;
        if (matchingInvoice.dueAmount > 0 && matchingInvoice.dueDate != null) {
          if (nextDueDate == null || matchingInvoice.dueDate!.isBefore(nextDueDate)) {
            nextDueDate = matchingInvoice.dueDate;
          }
        }
      } else {
        salesRevenue += order.grandTotal;
        salesPaid += order.advanceReceived;
        salesDue += order.balanceDue;
        final dueDate = order.paymentDueDate ?? order.expectedDeliveryDate;
        if (order.balanceDue > 0 && dueDate != null) {
          if (nextDueDate == null || dueDate.isBefore(nextDueDate)) {
            nextDueDate = dueDate;
          }
        }
      }
    }

    // Include orphaned sales invoices not linked to an order
    for (final inv in customerSalesInvoices) {
      if (inv.salesOrderId.isEmpty || !customerSalesOrders.any((o) => o.id == inv.salesOrderId)) {
        salesRevenue += inv.totalAmount;
        salesPaid += inv.paidAmount;
        salesDue += inv.dueAmount;
        if (inv.dueAmount > 0 && inv.dueDate != null) {
          if (nextDueDate == null || inv.dueDate!.isBefore(nextDueDate)) {
            nextDueDate = inv.dueDate;
          }
        }
      }
    }

    // 2. Calculate Job Work (using JobWorkContainerSyncHelper for exact rollup)
    var jobWorkRevenue = 0.0;
    var jobWorkPaid = 0.0;
    var jobWorkDue = 0.0;

    for (final order in customerJobWorkOrders) {
      final orderInvoices = customerJobWorkInvoices
          .where((i) => i.jobWorkId == order.id)
          .toList();
      final fin = JobWorkContainerSyncHelper.rollupInvoiceFinance(
        order: order,
        loads: customerJobWorkLoads,
        invoices: orderInvoices,
      );

      jobWorkRevenue += fin.charges;
      jobWorkPaid += fin.paid;
      jobWorkDue += fin.due;

      // Track earliest due date among open invoices/loads
      for (final inv in orderInvoices) {
        if (inv.dueAmount > 0 && inv.dueDate != null) {
          if (nextDueDate == null || inv.dueDate!.isBefore(nextDueDate)) {
            nextDueDate = inv.dueDate;
          }
        }
      }
      final orderLoads = JobWorkContainerSyncHelper.activeLoadsForFinance(
        order,
        customerJobWorkLoads,
      );
      for (final load in orderLoads) {
        final date = load.paymentDueDate ?? order.paymentDueDate;
        if (load.balanceDue > 0 && date != null) {
          if (nextDueDate == null || date.isBefore(nextDueDate)) {
            nextDueDate = date;
          }
        }
      }
      if (orderLoads.isEmpty && order.balanceDue > 0 && order.paymentDueDate != null) {
        if (nextDueDate == null || order.paymentDueDate!.isBefore(nextDueDate)) {
          nextDueDate = order.paymentDueDate;
        }
      }
    }

    // 3. Totals
    final totalRevenue = salesRevenue + jobWorkRevenue;
    final totalPaid = salesPaid + jobWorkPaid;
    final netCalculatedDue = customer.openingBalance + totalRevenue - totalPaid;
    final totalDue = netCalculatedDue > 0 ? netCalculatedDue : 0.0;

    // 4. Status Evaluation
    final CustomerBalanceStatus balanceStatus;
    if (totalDue <= 0) {
      balanceStatus = CustomerBalanceStatus.paidUp;
      nextDueDate = null;
    } else if (nextDueDate == null) {
      balanceStatus = CustomerBalanceStatus.outstanding;
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
      final diff = dueDay.difference(today).inDays;

      if (diff < 0) {
        balanceStatus = CustomerBalanceStatus.overdue;
      } else if (diff == 0) {
        balanceStatus = CustomerBalanceStatus.dueToday;
      } else if (diff <= 7) {
        balanceStatus = CustomerBalanceStatus.dueSoon;
      } else {
        balanceStatus = CustomerBalanceStatus.outstanding;
      }
    }

    return CustomerFinancialSummary(
      customerId: customerId,
      openingBalance: customer.openingBalance,
      totalRevenue: totalRevenue,
      totalPaid: totalPaid,
      totalDue: totalDue,
      balanceStatus: balanceStatus,
      nextDueDate: nextDueDate,
      jobWorkOrderCount: customerJobWorkOrders.length,
      salesOrderCount: customerSalesOrders.length,
    );
  }
}
