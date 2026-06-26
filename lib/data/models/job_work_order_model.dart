import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/job_work_enums.dart';

class JobWorkOrderModel {
  const JobWorkOrderModel({
    required this.id,
    required this.jobWorkNumber,
    required this.factoryId,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.receivedDate,
    required this.marbleVariety,
    required this.blockCount,
    required this.totalTons,
    required this.cuttingStrategy,
    required this.targetProduct,
    required this.sizes,
    required this.thickness,
    required this.finish,
    required this.pricingModel,
    required this.agreedRate,
    required this.estimatedTotal,
    required this.negotiatedFinalAmount,
    required this.advanceReceived,
    required this.balanceDue,
    required this.paymentTerms,
    required this.createdAt,
    this.expectedCompletionDate,
    this.totalVolumeM3,
    this.blockDimensions,
    this.conditionNotes,
    this.vehicleNumber,
    this.expectedOutputSqFt,
    this.specialInstructions,
    this.paymentDueDate,
    this.updatedAt,
  });

  final String id;
  final String jobWorkNumber;
  final String factoryId;
  final String customerId;
  final String customerName;
  final JobWorkStatus status;
  final DateTime receivedDate;
  final DateTime? expectedCompletionDate;
  final String marbleVariety;
  final int blockCount;
  final double totalTons;
  final double? totalVolumeM3;
  final String? blockDimensions;
  final String? conditionNotes;
  final String? vehicleNumber;
  final CuttingStrategy cuttingStrategy;
  final TargetProduct targetProduct;
  final List<String> sizes;
  final String thickness;
  final FinishType finish;
  final double? expectedOutputSqFt;
  final String? specialInstructions;
  final PricingModel pricingModel;
  final double agreedRate;
  final double estimatedTotal;
  final double negotiatedFinalAmount;
  final double advanceReceived;
  final double balanceDue;
  final PaymentTerms paymentTerms;
  final DateTime? paymentDueDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory JobWorkOrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    final cuttingSpec = data['cuttingSpec'] as Map<String, dynamic>? ?? {};
    final input = data['input'] as Map<String, dynamic>? ?? {};
    final pricing = data['pricing'] as Map<String, dynamic>? ?? {};

