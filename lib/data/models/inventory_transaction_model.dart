import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/inventory_transaction.dart';
import '../../domain/enums/inventory_enums.dart';

class InventoryTransactionModel {
  const InventoryTransactionModel({
    required this.id,
    required this.transactionNumber,
    required this.factoryId,
    required this.finishedGoodId,
    required this.movementType,
    required this.quantity,
    required this.transactionDate,
    required this.createdAt,
    this.unitCost,
    this.totalCost,
    this.productionBatchId,
    this.productionBatchNumber,
    this.reason,
    this.notes,
  });

  final String id;
  final String transactionNumber;
  final String factoryId;
  final String finishedGoodId;
  final InventoryMovementType movementType;
  final double quantity;
  final double? unitCost;
  final double? totalCost;
  final DateTime transactionDate;
  final String? productionBatchId;
  final String? productionBatchNumber;
  final String? reason;
  final String? notes;
  final DateTime createdAt;

  factory InventoryTransactionModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return InventoryTransactionModel(
      id: id,
      transactionNumber: data['transactionNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      finishedGoodId: data['finishedGoodId'] as String? ?? '',
      movementType:
          InventoryMovementType.fromString(data['movementType'] as String?),
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0,
      unitCost: (data['unitCost'] as num?)?.toDouble(),
      totalCost: (data['totalCost'] as num?)?.toDouble(),
      transactionDate:
          (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      productionBatchId: data['productionBatchId'] as String?,
      productionBatchNumber: data['productionBatchNumber'] as String?,
      reason: data['reason'] as String?,
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'transactionNumber': transactionNumber,
      'factoryId': factoryId,
      'finishedGoodId': finishedGoodId,
      'movementType': movementType.firestoreValue,
      'quantity': quantity,
      if (unitCost != null) 'unitCost': unitCost,
      if (totalCost != null) 'totalCost': totalCost,
      'transactionDate': Timestamp.fromDate(transactionDate),
      if (productionBatchId != null && productionBatchId!.isNotEmpty)
        'productionBatchId': productionBatchId,
      if (productionBatchNumber != null && productionBatchNumber!.isNotEmpty)
        'productionBatchNumber': productionBatchNumber,
      if (reason != null && reason!.isNotEmpty) 'reason': reason,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  InventoryTransaction toEntity() => InventoryTransaction(
        id: id,
        transactionNumber: transactionNumber,
        factoryId: factoryId,
        finishedGoodId: finishedGoodId,
        movementType: movementType,
        quantity: quantity,
        unitCost: unitCost,
        totalCost: totalCost,
        transactionDate: transactionDate,
        productionBatchId: productionBatchId,
        productionBatchNumber: productionBatchNumber,
        reason: reason,
        notes: notes,
        createdAt: createdAt,
      );

  factory InventoryTransactionModel.fromEntity(InventoryTransaction transaction) =>
      InventoryTransactionModel(
        id: transaction.id,
        transactionNumber: transaction.transactionNumber,
        factoryId: transaction.factoryId,
        finishedGoodId: transaction.finishedGoodId,
        movementType: transaction.movementType,
        quantity: transaction.quantity,
        unitCost: transaction.unitCost,
        totalCost: transaction.totalCost,
        transactionDate: transaction.transactionDate,
        productionBatchId: transaction.productionBatchId,
        productionBatchNumber: transaction.productionBatchNumber,
        reason: transaction.reason,
        notes: transaction.notes,
        createdAt: transaction.createdAt,
      );
}
