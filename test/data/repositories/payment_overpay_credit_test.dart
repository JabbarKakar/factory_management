import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:factory_management/data/models/payment_model.dart';
import 'package:factory_management/data/repositories/job_work_invoice_repository.dart';
import 'package:factory_management/data/repositories/job_work_load_repository.dart';
import 'package:factory_management/data/repositories/job_work_repository.dart';
import 'package:factory_management/data/repositories/payment_repository.dart';
import 'package:factory_management/data/repositories/sales_invoice_repository.dart';
import 'package:factory_management/data/repositories/sales_order_repository.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:factory_management/domain/enums/job_work_load_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const factoryId = 'factory-overpay';
  const customerId = 'cust-overpay';
  final stamped = Timestamp.fromDate(DateTime(2026, 8, 31));

  PaymentRepository buildRepo(FakeFirebaseFirestore firestore) {
    final jobWork = JobWorkRepository(firestore: firestore);
    final loads = JobWorkLoadRepository(
      firestore: firestore,
      jobWorkRepository: jobWork,
    );
    final salesOrders = SalesOrderRepository(firestore: firestore);
    return PaymentRepository(
      firestore: firestore,
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
  }

  Future<void> seedJobWorkInvoice(
    FakeFirebaseFirestore firestore, {
    required String invoiceId,
    required String loadId,
    required String orderId,
    required double total,
    double paid = 0,
  }) async {
    await firestore.collection('jobWorkOrders').doc(orderId).set({
      'factoryId': factoryId,
      'customerId': customerId,
      'customerName': 'A',
      'jobWorkNumber': 'JW-1',
      'status': 'invoiced',
      'receivedDate': stamped,
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
      'balanceDue': total - paid,
      'paymentTerms': 'cash',
      'createdAt': stamped,
      'schemaVersion': JobWorkSchemaVersion.loadsAuthoritative,
      'defaultLoadId': loadId,
      'loadCount': 1,
      'activeLoadCount': 1,
      'summaryStatus': 'active',
      'pricing': {
        'model': 'perSqFt',
        'agreedRate': 100,
        'finalCuttingCharges': total,
        'advanceReceived': 0,
        'balanceDue': total - paid,
        'paymentTerms': 'cash',
      },
    });
    await firestore.collection('jobWorkLoads').doc(loadId).set({
      'factoryId': factoryId,
      'customerId': customerId,
      'customerName': 'A',
      'jobWorkNumber': 'JW-1',
      'jobWorkId': orderId,
      'loadNumber': 'L-1',
      'loadSequence': 1,
      'status': 'invoiced',
      'receivedDate': stamped,
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
      'balanceDue': total - paid,
      'paymentTerms': 'cash',
      'createdAt': stamped,
      'pricing': {
        'model': 'perSqFt',
        'agreedRate': 100,
        'finalCuttingCharges': total,
        'advanceReceived': 0,
        'balanceDue': total - paid,
        'paymentTerms': 'cash',
      },
    });
    await firestore.collection('jobWorkInvoices').doc(invoiceId).set({
      'factoryId': factoryId,
      'invoiceNumber': 'INV-$invoiceId',
      'jobWorkId': orderId,
      'jobWorkNumber': 'JW-1',
      'loadId': loadId,
      'customerId': customerId,
      'customerName': 'A',
      'items': [
        {'description': 'Cutting', 'amount': total},
      ],
      'total': total,
      'paid': paid,
      'due': total - paid,
      'status': paid > 0 ? 'partial' : 'unpaid',
      'createdAt': stamped,
    });
  }

  Future<void> seedSalesInvoice(
    FakeFirebaseFirestore firestore, {
    required String invoiceId,
    required String orderId,
    required double total,
    double paid = 0,
  }) async {
    await firestore.collection('salesOrders').doc(orderId).set({
      'factoryId': factoryId,
      'customerId': customerId,
      'orderNumber': 'SO-$orderId',
      'customerName': 'A',
      'status': 'invoiced',
      'orderDate': stamped,
      'orderSource': 'walkIn',
      'subtotal': total,
      'orderDiscount': 0,
      'tax': 0,
      'grandTotal': total,
      'paymentTerms': 'cash',
      'advanceReceived': paid,
      'balanceDue': total - paid,
      'createdAt': stamped,
    });
    await firestore.collection('salesInvoices').doc(invoiceId).set({
      'factoryId': factoryId,
      'invoiceNumber': 'INV-$invoiceId',
      'salesOrderId': orderId,
      'orderNumber': 'SO-$orderId',
      'customerId': customerId,
      'customerName': 'A',
      'items': [
        {'description': 'Tiles', 'amount': total},
      ],
      'total': total,
      'paid': paid,
      'due': total - paid,
      'status': paid > 0 ? 'partial' : 'unpaid',
      'createdAt': stamped,
    });
  }

  group('overpay as customer credit', () {
    test('job work 300k cash on 200k due stores leftover as unallocated',
        () async {
      final firestore = FakeFirebaseFirestore();
      final payments = buildRepo(firestore);
      await seedJobWorkInvoice(
        firestore,
        invoiceId: 'inv-jw',
        loadId: 'load-1',
        orderId: 'jw-1',
        total: 200000,
      );

      final payment = await payments.recordJobWorkPayment(
        invoiceId: 'inv-jw',
        amount: 300000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 8, 31),
        loadId: 'load-1',
      );

      expect(payment.amount, 300000);
      expect(payment.appliedAmount, 200000);
      expect(payment.unallocatedAmount, 100000);

      final invoice =
          await firestore.collection('jobWorkInvoices').doc('inv-jw').get();
      expect(invoice.data()?['paid'], 200000);
      expect(invoice.data()?['due'], 0);

      final credit = await payments.getUnallocatedCreditForCustomer(
        factoryId: factoryId,
        customerId: customerId,
      );
      expect(credit, 100000);
    });

    test('sales 300k cash on 200k due does not inflate invoice paid', () async {
      final firestore = FakeFirebaseFirestore();
      final payments = buildRepo(firestore);
      await seedSalesInvoice(
        firestore,
        invoiceId: 'inv-so',
        orderId: 'so-1',
        total: 200000,
      );

      final payment = await payments.recordSalesPayment(
        invoiceId: 'inv-so',
        amount: 300000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 8, 31),
      );

      expect(payment.amount, 300000);
      expect(payment.appliedAmount, 200000);

      final invoice =
          await firestore.collection('salesInvoices').doc('inv-so').get();
      expect(invoice.data()?['paid'], 200000);
      expect(invoice.data()?['due'], 0);
    });

    test('repair sync uses appliedAmount not cash amount', () async {
      final firestore = FakeFirebaseFirestore();
      final payments = buildRepo(firestore);
      await seedSalesInvoice(
        firestore,
        invoiceId: 'inv-so',
        orderId: 'so-1',
        total: 200000,
        paid: 200000,
      );
      await firestore.collection('payments').doc('pay-1').set({
        'factoryId': factoryId,
        'customerId': customerId,
        'customerName': 'A',
        'invoiceId': 'inv-so',
        'invoiceType': 'sales',
        'invoiceNumber': 'INV-inv-so',
        'amount': 300000,
        'appliedAmount': 200000,
        'method': 'cash',
        'date': stamped,
        'orderId': 'so-1',
        'status': 'completed',
        'createdAt': stamped,
      });

      await payments.updatePayment(
        paymentId: 'pay-1',
        amount: 300000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 8, 31),
      );

      final invoice =
          await firestore.collection('salesInvoices').doc('inv-so').get();
      expect(invoice.data()?['paid'], 200000);
      expect(invoice.data()?['due'], 0);
    });

    test('legacy payment without appliedAmount still fully applies', () async {
      final model = PaymentModel.fromFirestore('legacy', {
        'factoryId': factoryId,
        'customerId': customerId,
        'invoiceId': 'inv-so',
        'invoiceType': 'sales',
        'invoiceNumber': 'INV-1',
        'amount': 50,
        'method': 'cash',
        'status': 'completed',
      });
      expect(model.appliedAmount, 50);
      expect(model.toEntity().unallocatedAmount, 0);
    });

    test('apply credit then cash on a later invoice clears due without extra income',
        () async {
      final firestore = FakeFirebaseFirestore();
      final payments = buildRepo(firestore);
      await seedJobWorkInvoice(
        firestore,
        invoiceId: 'inv-a',
        loadId: 'load-a',
        orderId: 'jw-a',
        total: 200000,
      );
      await seedSalesInvoice(
        firestore,
        invoiceId: 'inv-b',
        orderId: 'so-b',
        total: 150000,
      );

      await payments.recordJobWorkPayment(
        invoiceId: 'inv-a',
        amount: 300000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 8, 31),
        loadId: 'load-a',
      );

      await payments.applyCustomerCredit(
        invoiceId: 'inv-b',
        invoiceType: InvoiceType.sales,
        appliedAmount: 100000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 8, 31),
      );
      await payments.recordSalesPayment(
        invoiceId: 'inv-b',
        amount: 50000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 8, 31),
      );

      final invoiceA =
          await firestore.collection('jobWorkInvoices').doc('inv-a').get();
      expect(invoiceA.data()?['paid'], 200000);

      final invoiceB =
          await firestore.collection('salesInvoices').doc('inv-b').get();
      expect(invoiceB.data()?['paid'], 150000);
      expect(invoiceB.data()?['due'], 0);

      final all = await firestore.collection('payments').get();
      final cash = all.docs.fold<double>(
        0,
        (sum, doc) => sum + ((doc.data()['amount'] as num?)?.toDouble() ?? 0),
      );
      expect(cash, 350000);
      expect(
        await payments.getUnallocatedCreditForCustomer(
          factoryId: factoryId,
          customerId: customerId,
        ),
        0,
      );
    });

    test('deleting overpay payment restores due and credit together', () async {
      final firestore = FakeFirebaseFirestore();
      final payments = buildRepo(firestore);
      await seedSalesInvoice(
        firestore,
        invoiceId: 'inv-so',
        orderId: 'so-1',
        total: 200000,
      );

      final payment = await payments.recordSalesPayment(
        invoiceId: 'inv-so',
        amount: 300000,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 8, 31),
      );
      await payments.deletePayment(payment.id);

      final invoice =
          await firestore.collection('salesInvoices').doc('inv-so').get();
      expect(invoice.data()?['paid'], 0);
      expect(invoice.data()?['due'], 200000);
      expect(
        await payments.getUnallocatedCreditForCustomer(
          factoryId: factoryId,
          customerId: customerId,
        ),
        0,
      );
    });
  });
}
