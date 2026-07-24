import 'package:factory_management/data/services/customer_balance_calculator.dart';
import 'package:factory_management/domain/entities/customer.dart';
import 'package:factory_management/domain/entities/job_work_load.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';
import 'package:factory_management/domain/enums/job_work_load_enums.dart';
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
  });
}