    return JobWorkOrderModel(
      id: id,
      jobWorkNumber: data['jobWorkNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      status: JobWorkStatus.fromString(data['status'] as String?),
      receivedDate:
          (data['receivedDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expectedCompletionDate:
          (data['expectedCompletionDate'] as Timestamp?)?.toDate(),
      marbleVariety: input['variety'] as String? ?? '',
      blockCount: (input['blockCount'] as num?)?.toInt() ?? 0,
      totalTons: (input['totalTons'] as num?)?.toDouble() ?? 0,
      totalVolumeM3: (input['volumeM3'] as num?)?.toDouble(),
      blockDimensions: input['dimensions'] as String?,
      conditionNotes: input['notes'] as String?,
      vehicleNumber: input['vehicleNumber'] as String?,
      cuttingStrategy: CuttingStrategy.fromString(
        cuttingSpec['strategy'] as String?,
      ),
      targetProduct: TargetProduct.fromString(
        cuttingSpec['targetProduct'] as String?,
      ),
      sizes: (cuttingSpec['sizes'] as List?)?.cast<String>() ?? const [],
      thickness: cuttingSpec['thickness'] as String? ?? '',
      finish: FinishType.fromString(cuttingSpec['finish'] as String?),
      expectedOutputSqFt:
          (cuttingSpec['expectedOutputSqFt'] as num?)?.toDouble(),
      specialInstructions: cuttingSpec['specialInstructions'] as String?,
      pricingModel: PricingModel.fromString(pricing['model'] as String?),
      agreedRate: (pricing['agreedRate'] as num?)?.toDouble() ?? 0,
      estimatedTotal: (pricing['estimatedTotal'] as num?)?.toDouble() ?? 0,
      negotiatedFinalAmount:
          (pricing['negotiatedFinalAmount'] as num?)?.toDouble() ?? 0,
      advanceReceived: (pricing['advanceReceived'] as num?)?.toDouble() ?? 0,
      balanceDue: (pricing['balanceDue'] as num?)?.toDouble() ?? 0,
      paymentTerms: PaymentTerms.fromString(pricing['paymentTerms'] as String?),
      paymentDueDate: (pricing['paymentDueDate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'jobWorkNumber': jobWorkNumber,
      'factoryId': factoryId,
      'customerId': customerId,
      'customerName': customerName,
      'status': status.firestoreValue,
      'receivedDate': Timestamp.fromDate(receivedDate),
      if (expectedCompletionDate != null)
        'expectedCompletionDate': Timestamp.fromDate(expectedCompletionDate!),
      'input': {
        'variety': marbleVariety,
        'blockCount': blockCount,
        'totalTons': totalTons,
        if (totalVolumeM3 != null) 'volumeM3': totalVolumeM3,
        if (blockDimensions != null) 'dimensions': blockDimensions,
        if (conditionNotes != null) 'notes': conditionNotes,
        if (vehicleNumber != null) 'vehicleNumber': vehicleNumber,
      },
      'cuttingSpec': {
        'strategy': cuttingStrategy.firestoreValue,
        'targetProduct': targetProduct.name,
        'sizes': sizes,
        'thickness': thickness,
        'finish': finish.name,
        if (expectedOutputSqFt != null)
          'expectedOutputSqFt': expectedOutputSqFt,
        if (specialInstructions != null)
          'specialInstructions': specialInstructions,
      },
      'pricing': {
        'model': pricingModel.name,
        'agreedRate': agreedRate,
        'estimatedTotal': estimatedTotal,
        'negotiatedFinalAmount': negotiatedFinalAmount,
        'advanceReceived': advanceReceived,
        'balanceDue': balanceDue,
        'paymentTerms': paymentTerms.name,
        if (paymentDueDate != null)
          'paymentDueDate': Timestamp.fromDate(paymentDueDate!),
      },
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  JobWorkOrder toEntity() {
    return JobWorkOrder(
      id: id,
      jobWorkNumber: jobWorkNumber,
      factoryId: factoryId,
      customerId: customerId,
      customerName: customerName,
      status: status,
      receivedDate: receivedDate,
      expectedCompletionDate: expectedCompletionDate,
      marbleVariety: marbleVariety,
      blockCount: blockCount,
      totalTons: totalTons,
      totalVolumeM3: totalVolumeM3,
      blockDimensions: blockDimensions,
      conditionNotes: conditionNotes,
      vehicleNumber: vehicleNumber,
      cuttingStrategy: cuttingStrategy,
      targetProduct: targetProduct,
      sizes: sizes,
      thickness: thickness,
      finish: finish,
      expectedOutputSqFt: expectedOutputSqFt,
      specialInstructions: specialInstructions,
      pricingModel: pricingModel,
      agreedRate: agreedRate,
      estimatedTotal: estimatedTotal,
      negotiatedFinalAmount: negotiatedFinalAmount,
      advanceReceived: advanceReceived,
      balanceDue: balanceDue,
      paymentTerms: paymentTerms,
      paymentDueDate: paymentDueDate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory JobWorkOrderModel.fromEntity(JobWorkOrder order) {
    return JobWorkOrderModel(
      id: order.id,
      jobWorkNumber: order.jobWorkNumber,
      factoryId: order.factoryId,
      customerId: order.customerId,
      customerName: order.customerName,
      status: order.status,
      receivedDate: order.receivedDate,
      expectedCompletionDate: order.expectedCompletionDate,
      marbleVariety: order.marbleVariety,
      blockCount: order.blockCount,
      totalTons: order.totalTons,
      totalVolumeM3: order.totalVolumeM3,
      blockDimensions: order.blockDimensions,
      conditionNotes: order.conditionNotes,
      vehicleNumber: order.vehicleNumber,
      cuttingStrategy: order.cuttingStrategy,
      targetProduct: order.targetProduct,
      sizes: order.sizes,
      thickness: order.thickness,
      finish: order.finish,
      expectedOutputSqFt: order.expectedOutputSqFt,
      specialInstructions: order.specialInstructions,
      pricingModel: order.pricingModel,
      agreedRate: order.agreedRate,
      estimatedTotal: order.estimatedTotal,
      negotiatedFinalAmount: order.negotiatedFinalAmount,
      advanceReceived: order.advanceReceived,
      balanceDue: order.balanceDue,
      paymentTerms: order.paymentTerms,
      paymentDueDate: order.paymentDueDate,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }
}
