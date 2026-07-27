import 'package:factory_management/data/models/job_work_collection_model.dart';
import 'package:factory_management/domain/entities/job_work_collection.dart';
import 'package:factory_management/domain/enums/job_work_collection_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobWorkCollectionModel', () {
    final testDate = DateTime(2026, 7, 27, 10, 0);

    final testEntity = JobWorkCollection(
      id: 'col-123',
      collectionNumber: 'JC-2026-0001',
      factoryId: 'factory-1',
      jobWorkOrderId: 'jwo-1',
      jobWorkNumber: 'JWO-2026-001',
      loadId: 'load-1',
      loadNumber: 'LOAD-001',
      customerId: 'cust-1',
      customerName: 'Ahmad Marble Co',
      collectedAt: testDate,
      status: JobWorkCollectionStatus.collected,
      lineItems: const [
        JobWorkCollectionLineItem(
          size: '12x12',
          pieces: 100,
          squareFeet: 100.0,
          isSmall: true,
        ),
      ],
      receiverName: 'Ali Khan',
      receiverPhone: '03001234567',
      receiverAddress: 'Plot 45, Industrial Zone, Quetta',
      receiverEmail: 'ali@example.com',
      vehicleNumber: 'KBL-1234',
      driverName: 'Jan Mohammad',
      driverPhone: '03129876543',
      driverCnic: '54400-1234567-1',
      vehicleType: 'Flatbed Truck',
      notes: 'Delivered in full',
      createdAt: testDate,
    );

    test('should convert to and from entity correctly', () {
      final model = JobWorkCollectionModel.fromEntity(testEntity);
      final entity = model.toEntity();

      expect(entity.id, equals('col-123'));
      expect(entity.receiverName, equals('Ali Khan'));
      expect(entity.receiverPhone, equals('03001234567'));
      expect(entity.receiverAddress, equals('Plot 45, Industrial Zone, Quetta'));
      expect(entity.receiverEmail, equals('ali@example.com'));
      expect(entity.vehicleNumber, equals('KBL-1234'));
      expect(entity.driverName, equals('Jan Mohammad'));
      expect(entity.driverPhone, equals('03129876543'));
      expect(entity.driverCnic, equals('54400-1234567-1'));
      expect(entity.vehicleType, equals('Flatbed Truck'));
    });

    test('should convert to Firestore map and contain all receiver and transport fields', () {
      final model = JobWorkCollectionModel.fromEntity(testEntity);
      final firestoreMap = model.toFirestore(isCreate: true);

      expect(firestoreMap['receiverName'], equals('Ali Khan'));
      expect(firestoreMap['receiverPhone'], equals('03001234567'));
      expect(firestoreMap['receiverAddress'], equals('Plot 45, Industrial Zone, Quetta'));
      expect(firestoreMap['receiverEmail'], equals('ali@example.com'));
      expect(firestoreMap['vehicleNumber'], equals('KBL-1234'));
      expect(firestoreMap['driverName'], equals('Jan Mohammad'));
      expect(firestoreMap['driverPhone'], equals('03129876543'));
      expect(firestoreMap['driverCnic'], equals('54400-1234567-1'));
      expect(firestoreMap['vehicleType'], equals('Flatbed Truck'));
    });
  });
}
