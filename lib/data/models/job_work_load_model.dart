import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/enums/job_work_load_enums.dart';
import 'job_work_order_model.dart';

class JobWorkLoadModel {
  const JobWorkLoadModel({required this.load});

  final JobWorkLoad load;

  factory JobWorkLoadModel.fromFirestore(String id, Map<String, dynamic> data) {
    final orderModel = JobWorkOrderModel.fromFirestore(id, data);
    final order = orderModel.toEntity();
    return JobWorkLoadModel(
      load: JobWorkLoad(
        id: id,
        loadNumber: data['loadNumber'] as String? ?? '',
        loadSequence: (data['loadSequence'] as num?)?.toInt() ?? 1,
        jobWorkId: data['jobWorkId'] as String? ?? '',
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
        specialInstructions: order.specialInstructions,
        pricingModel: order.pricingModel,
        agreedRate: order.agreedRate,
        smallStockPrice: order.smallStockPrice,
        largeStockPrice: order.largeStockPrice,
        finalCuttingCharges: order.finalCuttingCharges,
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
        migratedFromJobWork: data['migratedFromJobWork'] as bool? ?? false,
        isVirtual: false,
      ),
    );
  }

  factory JobWorkLoadModel.fromEntity(JobWorkLoad load) =>
      JobWorkLoadModel(load: load);

  JobWorkLoad toEntity() => load;

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    final asOrder = JobWorkOrder(
      id: load.id,
      jobWorkNumber: load.jobWorkNumber,
      factoryId: load.factoryId,
      customerId: load.customerId,
      customerName: load.customerName,
      status: load.status,
      receivedDate: load.receivedDate,
      expectedCompletionDate: load.expectedCompletionDate,
      mineLocation: load.mineLocation,
      mineOwner: load.mineOwner,
      marbleVariety: load.marbleVariety,
      blockCount: load.blockCount,
      totalTons: load.totalTons,
      totalVolumeM3: load.totalVolumeM3,
      blockDimensions: load.blockDimensions,
      conditionNotes: load.conditionNotes,
      vehicleNumber: load.vehicleNumber,
      cuttingStrategy: load.cuttingStrategy,
      targetProduct: load.targetProduct,
      smallSizes: load.smallSizes,
      largeSizes: load.largeSizes,
      legacySizes: load.legacySizes,
      thickness: load.thickness,
      finish: load.finish,
      specialInstructions: load.specialInstructions,
      pricingModel: load.pricingModel,
      agreedRate: load.agreedRate,
      smallStockPrice: load.smallStockPrice,
      largeStockPrice: load.largeStockPrice,
      finalCuttingCharges: load.finalCuttingCharges,
      advanceReceived: load.advanceReceived,
      balanceDue: load.balanceDue,
      paymentTerms: load.paymentTerms,
      paymentDueDate: load.paymentDueDate,
      output: load.output,
      execution: load.execution,
      shiftLogs: load.shiftLogs,
      invoiceId: load.invoiceId,
      collectedAt: load.collectedAt,
      closedAt: load.closedAt,
      createdAt: load.createdAt,
      updatedAt: load.updatedAt,
      schemaVersion: JobWorkSchemaVersion.loadsAuthoritative,
    );

    final map = JobWorkOrderModel.fromEntity(asOrder).toFirestore(isCreate: isCreate);
    map.remove('schemaVersion');
    map.remove('summaryStatus');
    map.remove('defaultLoadId');
    map.remove('loadCount');
    map.remove('activeLoadCount');
    map['loadNumber'] = load.loadNumber;
    map['loadSequence'] = load.loadSequence;
    map['jobWorkId'] = load.jobWorkId;
    map['migratedFromJobWork'] = load.migratedFromJobWork;
    return map;
  }
}
