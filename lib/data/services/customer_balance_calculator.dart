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
import 'sales_container_sync_helper.dart';

class CustomerFinancialSummary extends Equatable {
  const CustomerFinancialSummary({
    required this.customerId,
    required this.openingBalance,
    required this.totalRevenue,
    required this.totalPaid,
    required this.totalDue,
    required this.balanceStatus,
    this.unallocatedCredit = 0.0,
    this.nextDueDate,
    this.jobWorkOrderCount = 0,
    this.salesOrderCount = 0,
  });

  final String customerId;
  final double openingBalance;
  final double totalRevenue;
  final double totalPaid;
  final double totalDue;
  final double unallocatedCredit;
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
        unallocatedCredit,
        balanceStatus,
        nextDueDate,
        jobWorkOrderCount,
        salesOrderCount,
      ];
}

abstract final class CustomerBalanceCalculator {
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

    final customerSalesOrders = salesOrders
        .where(
          (order) =>
              order.customerId == customerId &&
              order.status != SalesOrderStatus.cancelled,
        )
        .toList();
    final customerSalesInvoices = salesInvoices
        .where(
          (invoice) =>
              invoice.customerId == customerId &&
              invoice.status != InvoiceStatus.cancelled,
        )
        .toList();

    final customerJobWorkOrders = jobWorkOrders
        .where(
          (order) =>
              order.customerId == customerId &&
              order.status != JobWorkStatus.cancelled,
        )
        .toList();
    final customerJobWorkLoads = jobWorkLoads
        .where(
          (load) =>
              load.customerId == customerId &&
              load.status != JobWorkStatus.cancelled,
        )
        .toList();
    final customerJobWorkInvoices = jobWorkInvoices
        .where(
          (invoice) =>
              invoice.customerId == customerId &&
              invoice.status != InvoiceStatus.cancelled,
        )
        .toList();

    final validPayments = payments
        .where((payment) =>
            payment.customerId == customerId &&
            payment.status != PaymentStatus.voided)
        .toList();

    var salesRevenue = 0.0;
    var salesPaid = 0.0;
    DateTime? nextDueDate;

    // 1. Sales — prefer active single-order invoices (exclude Grand from orphan path).
    final coveredOrderIds = <String>{};
    for (final order in customerSalesOrders) {
      coveredOrderIds.add(order.id);
      final invoice = SalesContainerSyncHelper.preferActiveSingleInvoice(
        customerSalesInvoices.where(
          (item) => item.salesOrderId == order.id,
        ),
      );
      final finance = SalesContainerSyncHelper.financeForOrder(
        order: order,
        invoice: invoice,
      );
      salesRevenue += finance.charges;
      salesPaid += finance.paid;

      final dueDate = invoice?.dueDate ??
          order.paymentDueDate ??
          order.expectedDeliveryDate;
      if (finance.due > 0 && dueDate != null) {
        if (nextDueDate == null || dueDate.isBefore(nextDueDate)) {
          nextDueDate = dueDate;
        }
      }
    }

    final agreementsWithOrders = customerSalesOrders
        .map((order) => order.agreementId?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    for (final invoice in customerSalesInvoices) {
      if (invoice.isGrandInvoice) {
        // Grand paid/charges already reflected via order rollups when orders exist.
        final agreementId = invoice.agreementId?.trim() ?? '';
        if (agreementId.isNotEmpty &&
            agreementsWithOrders.contains(agreementId)) {
          continue;
        }
        // Legacy/orphan grand with no linked active orders — count once.
      } else if (coveredOrderIds.contains(invoice.salesOrderId)) {
        continue;
      }

      salesRevenue += invoice.totalAmount;
      salesPaid += invoice.paidAmount;
      if (invoice.dueAmount > 0 && invoice.dueDate != null) {
        if (nextDueDate == null || invoice.dueDate!.isBefore(nextDueDate)) {
          nextDueDate = invoice.dueDate;
        }
      }
    }

    // 2. Job Work (container helper rollup)
    var jobWorkRevenue = 0.0;
    var jobWorkPaid = 0.0;

    for (final order in customerJobWorkOrders) {
      final orderInvoices = customerJobWorkInvoices
          .where((invoice) => invoice.jobWorkId == order.id)
          .toList();
      final siblingOrderIds = {
        for (final other in customerJobWorkOrders)
          if (other.id != order.id) other.id,
      };
      final finance = JobWorkContainerSyncHelper.rollupInvoiceFinance(
        order: order,
        loads: customerJobWorkLoads,
        invoices: orderInvoices,
        payments: validPayments,
        siblingOrderIds: siblingOrderIds,
        attachDanglingCustomerPayments: siblingOrderIds.isEmpty,
      );

      jobWorkRevenue += finance.charges;
      jobWorkPaid += finance.paid;

      for (final invoice in orderInvoices) {
        if (invoice.dueAmount > 0 && invoice.dueDate != null) {
          if (nextDueDate == null || invoice.dueDate!.isBefore(nextDueDate)) {
            nextDueDate = invoice.dueDate;
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
      if (orderLoads.isEmpty &&
          order.balanceDue > 0 &&
          order.paymentDueDate != null) {
        if (nextDueDate == null ||
            order.paymentDueDate!.isBefore(nextDueDate)) {
          nextDueDate = order.paymentDueDate;
        }
      }
    }

    final paymentCash = validPayments.fold<double>(
      0,
      (sum, payment) => sum + payment.amount,
    );

    final totalRevenue = double.parse((salesRevenue + jobWorkRevenue).toStringAsFixed(2));
    final rollupPaid = double.parse((salesPaid + jobWorkPaid).toStringAsFixed(2));
    final totalPaid = validPayments.isNotEmpty
        ? double.parse(paymentCash.toStringAsFixed(2))
        : rollupPaid;
    final netCalculatedDue = double.parse(
      (customer.openingBalance + totalRevenue - totalPaid).toStringAsFixed(2),
    );
    final totalDue = netCalculatedDue > 0 ? netCalculatedDue : 0.0;
    final unallocatedCredit = netCalculatedDue < 0 ? (-netCalculatedDue) : 0.0;

    final CustomerBalanceStatus balanceStatus;
    if (unallocatedCredit > 0) {
      balanceStatus = CustomerBalanceStatus.inCredit;
      nextDueDate = null;
    } else if (totalDue <= 0) {
      balanceStatus = CustomerBalanceStatus.paidUp;
      nextDueDate = null;
    } else if (nextDueDate == null) {
      balanceStatus = CustomerBalanceStatus.outstanding;
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueDay = DateTime(
        nextDueDate.year,
        nextDueDate.month,
        nextDueDate.day,
      );
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
      unallocatedCredit: unallocatedCredit,
      balanceStatus: balanceStatus,
      nextDueDate: nextDueDate,
      jobWorkOrderCount: customerJobWorkOrders.length,
      salesOrderCount: customerSalesOrders.length,
    );
  }
}
