import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/stock_transaction.dart';
import '../../domain/enums/raw_material_enums.dart';

class StockTransactionModel {
  const StockTransactionModel({
    required this.id,
    required this.transactionNumber,
    required this.factoryId,
    required this.rawMaterialId,
    required this.materialType,
    required this.movementType,
    required this.quantity,
    required this.transactionDate,
    required this.createdAt,
    this.unitCost,
    this.totalCost,
    this.supplierId,
    this.referenceNumber,
    this.notes,
  });

  final String id;
  final String transactionNumber;
  final String factoryId;
  final String rawMaterialId;
  final RawMaterialType materialType;
  final StockMovementType movementType;
  final double quantity;
  final double? unitCost;
  final double? totalCost;
  final DateTime transactionDate;
  final String? supplierId;
  final String? referenceNumber;
  final String? notes;
  final DateTime createdAt;

  factory StockTransactionModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return StockTransactionModel(
      id: id,
      transactionNumber: data['transactionNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      rawMaterialId: data['rawMaterialId'] as String? ?? '',
      materialType:
          RawMaterialType.fromString(data['materialType'] as String?),
      movementType:
          StockMovementType.fromString(data['movementType'] as String?),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      unitCost: (data['unitCost'] as num?)?.toDouble(),
      totalCost: (data['totalCost'] as num?)?.toDouble(),
      transactionDate:
          (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      supplierId: data['supplierId'] as String?,
      referenceNumber: data['referenceNumber'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'transactionNumber': transactionNumber,
      'factoryId': factoryId,
      'rawMaterialId': rawMaterialId,
      'materialType': materialType.firestoreValue,
      'movementType': movementType.firestoreValue,
      'quantity': quantity,
      if (unitCost != null) 'unitCost': unitCost,
      if (totalCost != null) 'totalCost': totalCost,
      'transactionDate': Timestamp.fromDate(transactionDate),
      if (supplierId != null && supplierId!.isNotEmpty) 'supplierId': supplierId,
      if (referenceNumber != null && referenceNumber!.isNotEmpty)
        'referenceNumber': referenceNumber,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  StockTransaction toEntity() => StockTransaction(
        id: id,
        transactionNumber: transactionNumber,
        factoryId: factoryId,
        rawMaterialId: rawMaterialId,
        materialType: materialType,
        movementType: movementType,
        quantity: quantity,
        unitCost: unitCost,
        totalCost: totalCost,
        transactionDate: transactionDate,
        supplierId: supplierId,
        referenceNumber: referenceNumber,
        notes: notes,
        createdAt: createdAt,
      );

  factory StockTransactionModel.fromEntity(StockTransaction transaction) =>
      StockTransactionModel(
        id: transaction.id,
        transactionNumber: transaction.transactionNumber,
        factoryId: transaction.factoryId,
        rawMaterialId: transaction.rawMaterialId,
        materialType: transaction.materialType,
        movementType: transaction.movementType,
        quantity: transaction.quantity,
        unitCost: transaction.unitCost,
        totalCost: transaction.totalCost,
        transactionDate: transaction.transactionDate,
        supplierId: transaction.supplierId,
        referenceNumber: transaction.referenceNumber,
        notes: transaction.notes,
        createdAt: transaction.createdAt,
      );
}
