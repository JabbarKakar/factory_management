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
    this.output,
    this.execution,
    this.shiftLogs = const [],
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
  final List<String> sizes;
  final String thickness;
  final FinishType finish;
  final double? expectedOutputSqFt;
  final String? specialInstructions;

  // Pricing
  final PricingModel pricingModel;
  final double agreedRate;
  final double estimatedTotal;
  final double negotiatedFinalAmount;
  final double advanceReceived;
  final double balanceDue;
  final PaymentTerms paymentTerms;
  final DateTime? paymentDueDate;

  final JobWorkOutput? output;
  final JobWorkExecution? execution;
  final List<JobWorkShiftLog> shiftLogs;

  final DateTime createdAt;
  final DateTime? updatedAt;

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
    String? marbleVariety,
    int? blockCount,
    double? totalTons,
    double? totalVolumeM3,
    String? blockDimensions,
    String? conditionNotes,
    String? vehicleNumber,
    CuttingStrategy? cuttingStrategy,
    TargetProduct? targetProduct,
    List<String>? sizes,
    String? thickness,
    FinishType? finish,
    double? expectedOutputSqFt,
    String? specialInstructions,
    PricingModel? pricingModel,
    double? agreedRate,
    double? estimatedTotal,
    double? negotiatedFinalAmount,
    double? advanceReceived,
    double? balanceDue,
    PaymentTerms? paymentTerms,
    DateTime? paymentDueDate,
    JobWorkOutput? output,
    JobWorkExecution? execution,
    List<JobWorkShiftLog>? shiftLogs,
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
      marbleVariety: marbleVariety ?? this.marbleVariety,
      blockCount: blockCount ?? this.blockCount,
      totalTons: totalTons ?? this.totalTons,
      totalVolumeM3: totalVolumeM3 ?? this.totalVolumeM3,
      blockDimensions: blockDimensions ?? this.blockDimensions,
      conditionNotes: conditionNotes ?? this.conditionNotes,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      cuttingStrategy: cuttingStrategy ?? this.cuttingStrategy,
      targetProduct: targetProduct ?? this.targetProduct,
      sizes: sizes ?? this.sizes,
      thickness: thickness ?? this.thickness,
      finish: finish ?? this.finish,
      expectedOutputSqFt: expectedOutputSqFt ?? this.expectedOutputSqFt,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      pricingModel: pricingModel ?? this.pricingModel,
      agreedRate: agreedRate ?? this.agreedRate,
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
        marbleVariety,
        blockCount,
        totalTons,
        totalVolumeM3,
        blockDimensions,
        conditionNotes,
        vehicleNumber,
        cuttingStrategy,
        targetProduct,
        sizes,
        thickness,
        finish,
        expectedOutputSqFt,
        specialInstructions,
        pricingModel,
        agreedRate,
        estimatedTotal,
        negotiatedFinalAmount,
        advanceReceived,
        balanceDue,
        paymentTerms,
        paymentDueDate,
        output,
        execution,
        shiftLogs,
        createdAt,
        updatedAt,
      ];
}
