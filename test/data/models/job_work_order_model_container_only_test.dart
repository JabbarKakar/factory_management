import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:factory_management/data/models/job_work_order_model.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';
import 'package:factory_management/domain/enums/job_work_load_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobWorkOrder buildOrder() {
    return JobWorkOrder(
      id: 'jw-1',
      jobWorkNumber: 'JW-2026-0001',
      factoryId: 'factory-1',
      customerId: 'customer-1',
      customerName: 'Customer',
      status: JobWorkStatus.inCutting,
      receivedDate: DateTime(2026, 1, 1),
      marbleVariety: 'Black Galaxy',
      blockCount: 10,
      totalTons: 20,
      cuttingStrategy: CuttingStrategy.bridgeSaw,
      targetProduct: TargetProduct.tiles,
      thickness: '18mm',
      finish: FinishType.polished,
      pricingModel: PricingModel.perSqFt,
      agreedRate: 50,
      advanceReceived: 100,
      balanceDue: 900,
      paymentTerms: PaymentTerms.cash,
      createdAt: DateTime(2026, 1, 1),
      schemaVersion: JobWorkSchemaVersion.loadsAuthoritative,
      defaultLoadId: 'load-1',
      loadCount: 1,
      activeLoadCount: 1,
    );
  }

  test('toFirestore(containerOnly) omits nested ops and status', () {
    final map = JobWorkOrderModel.fromEntity(buildOrder()).toFirestore(
      containerOnly: true,
    );

    expect(map.containsKey('input'), isFalse);
    expect(map.containsKey('cuttingSpec'), isFalse);
    expect(map.containsKey('pricing'), isFalse);
    expect(map.containsKey('output'), isFalse);
    expect(map.containsKey('outputShifts'), isFalse);
    expect(map.containsKey('execution'), isFalse);
    expect(map.containsKey('invoiceId'), isFalse);
    expect(map.containsKey('status'), isFalse);
    expect(map['schemaVersion'], JobWorkSchemaVersion.loadsAuthoritative);
    expect(map['defaultLoadId'], 'load-1');
    expect(map['customerName'], 'Customer');
    expect(map['updatedAt'], isA<FieldValue>());
  });

  test('toFirestore(full) still writes nested archives for legacy create/update', () {
    final map = JobWorkOrderModel.fromEntity(buildOrder()).toFirestore();
    expect(map.containsKey('input'), isTrue);
    expect(map.containsKey('cuttingSpec'), isTrue);
    expect(map.containsKey('pricing'), isTrue);
    expect(map['status'], JobWorkStatus.inCutting.firestoreValue);
  });
}
