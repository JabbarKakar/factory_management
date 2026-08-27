import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
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
  const factoryId = 'factory-s40';
  const customerId = 'cust-a';
  final stamped = Timestamp.fromDate(DateTime(2026, 8, 1));

  group('write de-amplification', () {
    test('sales repair sync does not rewrite invoice or order when already matched',
        () async {
      final firestore = FakeFirebaseFirestore();
      final salesOrders = SalesOrderRepository(firestore: firestore);
      final payments = PaymentRepository(
        firestore: firestore,
        jobWorkInvoiceRepository: JobWorkInvoiceRepository(
          firestore: firestore,
          jobWorkRepository: JobWorkRepository(firestore: firestore),
          loadRepository: JobWorkLoadRepository(firestore: firestore),
        ),
        salesInvoiceRepository: SalesInvoiceRepository(
          firestore: firestore,
          salesOrderRepository: salesOrders,
        ),
        jobWorkRepository: JobWorkRepository(firestore: firestore),
        jobWorkLoadRepository: JobWorkLoadRepository(firestore: firestore),
        salesOrderRepository: salesOrders,
      );

      await firestore.collection('salesOrders').doc('so-1').set({
        'factoryId': factoryId,
        'customerId': customerId,
        'orderNumber': 'SO-1',
        'customerName': 'A',
        'status': 'ready',
        'orderDate': stamped,
        'orderSource': 'walkIn',
        'subtotal': 100,
        'orderDiscount': 0,
        'tax': 0,
        'grandTotal': 100,
        'paymentTerms': 'cash',
        'advanceReceived': 50,
        'balanceDue': 50,
        'createdAt': stamped,
        'updatedAt': stamped,
      });
      await firestore.collection('salesInvoices').doc('inv-1').set({
        'factoryId': factoryId,
        'invoiceNumber': 'INV-1',
        'salesOrderId': 'so-1',
        'orderNumber': 'SO-1',
        'customerId': customerId,
        'customerName': 'A',
        'items': [
          {'description': 'Tiles', 'amount': 100},
        ],
        'total': 100,
        'paid': 50,
        'due': 50,
        'status': 'partial',
        'createdAt': stamped,
        'updatedAt': stamped,
      });
      await firestore.collection('payments').doc('pay-1').set({
        'factoryId': factoryId,
        'customerId': customerId,
        'customerName': 'A',
        'invoiceId': 'inv-1',
        'invoiceType': 'sales',
        'invoiceNumber': 'INV-1',
        'amount': 50,
        'method': 'cash',
        'date': stamped,
        'orderId': 'so-1',
        'status': 'completed',
        'createdAt': stamped,
      });

      await payments.updatePayment(
        paymentId: 'pay-1',
        amount: 50,
        method: PaymentMethod.cash,
        paymentDate: DateTime(2026, 8, 1),
      );

      final invoice = await firestore.collection('salesInvoices').doc('inv-1').get();
      final order = await firestore.collection('salesOrders').doc('so-1').get();
      expect(invoice.data()?['updatedAt'], stamped);
      expect(order.data()?['updatedAt'], stamped);
    });

    test('refreshContainerFromLoads writes nothing on a second no-op pass',
        () async {
      final firestore = FakeFirebaseFirestore();
      final jobWork = JobWorkRepository(firestore: firestore);
      final loads = JobWorkLoadRepository(
        firestore: firestore,
        jobWorkRepository: jobWork,
      );

      await firestore.collection('jobWorkOrders').doc('jw-1').set({
        'factoryId': factoryId,
        'customerId': customerId,
        'customerName': 'A',
        'jobWorkNumber': 'JW-1',
        'status': 'inCutting',
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
        'balanceDue': 0,
        'paymentTerms': 'cash',
        'createdAt': stamped,
        'schemaVersion': JobWorkSchemaVersion.loadsAuthoritative,
        'defaultLoadId': 'load-1',
        'loadCount': 1,
        'activeLoadCount': 1,
        'summaryStatus': 'active',
      });
      await firestore.collection('jobWorkLoads').doc('load-1').set({
        'factoryId': factoryId,
        'customerId': customerId,
        'customerName': 'A',
        'jobWorkNumber': 'JW-1',
        'jobWorkId': 'jw-1',
        'loadNumber': 'L-1',
        'loadSequence': 1,
        'status': 'inCutting',
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
        'balanceDue': 0,
        'paymentTerms': 'cash',
        'createdAt': stamped,
      });

      await loads.refreshContainerFromLoads('jw-1');
      final afterFirst =
          await firestore.collection('jobWorkOrders').doc('jw-1').get();
      final firstUpdatedAt = afterFirst.data()?['updatedAt'];

      await loads.refreshContainerFromLoads('jw-1');
      final afterSecond =
          await firestore.collection('jobWorkOrders').doc('jw-1').get();
      expect(afterSecond.data()?['updatedAt'], firstUpdatedAt);
    });
  });
}
