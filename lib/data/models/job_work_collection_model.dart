import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/job_work_collection.dart';
import '../../domain/enums/job_work_collection_enums.dart';
import '../../core/constants/job_work_sizes.dart';

class JobWorkCollectionModel {
  const JobWorkCollectionModel({
    required this.id,
    required this.collectionNumber,
    required this.factoryId,
    required this.jobWorkOrderId,
    required this.jobWorkNumber,
    required this.customerId,
    required this.customerName,
    required this.collectedAt,
    required this.status,
    required this.lineItems,
    required this.createdAt,
    this.loadId,
    this.loadNumber,
    this.receiverName,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String collectionNumber;
  final String factoryId;
  final String jobWorkOrderId;
  final String jobWorkNumber;
  final String? loadId;
  final String? loadNumber;
  final String customerId;
  final String customerName;
  final DateTime collectedAt;
  final JobWorkCollectionStatus status;
  final List<JobWorkCollectionLineItem> lineItems;
  final String? receiverName;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory JobWorkCollectionModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final items = (data['lineItems'] as List?) ?? const [];
    return JobWorkCollectionModel(
      id: id,
      collectionNumber: data['collectionNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      jobWorkOrderId: data['jobWorkOrderId'] as String? ?? '',
      jobWorkNumber: data['jobWorkNumber'] as String? ?? '',
      loadId: data['loadId'] as String?,
      loadNumber: data['loadNumber'] as String?,
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      collectedAt:
          (data['collectedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: JobWorkCollectionStatus.fromString(data['status'] as String?),
      lineItems: items.whereType<Map>().map(_lineItemFromMap).toList(),
      receiverName: data['receiverName'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static JobWorkCollectionLineItem _lineItemFromMap(Map<dynamic, dynamic> data) {
    final size = data['size'] as String? ?? '';
    return JobWorkCollectionLineItem(
      size: size,
      pieces: (data['pieces'] as num?)?.toInt() ?? 0,
      squareFeet: (data['squareFeet'] as num?)?.toDouble() ?? 0,
      isSmall: data['isSmall'] as bool? ?? JobWorkSizes.isSmall(size),
    );
  }

  static Map<String, dynamic> _lineItemToMap(JobWorkCollectionLineItem item) {
    return {
      'size': item.size,
      'pieces': item.pieces,
      'squareFeet': item.squareFeet,
      'isSmall': item.isSmall,
    };
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'collectionNumber': collectionNumber,
      'factoryId': factoryId,
      'jobWorkOrderId': jobWorkOrderId,
      'jobWorkNumber': jobWorkNumber,
      if (loadId != null && loadId!.isNotEmpty) 'loadId': loadId,
      if (loadNumber != null && loadNumber!.isNotEmpty) 'loadNumber': loadNumber,
      'customerId': customerId,
      'customerName': customerName,
      'collectedAt': Timestamp.fromDate(collectedAt),
      'status': status.firestoreValue,
      'lineItems': lineItems.map(_lineItemToMap).toList(),
      if (receiverName != null && receiverName!.isNotEmpty)
        'receiverName': receiverName,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  JobWorkCollection toEntity() => JobWorkCollection(
        id: id,
        collectionNumber: collectionNumber,
        factoryId: factoryId,
        jobWorkOrderId: jobWorkOrderId,
        jobWorkNumber: jobWorkNumber,
        loadId: loadId,
        loadNumber: loadNumber,
        customerId: customerId,
        customerName: customerName,
        collectedAt: collectedAt,
        status: status,
        lineItems: lineItems,
        receiverName: receiverName,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory JobWorkCollectionModel.fromEntity(JobWorkCollection collection) =>
      JobWorkCollectionModel(
        id: collection.id,
        collectionNumber: collection.collectionNumber,
        factoryId: collection.factoryId,
        jobWorkOrderId: collection.jobWorkOrderId,
        jobWorkNumber: collection.jobWorkNumber,
        loadId: collection.loadId,
        loadNumber: collection.loadNumber,
        customerId: collection.customerId,
        customerName: collection.customerName,
        collectedAt: collection.collectedAt,
        status: collection.status,
        lineItems: collection.lineItems,
        receiverName: collection.receiverName,
        notes: collection.notes,
        createdAt: collection.createdAt,
        updatedAt: collection.updatedAt,
      );
}
