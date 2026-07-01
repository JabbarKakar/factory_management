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
  final double? expectedOutputSqFt;
  final String? specialInstructions;

  // Pricing
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

  List<String> get allSizes => [
        ...smallSizes,
        ...largeSizes,
        ...legacySizes,
      ];

  bool get hasAnySize => allSizes.isNotEmpty;

  static double calculateEstimatedTotalFromStockPrices({
    required double smallStockPrice,
    required double largeStockPrice,
    required int smallSizeCount,
    required int largeSizeCount,
    int legacySizeCount = 0,
  }) {
    return (smallStockPrice * smallSizeCount) +
        (largeStockPrice * largeSizeCount) +
        (smallStockPrice * legacySizeCount);
  }

  static double calculateEstimatedTotal({
    required PricingModel model,
    required double agreedRate,
    required double totalTons,
    required int blockCount,
    double? expectedOutputSqFt,
  }) {
    return switch (model) {
      PricingModel.perTon => agreedRate * totalTons,
      PricingModel.perSqFt => agreedRate * (expectedOutputSqFt ?? 0),
      PricingModel.perBlock => agreedRate * blockCount,
      PricingModel.lumpSum => agreedRate,
    };
  }

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
    double? expectedOutputSqFt,
    String? specialInstructions,
    PricingModel? pricingModel,
    double? agreedRate,
    double? smallStockPrice,
    double? largeStockPrice,
    double? estimatedTotal,
    double? negotiatedFinalAmount,
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
      expectedOutputSqFt: expectedOutputSqFt ?? this.expectedOutputSqFt,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      pricingModel: pricingModel ?? this.pricingModel,
      agreedRate: agreedRate ?? this.agreedRate,
      smallStockPrice: smallStockPrice ?? this.smallStockPrice,
      largeStockPrice: largeStockPrice ?? this.largeStockPrice,
      estimatedTotal: estimatedTotal ?? this.estimatedTotal,
      negotiatedFinalAmount:
          negotiatedFinalAmount ?? this.negotiatedFinalAmount,
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
        expectedOutputSqFt,
        specialInstructions,
        pricingModel,
        agreedRate,
        smallStockPrice,
        largeStockPrice,
        estimatedTotal,
        negotiatedFinalAmount,
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
