import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/data/repositories/customer_repository.dart';
import 'package:factory_management/data/repositories/job_work_invoice_repository.dart';
import 'package:factory_management/data/repositories/job_work_load_repository.dart';
import 'package:factory_management/data/repositories/job_work_repository.dart';
import 'package:factory_management/data/repositories/sales_invoice_repository.dart';
import 'package:factory_management/data/repositories/sales_order_repository.dart';
import 'package:factory_management/data/services/customer_ledger_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factoryId = 'factory-s40';
  const customerA = 'cust-a';
  const customerB = 'cust-b';

  group('customer-scoped repository queries', () {
    test('getSalesOrdersForCustomer does not return other customers', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('salesOrders').doc('so-a').set(
            _salesOrderData(customerId: customerA),
          );
      await firestore.collection('salesOrders').doc('so-b').set(
            _salesOrderData(customerId: customerB, orderNumber: 'SO-B'),
          );

      final orders = await SalesOrderRepository(firestore: firestore)
          .getSalesOrdersForCustomer(
        factoryId: factoryId,
        customerId: customerA,
      );

      expect(orders.map((order) => order.id), ['so-a']);
    });

    test('getOrdersForCustomer does not return other customers', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('jobWorkOrders').doc('jw-a').set(
            _jobWorkData(customerId: customerA),
          );
      await firestore.collection('jobWorkOrders').doc('jw-b').set(
            _jobWorkData(customerId: customerB, number: 'JW-B'),
          );

      final orders = await JobWorkRepository(firestore: firestore)
          .getOrdersForCustomer(
        factoryId: factoryId,
        customerId: customerA,
      );

      expect(orders.map((order) => order.id), ['jw-a']);
    });

    test('getLoadsForCustomer does not return other customers', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('jobWorkLoads').doc('load-a').set(
            _loadData(customerId: customerA, jobWorkId: 'jw-a'),
          );
      await firestore.collection('jobWorkLoads').doc('load-b').set(
            _loadData(
              customerId: customerB,
              jobWorkId: 'jw-b',
              loadNumber: 'L-B',
            ),
          );

      final loads = await JobWorkLoadRepository(firestore: firestore)
          .getLoadsForCustomer(
        factoryId: factoryId,
        customerId: customerA,
      );

      expect(loads.map((load) => load.id), ['load-a']);
    });
  });

  group('CustomerLedgerService', () {
    test('sync ignores another customer\'s orders and skips a no-op rewrite',
        () async {
      final firestore = FakeFirebaseFirestore();
      final jobWork = JobWorkRepository(firestore: firestore);
      final loads = JobWorkLoadRepository(
        firestore: firestore,
        jobWorkRepository: jobWork,
      );
      final salesOrders = SalesOrderRepository(firestore: firestore);
      final customers = CustomerRepository(firestore: firestore);

      await firestore.collection('customers').doc(customerA).set(
            _customerData(balance: 0, totalDue: 0, totalPaid: 0),
          );
      await firestore.collection('salesOrders').doc('so-a').set(
            _salesOrderData(customerId: customerA, grandTotal: 400, due: 400),
          );
      await firestore.collection('salesOrders').doc('so-b').set(
            _salesOrderData(
              customerId: customerB,
              orderNumber: 'SO-B',
              grandTotal: 99999,
              due: 99999,
            ),
          );

      final ledger = CustomerLedgerService(
        customerRepository: customers,
        jobWorkInvoiceRepository: JobWorkInvoiceRepository(
          firestore: firestore,
          jobWorkRepository: jobWork,
          loadRepository: loads,
        ),
        salesInvoiceRepository: SalesInvoiceRepository(
          firestore: firestore,
          salesOrderRepository: salesOrders,
        ),
        jobWorkRepository: jobWork,
        jobWorkLoadRepository: loads,
        salesOrderRepository: salesOrders,
      );

      await ledger.syncCustomerBalance(customerA);
      final afterFirst = await customers.getCustomer(customerA);
      expect(afterFirst, isNotNull);
      expect(afterFirst!.totalBalanceDue, 400);
      expect(afterFirst.balance, 400);

      await ledger.syncCustomerBalance(customerA);
      final afterSecond = await customers.getCustomer(customerA);
      expect(afterSecond!.updatedAt, afterFirst.updatedAt);
    });
  });
}

Map<String, dynamic> _salesOrderData({
  required String customerId,
  String orderNumber = 'SO-A',
  double grandTotal = 100,
  double due = 100,
}) {
  final now = Timestamp.fromDate(DateTime(2026, 8, 1));
  return {
    'factoryId': 'factory-s40',
    'customerId': customerId,
    'orderNumber': orderNumber,
    'customerName': customerId,
    'status': 'ready',
    'orderDate': now,
    'orderSource': 'walkIn',
    'subtotal': grandTotal,
    'orderDiscount': 0,
    'tax': 0,
    'grandTotal': grandTotal,
    'paymentTerms': 'cash',
    'advanceReceived': 0,
    'balanceDue': due,
    'createdAt': now,
  };
}

Map<String, dynamic> _jobWorkData({
  required String customerId,
  String number = 'JW-A',
}) {
  final now = Timestamp.fromDate(DateTime(2026, 8, 1));
  return {
    'factoryId': 'factory-s40',
    'customerId': customerId,
    'customerName': customerId,
    'jobWorkNumber': number,
    'status': 'inCutting',
    'receivedDate': now,
    'marbleVariety': 'White',
    'blockCount': 1,
    'totalTons': 1,
    'cuttingStrategy': 'bridgeSaw',
    'targetProduct': 'tiles',
    'thickness': '18mm',
    'finish': 'polished',
    'pricingModel': 'perSqFt',
    'agreedRate': 100,
    'advanceReceived': 0,
    'balanceDue': 0,
    'paymentTerms': 'cash',
    'createdAt': now,
  };
}

Map<String, dynamic> _loadData({
  required String customerId,
  required String jobWorkId,
  String loadNumber = 'L-A',
}) {
  return {
    ..._jobWorkData(customerId: customerId),
    'loadNumber': loadNumber,
    'loadSequence': 1,
    'jobWorkId': jobWorkId,
  };
}

Map<String, dynamic> _customerData({
  required double balance,
  required double totalDue,
  required double totalPaid,
}) {
  return {
    'factoryId': 'factory-s40',
    'customerType': 'individual',
    'name': 'Customer A',
    'phone': '03000000000',
    'serviceType': 'jobWork',
    'category': 'retail',
    'paymentTerms': 'cash',
    'creditLimit': 0,
    'balance': balance,
    'openingBalance': 0,
    'totalAmountPaid': totalPaid,
    'totalBalanceDue': totalDue,
    'createdAt': Timestamp.fromDate(DateTime(2026, 8, 1)),
  };
}
