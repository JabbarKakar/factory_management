import 'package:equatable/equatable.dart';

import '../enums/job_work_collection_enums.dart';

class JobWorkCollectionLineItem extends Equatable {
  const JobWorkCollectionLineItem({
    required this.size,
    required this.pieces,
    required this.squareFeet,
    this.isSmall = true,
  });

  final String size;
  final int pieces;
  final double squareFeet;
  final bool isSmall;

  String get displayLabel => size;

  bool get hasQuantity => pieces > 0 || squareFeet > 0;

  JobWorkCollectionLineItem copyWith({
    String? size,
    int? pieces,
    double? squareFeet,
    bool? isSmall,
  }) {
    return JobWorkCollectionLineItem(
      size: size ?? this.size,
      pieces: pieces ?? this.pieces,
      squareFeet: squareFeet ?? this.squareFeet,
      isSmall: isSmall ?? this.isSmall,
    );
  }

  @override
  List<Object?> get props => [size, pieces, squareFeet, isSmall];
}

class JobWorkCollection extends Equatable {
  const JobWorkCollection({
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
    this.receiverPhone,
    this.receiverAddress,
    this.receiverEmail,
    this.vehicleNumber,
    this.driverName,
    this.driverPhone,
    this.driverCnic,
    this.vehicleType,
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
  final String? receiverPhone;
  final String? receiverAddress;
  final String? receiverEmail;
  final String? vehicleNumber;
  final String? driverName;
  final String? driverPhone;
  final String? driverCnic;
  final String? vehicleType;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  int get totalPieces =>
      lineItems.fold<int>(0, (sum, item) => sum + item.pieces);

  double get totalSquareFeet =>
      lineItems.fold<double>(0, (sum, item) => sum + item.squareFeet);

  JobWorkCollection copyWith({
    String? id,
    String? collectionNumber,
    String? factoryId,
    String? jobWorkOrderId,
    String? jobWorkNumber,
    String? loadId,
    String? loadNumber,
    String? customerId,
    String? customerName,
    DateTime? collectedAt,
    JobWorkCollectionStatus? status,
    List<JobWorkCollectionLineItem>? lineItems,
    String? receiverName,
    String? receiverPhone,
    String? receiverAddress,
    String? receiverEmail,
    String? vehicleNumber,
    String? driverName,
    String? driverPhone,
    String? driverCnic,
    String? vehicleType,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobWorkCollection(
      id: id ?? this.id,
      collectionNumber: collectionNumber ?? this.collectionNumber,
      factoryId: factoryId ?? this.factoryId,
      jobWorkOrderId: jobWorkOrderId ?? this.jobWorkOrderId,
      jobWorkNumber: jobWorkNumber ?? this.jobWorkNumber,
      loadId: loadId ?? this.loadId,
      loadNumber: loadNumber ?? this.loadNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      collectedAt: collectedAt ?? this.collectedAt,
      status: status ?? this.status,
      lineItems: lineItems ?? this.lineItems,
      receiverName: receiverName ?? this.receiverName,
      receiverPhone: receiverPhone ?? this.receiverPhone,
      receiverAddress: receiverAddress ?? this.receiverAddress,
      receiverEmail: receiverEmail ?? this.receiverEmail,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      driverName: driverName ?? this.driverName,
      driverPhone: driverPhone ?? this.driverPhone,
      driverCnic: driverCnic ?? this.driverCnic,
      vehicleType: vehicleType ?? this.vehicleType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        collectionNumber,
        factoryId,
        jobWorkOrderId,
        jobWorkNumber,
        loadId,
        loadNumber,
        customerId,
        customerName,
        collectedAt,
        status,
        lineItems,
        receiverName,
        receiverPhone,
        receiverAddress,
        receiverEmail,
        vehicleNumber,
        driverName,
        driverPhone,
        driverCnic,
        vehicleType,
        notes,
        createdAt,
        updatedAt,
      ];
}
