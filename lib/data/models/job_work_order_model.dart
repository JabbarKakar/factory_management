import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';
import '../../domain/enums/customer_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../core/constants/job_work_sizes.dart';

class JobWorkOrderModel {
  const JobWorkOrderModel({
    required this.id,
    required this.jobWorkNumber,
    required this.factoryId,
    required this.customerId,
    required this.customerName,
    required this.status,
    required this.receivedDate,
    this.mineLocation,
    this.mineOwner,
    required this.marbleVariety,
    required this.blockCount,
    required this.totalTons,
    required this.cuttingStrategy,
    required this.targetProduct,
    this.smallSizes = const [],
    this.largeSizes = const [],
    this.legacySizes = const [],
    required this.thickness,
    required this.finish,
    required this.pricingModel,
    required this.agreedRate,
    this.smallStockPrice = 0,
    this.largeStockPrice = 0,
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
    this.output,
    this.execution,
    this.shiftLogs = const [],
    this.invoiceId,
    this.collectedAt,
    this.closedAt,
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
  final String? mineLocation;
  final String? mineOwner;
  final String marbleVariety;
  final int blockCount;
  final double totalTons;
  final double? totalVolumeM3;
  final String? blockDimensions;
  final String? conditionNotes;
  final String? vehicleNumber;
  final CuttingStrategy cuttingStrategy;
  final TargetProduct targetProduct;
  final List<String> smallSizes;
  final List<String> largeSizes;
  final List<String> legacySizes;
  final String thickness;
  final FinishType finish;
  final double? expectedOutputSqFt;
  final String? specialInstructions;
  final PricingModel pricingModel;
  final double agreedRate;
  final double smallStockPrice;
  final double largeStockPrice;
  final double estimatedTotal;
  final double negotiatedFinalAmount;
  final double advanceReceived;
  final double balanceDue;
  final PaymentTerms paymentTerms;
  final DateTime? paymentDueDate;
  final JobWorkOutput? output;
  final JobWorkExecution? execution;
  final List<JobWorkShiftLog> shiftLogs;
  final String? invoiceId;
  final DateTime? collectedAt;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory JobWorkOrderModel.fromFirestore(String id, Map<String, dynamic> data) {
    final cuttingSpec = data['cuttingSpec'] as Map<String, dynamic>? ?? {};
    final input = data['input'] as Map<String, dynamic>? ?? {};
    final pricing = data['pricing'] as Map<String, dynamic>? ?? {};
    final outputData = data['output'] as Map<String, dynamic>?;
    final executionData = data['execution'] as Map<String, dynamic>?;
    final shiftLogsData = data['outputShifts'] as List?;
    final parsedSizes = JobWorkSizes.fromCuttingSpec(cuttingSpec);

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
      mineLocation: data['mineLocation'] as String?,
      mineOwner: data['mineOwner'] as String?,
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
      smallSizes: parsedSizes.smallSizes,
      largeSizes: parsedSizes.largeSizes,
      legacySizes: parsedSizes.legacySizes,
      thickness: cuttingSpec['thickness'] as String? ?? '',
      finish: FinishType.fromString(cuttingSpec['finish'] as String?),
      expectedOutputSqFt:
          (cuttingSpec['expectedOutputSqFt'] as num?)?.toDouble(),
      specialInstructions: cuttingSpec['specialInstructions'] as String?,
      pricingModel: PricingModel.fromString(pricing['model'] as String?),
      agreedRate: (pricing['agreedRate'] as num?)?.toDouble() ?? 0,
      smallStockPrice: (pricing['smallStockPrice'] as num?)?.toDouble() ?? 0,
      largeStockPrice: (pricing['largeStockPrice'] as num?)?.toDouble() ?? 0,
      estimatedTotal: (pricing['estimatedTotal'] as num?)?.toDouble() ?? 0,
      negotiatedFinalAmount:
          (pricing['negotiatedFinalAmount'] as num?)?.toDouble() ?? 0,
      advanceReceived: (pricing['advanceReceived'] as num?)?.toDouble() ?? 0,
      balanceDue: (pricing['balanceDue'] as num?)?.toDouble() ?? 0,
      paymentTerms: PaymentTerms.fromString(pricing['paymentTerms'] as String?),
      paymentDueDate: (pricing['paymentDueDate'] as Timestamp?)?.toDate(),
      output: outputData == null ? null : _outputFromMap(outputData),
      execution:
          executionData == null ? null : _executionFromMap(executionData),
      shiftLogs: shiftLogsData == null
          ? const []
          : shiftLogsData
              .whereType<Map>()
              .map((item) => _shiftLogFromMap(item.cast<String, dynamic>()))
              .toList(),
      invoiceId: data['invoiceId'] as String?,
      collectedAt: (data['collectedAt'] as Timestamp?)?.toDate(),
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  static JobWorkOutput _outputFromMap(Map<String, dynamic> data) {
    final wasteUnit = WasteUnit.fromString(data['wasteUnit'] as String?);
    final wasteTons = (data['wasteTons'] as num?)?.toDouble();
    final wasteSqFt = (data['wasteSqFt'] as num?)?.toDouble();

    return JobWorkOutput(
      gradeASqFt: (data['gradeASqFt'] as num?)?.toDouble() ?? 0,
      gradeBSqFt: (data['gradeBSqFt'] as num?)?.toDouble() ?? 0,
      gradeCSqFt: (data['gradeCSqFt'] as num?)?.toDouble() ?? 0,
      rejectSqFt: (data['rejectSqFt'] as num?)?.toDouble() ?? 0,
      wasteAmount: wasteUnit == WasteUnit.sqFt
          ? (wasteSqFt ?? 0)
          : (wasteTons ?? (data['wasteAmount'] as num?)?.toDouble() ?? 0),
      wasteUnit: wasteUnit,
      slurryDust: data['slurryDust'] as String?,
      wasteDisposition: WasteDisposition.fromString(
        data['wasteDisposition'] as String?,
      ),
      recordedAt: (data['recordedAt'] as Timestamp?)?.toDate(),
    );
  }

  static JobWorkExecution _executionFromMap(Map<String, dynamic> data) {
    return JobWorkExecution(
      cuttingStartDate: (data['startDate'] as Timestamp?)?.toDate(),
      cuttingCompletionDate: (data['endDate'] as Timestamp?)?.toDate(),
      supervisorName: data['supervisor'] as String?,
      progressNotes: data['progressNotes'] as String?,
    );
  }

  static JobWorkShiftLog _shiftLogFromMap(Map<String, dynamic> data) {
    return JobWorkShiftLog(
      id: data['id'] as String? ?? '',
      shiftDate:
          (data['shiftDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      shiftName: data['shiftName'] as String?,
      gradeASqFt: (data['gradeASqFt'] as num?)?.toDouble() ?? 0,
      gradeBSqFt: (data['gradeBSqFt'] as num?)?.toDouble() ?? 0,
      gradeCSqFt: (data['gradeCSqFt'] as num?)?.toDouble() ?? 0,
      rejectSqFt: (data['rejectSqFt'] as num?)?.toDouble() ?? 0,
      wasteAmount: (data['wasteAmount'] as num?)?.toDouble() ?? 0,
      wasteUnit: WasteUnit.fromString(data['wasteUnit'] as String?),
      notes: data['notes'] as String?,
      recordedAt:
          (data['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
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
      if (mineLocation != null) 'mineLocation': mineLocation,
      if (mineOwner != null) 'mineOwner': mineOwner,
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
        'smallSizes': smallSizes,
        'largeSizes': largeSizes,
        if (legacySizes.isNotEmpty) 'legacySizes': legacySizes,
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
        'smallStockPrice': smallStockPrice,
        'largeStockPrice': largeStockPrice,
        'estimatedTotal': estimatedTotal,
        'negotiatedFinalAmount': negotiatedFinalAmount,
        'advanceReceived': advanceReceived,
        'balanceDue': balanceDue,
        'paymentTerms': paymentTerms.name,
        if (paymentDueDate != null)
          'paymentDueDate': Timestamp.fromDate(paymentDueDate!),
      },
      if (output != null) 'output': _outputToMap(output!, totalTons),
      if (execution != null && execution!.hasData)
        'execution': _executionToMap(execution!),
      if (shiftLogs.isNotEmpty)
        'outputShifts': shiftLogs.map(_shiftLogToMap).toList(),
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (collectedAt != null) 'collectedAt': Timestamp.fromDate(collectedAt!),
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static Map<String, dynamic> _outputToMap(
    JobWorkOutput output,
    double inputTons,
  ) {
    final wastePercent = output.wastePercent(inputTons);
    final yieldPercent = output.yieldPercent(null);

    return {
      'gradeASqFt': output.gradeASqFt,
      'gradeBSqFt': output.gradeBSqFt,
      'gradeCSqFt': output.gradeCSqFt,
      'rejectSqFt': output.rejectSqFt,
      'totalUsableSqFt': output.totalUsableSqFt,
      if (output.wasteUnit == WasteUnit.tons) 'wasteTons': output.wasteAmount,
      if (output.wasteUnit == WasteUnit.sqFt) 'wasteSqFt': output.wasteAmount,
      'wasteUnit': output.wasteUnit.firestoreValue,
      'wasteAmount': output.wasteAmount,
      'wastePercent': wastePercent,
      'yieldPercent': yieldPercent,
      if (output.slurryDust != null) 'slurryDust': output.slurryDust,
      'wasteDisposition': output.wasteDisposition.firestoreValue,
      if (output.recordedAt != null)
        'recordedAt': Timestamp.fromDate(output.recordedAt!),
    };
  }

  static Map<String, dynamic> _outputToMapWithExpected(
    JobWorkOutput output,
    double inputTons,
    double? expectedSqFt,
  ) {
    final map = _outputToMap(output, inputTons);
    map['yieldPercent'] = output.yieldPercent(expectedSqFt);
    return map;
  }

  Map<String, dynamic> toFirestoreWithComputedYield() {
    final data = toFirestore();
    final outputValue = output;
    if (outputValue != null) {
      data['output'] = _outputToMapWithExpected(
        outputValue,
        totalTons,
        expectedOutputSqFt,
      );
    }
    return data;
  }

  static Map<String, dynamic> _executionToMap(JobWorkExecution execution) {
    return {
      if (execution.cuttingStartDate != null)
        'startDate': Timestamp.fromDate(execution.cuttingStartDate!),
      if (execution.cuttingCompletionDate != null)
        'endDate': Timestamp.fromDate(execution.cuttingCompletionDate!),
      if (execution.supervisorName != null)
        'supervisor': execution.supervisorName,
      if (execution.progressNotes != null)
        'progressNotes': execution.progressNotes,
    };
  }

  static Map<String, dynamic> _shiftLogToMap(JobWorkShiftLog shift) {
    return {
      'id': shift.id,
      'shiftDate': Timestamp.fromDate(shift.shiftDate),
      if (shift.shiftName != null) 'shiftName': shift.shiftName,
      'gradeASqFt': shift.gradeASqFt,
      'gradeBSqFt': shift.gradeBSqFt,
      'gradeCSqFt': shift.gradeCSqFt,
      'rejectSqFt': shift.rejectSqFt,
      'wasteAmount': shift.wasteAmount,
      'wasteUnit': shift.wasteUnit.firestoreValue,
      if (shift.notes != null) 'notes': shift.notes,
      'recordedAt': Timestamp.fromDate(shift.recordedAt),
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
      mineLocation: mineLocation,
      mineOwner: mineOwner,
      marbleVariety: marbleVariety,
      blockCount: blockCount,
      totalTons: totalTons,
      totalVolumeM3: totalVolumeM3,
      blockDimensions: blockDimensions,
      conditionNotes: conditionNotes,
      vehicleNumber: vehicleNumber,
      cuttingStrategy: cuttingStrategy,
      targetProduct: targetProduct,
      smallSizes: smallSizes,
      largeSizes: largeSizes,
      legacySizes: legacySizes,
      thickness: thickness,
      finish: finish,
      expectedOutputSqFt: expectedOutputSqFt,
      specialInstructions: specialInstructions,
      pricingModel: pricingModel,
      agreedRate: agreedRate,
      smallStockPrice: smallStockPrice,
      largeStockPrice: largeStockPrice,
      estimatedTotal: estimatedTotal,
      negotiatedFinalAmount: negotiatedFinalAmount,
      advanceReceived: advanceReceived,
      balanceDue: balanceDue,
      paymentTerms: paymentTerms,
      paymentDueDate: paymentDueDate,
      output: output,
      execution: execution,
      shiftLogs: shiftLogs,
      invoiceId: invoiceId,
      collectedAt: collectedAt,
      closedAt: closedAt,
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
      mineLocation: order.mineLocation,
      mineOwner: order.mineOwner,
      marbleVariety: order.marbleVariety,
      blockCount: order.blockCount,
      totalTons: order.totalTons,
      totalVolumeM3: order.totalVolumeM3,
      blockDimensions: order.blockDimensions,
      conditionNotes: order.conditionNotes,
      vehicleNumber: order.vehicleNumber,
      cuttingStrategy: order.cuttingStrategy,
      targetProduct: order.targetProduct,
      smallSizes: order.smallSizes,
      largeSizes: order.largeSizes,
      legacySizes: order.legacySizes,
      thickness: order.thickness,
      finish: order.finish,
      expectedOutputSqFt: order.expectedOutputSqFt,
      specialInstructions: order.specialInstructions,
      pricingModel: order.pricingModel,
      agreedRate: order.agreedRate,
      smallStockPrice: order.smallStockPrice,
      largeStockPrice: order.largeStockPrice,
      estimatedTotal: order.estimatedTotal,
      negotiatedFinalAmount: order.negotiatedFinalAmount,
      advanceReceived: order.advanceReceived,
      balanceDue: order.balanceDue,
      paymentTerms: order.paymentTerms,
      paymentDueDate: order.paymentDueDate,
      output: order.output,
      execution: order.execution,
      shiftLogs: order.shiftLogs,
      invoiceId: order.invoiceId,
      collectedAt: order.collectedAt,
      closedAt: order.closedAt,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
    );
  }
}
