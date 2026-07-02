import 'package:equatable/equatable.dart';

import '../enums/customer_enums.dart';
import '../enums/job_work_enums.dart';
import 'job_work_output.dart';

class JobWorkOrder extends Equatable {
  const JobWorkOrder({
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
    this.finalCuttingCharges = 0,
    required this.advanceReceived,
    required this.balanceDue,
    required this.paymentTerms,
    required this.createdAt,
    this.expectedCompletionDate,
    this.totalVolumeM3,
    this.blockDimensions,
    this.conditionNotes,
    this.vehicleNumber,
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

  // Mine source
  final String? mineLocation;
  final String? mineOwner;

  // Input
  final String marbleVariety;
  final int blockCount;
  final double totalTons;
  final double? totalVolumeM3;
  final String? blockDimensions;
  final String? conditionNotes;
  final String? vehicleNumber;

  // Cutting spec
  final CuttingStrategy cuttingStrategy;
  final TargetProduct targetProduct;
  final List<String> smallSizes;
  final List<String> largeSizes;

  /// Pre-catalog values from older `cuttingSpec.sizes` documents.
  final List<String> legacySizes;
  final String thickness;
  final FinishType finish;
  final String? specialInstructions;

  // Pricing
  final PricingModel pricingModel;
  final double agreedRate;
  final double smallStockPrice;
  final double largeStockPrice;

  /// Finalized when output is recorded (replaces legacy negotiated amount).
  final double finalCuttingCharges;
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

  List<String> get allSizes => [
        ...smallSizes,
        ...largeSizes,
        ...legacySizes,
      ];

  bool get hasAnySize => allSizes.isNotEmpty;

  bool get hasFinalCuttingCharges => finalCuttingCharges > 0;

  JobWorkOrder copyWith({
    String? id,
    String? jobWorkNumber,
    String? factoryId,
    String? customerId,
    String? customerName,
    JobWorkStatus? status,
    DateTime? receivedDate,
    DateTime? expectedCompletionDate,
    String? mineLocation,
    String? mineOwner,
    String? marbleVariety,
    int? blockCount,
    double? totalTons,
    double? totalVolumeM3,
    String? blockDimensions,
    String? conditionNotes,
    String? vehicleNumber,
    CuttingStrategy? cuttingStrategy,
    TargetProduct? targetProduct,
    List<String>? smallSizes,
    List<String>? largeSizes,
    List<String>? legacySizes,
    String? thickness,
    FinishType? finish,
    String? specialInstructions,
    PricingModel? pricingModel,
    double? agreedRate,
    double? smallStockPrice,
    double? largeStockPrice,
    double? finalCuttingCharges,
    double? advanceReceived,
    double? balanceDue,
    PaymentTerms? paymentTerms,
    DateTime? paymentDueDate,
    JobWorkOutput? output,
    JobWorkExecution? execution,
    List<JobWorkShiftLog>? shiftLogs,
    String? invoiceId,
    DateTime? collectedAt,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return JobWorkOrder(
      id: id ?? this.id,
      jobWorkNumber: jobWorkNumber ?? this.jobWorkNumber,
      factoryId: factoryId ?? this.factoryId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      status: status ?? this.status,
      receivedDate: receivedDate ?? this.receivedDate,
      expectedCompletionDate:
          expectedCompletionDate ?? this.expectedCompletionDate,
      mineLocation: mineLocation ?? this.mineLocation,
      mineOwner: mineOwner ?? this.mineOwner,
      marbleVariety: marbleVariety ?? this.marbleVariety,
      blockCount: blockCount ?? this.blockCount,
      totalTons: totalTons ?? this.totalTons,
      totalVolumeM3: totalVolumeM3 ?? this.totalVolumeM3,
      blockDimensions: blockDimensions ?? this.blockDimensions,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      cuttingStrategy: cuttingStrategy ?? this.cuttingStrategy,
      targetProduct: targetProduct ?? this.targetProduct,
      smallSizes: smallSizes ?? this.smallSizes,
      largeSizes: largeSizes ?? this.largeSizes,
      legacySizes: legacySizes ?? this.legacySizes,
      thickness: thickness ?? this.thickness,
      finish: finish ?? this.finish,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      pricingModel: pricingModel ?? this.pricingModel,
      agreedRate: agreedRate ?? this.agreedRate,
      smallStockPrice: smallStockPrice ?? this.smallStockPrice,
      largeStockPrice: largeStockPrice ?? this.largeStockPrice,
      finalCuttingCharges: finalCuttingCharges ?? this.finalCuttingCharges,
      advanceReceived: advanceReceived ?? this.advanceReceived,
      balanceDue: balanceDue ?? this.balanceDue,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      output: output ?? this.output,
      execution: execution ?? this.execution,
      shiftLogs: shiftLogs ?? this.shiftLogs,
      invoiceId: invoiceId ?? this.invoiceId,
      collectedAt: collectedAt ?? this.collectedAt,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        jobWorkNumber,
        factoryId,
        customerId,
        customerName,
        status,
        receivedDate,
        expectedCompletionDate,
        mineLocation,
        mineOwner,
        marbleVariety,
        blockCount,
        totalTons,
        totalVolumeM3,
        blockDimensions,
        conditionNotes,
        vehicleNumber,
        cuttingStrategy,
        targetProduct,
        smallSizes,
        largeSizes,
        legacySizes,
        thickness,
        finish,
        specialInstructions,
        pricingModel,
        agreedRate,
        smallStockPrice,
        largeStockPrice,
        finalCuttingCharges,
        advanceReceived,
        balanceDue,
        paymentTerms,
        paymentDueDate,
        output,
        execution,
        shiftLogs,
        invoiceId,
        collectedAt,
        closedAt,
        createdAt,
        updatedAt,
      ];
}
