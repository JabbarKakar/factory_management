import 'package:factory_management/data/services/customer_balance_calculator.dart';
import 'package:factory_management/domain/entities/customer.dart';
import 'package:factory_management/domain/entities/job_work_load.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/entities/sales_invoice.dart';
import 'package:factory_management/domain/entities/sales_order.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';
import 'package:factory_management/domain/enums/job_work_load_enums.dart';
import 'package:factory_management/domain/enums/sales_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCustomer = Customer(
    id: 'cust-1',
    factoryId: 'factory-1',
    customerType: CustomerType.individual,
    name: 'Hussain',
    phone: '1234567890',
    serviceType: CustomerServiceType.jobWork,
    category: CustomerCategory.retail,
    paymentTerms: PaymentTerms.cash,
    creditLimit: 0,
    balance: 50000,
    openingBalance: 0,
    nextDueDate: DateTime.now().add(const Duration(days: 2)),
    createdAt: DateTime.now(),
  );

  group('CustomerBalanceCalculator', () {
    test('returns \$0 due balance and paidUp status when all collections are empty (e.g. deleted)', () {
      final summary = CustomerBalanceCalculator.calculateCustomerSummary(
        customer: testCustomer,
        salesOrders: const [],
        salesInvoices: const [],
        jobWorkOrders: const [],
        jobWorkLoads: const [],
        jobWorkInvoices: const [],
        payments: const [],
      );

      expect(summary.customerId, 'cust-1');
      expect(summary.totalRevenue, 0.0);
      expect(summary.totalPaid, 0.0);
      expect(summary.totalDue, 0.0);
      expect(summary.balanceStatus, CustomerBalanceStatus.paidUp);
      expect(summary.nextDueDate, isNull);
      expect(summary.jobWorkOrderCount, 0);
      expect(summary.salesOrderCount, 0);
    });

    test('correctly calculates Job Work revenue, paid, and remaining due matching Job Work screen', () {
      final now = DateTime.now();
      final dueDate = now.add(const Duration(days: 3));

      final order = JobWorkOrder(
        id: 'jw-1',
        factoryId: 'factory-1',
        jobWorkNumber: 'JW-001',
        customerId: 'cust-1',
        customerName: 'Hussain',
        status: JobWorkStatus.inCutting,
        marbleVariety: 'White',
        blockCount: 1,
        totalTons: 10,
        cuttingStrategy: CuttingStrategy.bridgeSaw,
        targetProduct: TargetProduct.tiles,
        thickness: '18mm',
        finish: FinishType.polished,
        pricingModel: PricingModel.perSqFt,
        receivedDate: now,
        agreedRate: 100,
        finalCuttingCharges: 1000,
        advanceReceived: 200,
        balanceDue: 800,
        paymentTerms: PaymentTerms.cash,
        paymentDueDate: dueDate,
        createdAt: now,
      );

      final load = JobWorkLoad(
        id: 'load-1',
        jobWorkId: 'jw-1',
        jobWorkNumber: 'JW-001',
        loadNumber: '1',
        loadSequence: 1,
        factoryId: 'factory-1',
        customerId: 'cust-1',
        customerName: 'Hussain',
        status: JobWorkStatus.inCutting,
        marbleVariety: 'White',
        blockCount: 1,
        totalTons: 10,
        cuttingStrategy: CuttingStrategy.bridgeSaw,
        targetProduct: TargetProduct.tiles,
        thickness: '18mm',
        finish: FinishType.polished,
        pricingModel: PricingModel.perSqFt,
        receivedDate: now,
        agreedRate: 100,
        finalCuttingCharges: 1000,
        advanceReceived: 200,
        balanceDue: 800,
        paymentTerms: PaymentTerms.cash,
        paymentDueDate: dueDate,
        createdAt: now,
      );

      final summary = CustomerBalanceCalculator.calculateCustomerSummary(
        customer: testCustomer,
        salesOrders: const [],
        salesInvoices: const [],
        jobWorkOrders: [order],
        jobWorkLoads: [load],
        jobWorkInvoices: const [],
        payments: const [],
      );

      expect(summary.totalRevenue, 1000.0);
      expect(summary.totalPaid, 200.0);
      expect(summary.totalDue, 800.0);
      expect(summary.balanceStatus, CustomerBalanceStatus.dueSoon);
      expect(summary.nextDueDate, dueDate);
      expect(summary.jobWorkOrderCount, 1);
    });

    test('sales rollup prefers order invoice and skips grand double-count', () {
      final now = DateTime.now();
      final order = SalesOrder(
        id: 'o1',
        orderNumber: 'ORD-1',
        factoryId: 'factory-1',
        customerId: 'cust-1',
        customerName: 'Hussain',
        status: SalesOrderStatus.invoiced,
        orderDate: now,
        orderSource: SalesOrderSource.walkIn,
        lineItems: const [],
        subtotal: 1000,
        orderDiscount: 0,
        tax: 0,
        grandTotal: 1000,
        paymentTerms: PaymentTerms.cash,
        advanceReceived: 100,
        balanceDue: 900,
        createdAt: now,
        agreementId: 'sa-1',
        agreementNumber: 'SA-1',
      );
      final orderInvoice = SalesInvoice(
        id: 'inv-1',
        invoiceNumber: 'INV-1',
        factoryId: 'factory-1',
        agreementId: 'sa-1',
        agreementNumber: 'SA-1',
        salesOrderId: 'o1',
        orderNumber: 'ORD-1',
        customerId: 'cust-1',
        customerName: 'Hussain',
        lineItems: const [],
        totalAmount: 1000,
        paidAmount: 400,
        dueAmount: 600,
        status: InvoiceStatus.partial,
        createdAt: now,
      );
      final grand = SalesInvoice(
        id: 'grand-1',
        invoiceNumber: 'INV-G',
        factoryId: 'factory-1',
        agreementId: 'sa-1',
        agreementNumber: 'SA-1',
        salesOrderId: '',
        orderNumber: '',
        customerId: 'cust-1',
        customerName: 'Hussain',
        lineItems: const [],
        totalAmount: 1000,
        paidAmount: 400,
        dueAmount: 600,
        status: InvoiceStatus.partial,
        createdAt: now,
      );

      final summary = CustomerBalanceCalculator.calculateCustomerSummary(
        customer: testCustomer,
        salesOrders: [order],
        salesInvoices: [orderInvoice, grand],
        jobWorkOrders: const [],
        jobWorkLoads: const [],
        jobWorkInvoices: const [],
        payments: const [],
      );

      expect(summary.totalRevenue, 1000.0);
      expect(summary.totalPaid, 400.0);
      expect(summary.totalDue, 600.0);
      expect(summary.salesOrderCount, 1);
    });

    test('hybrid customer combines sales and Job Work without double-counting', () {
      final now = DateTime.now();
      final hybrid = testCustomer.copyWith(
        serviceType: CustomerServiceType.both,
      );
      final job = JobWorkOrder(
        id: 'jw-hybrid', factoryId: 'factory-1', jobWorkNumber: 'JW-H',
        customerId: 'cust-1', customerName: 'Hussain',
        status: JobWorkStatus.ready, marbleVariety: 'White', blockCount: 1,
        totalTons: 1, cuttingStrategy: CuttingStrategy.bridgeSaw,
        targetProduct: TargetProduct.tiles, thickness: '18mm',
        finish: FinishType.polished, pricingModel: PricingModel.perSqFt,
        receivedDate: now, agreedRate: 1, finalCuttingCharges: 1000,
        advanceReceived: 400, balanceDue: 600, paymentTerms: PaymentTerms.cash,
        createdAt: now,
      );
      final sale = SalesOrder(
        id: 'sale-hybrid', orderNumber: 'SO-H', factoryId: 'factory-1',
        customerId: 'cust-1', customerName: 'Hussain',
        status: SalesOrderStatus.received, orderDate: now,
        orderSource: SalesOrderSource.walkIn, lineItems: const [],
        subtotal: 500, orderDiscount: 0, tax: 0, grandTotal: 500,
        paymentTerms: PaymentTerms.cash, advanceReceived: 100,
        balanceDue: 400, createdAt: now,
      );

      final summary = CustomerBalanceCalculator.calculateCustomerSummary(
        customer: hybrid, salesOrders: [sale], salesInvoices: const [],
        jobWorkOrders: [job], jobWorkLoads: const [],
        jobWorkInvoices: const [], payments: const [],
      );

      expect(summary.totalRevenue, 1500);
      expect(summary.totalPaid, 500);
      expect(summary.totalDue, 1000);
      expect(summary.jobWorkOrderCount, 1);
      expect(summary.salesOrderCount, 1);
    });
  });
}
