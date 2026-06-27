part of 'qc_form_bloc.dart';

enum QcFormStatus { initial, loading, ready, saving, saved, failure }

class QcFormPrefill extends Equatable {
  const QcFormPrefill({
    this.productLabel,
    this.marbleVariety,
    this.sizeThickness,
    this.quantityInspected,
    this.gradeASqFt,
    this.gradeBSqFt,
    this.gradeCSqFt,
    this.rejectSqFt,
  });

  final String? productLabel;
  final String? marbleVariety;
  final String? sizeThickness;
  final double? quantityInspected;
  final double? gradeASqFt;
  final double? gradeBSqFt;
  final double? gradeCSqFt;
  final double? rejectSqFt;

  @override
  List<Object?> get props => [
        productLabel,
        marbleVariety,
        sizeThickness,
        quantityInspected,
        gradeASqFt,
        gradeBSqFt,
        gradeCSqFt,
        rejectSqFt,
      ];
}

class QcFormState extends Equatable {
  const QcFormState({
    this.status = QcFormStatus.initial,
    this.productionBatches = const [],
    this.jobWorkOrders = const [],
    this.referenceType = QcReferenceType.production,
    this.selectedBatch,
    this.selectedOrder,
    this.prefill = const QcFormPrefill(),
    this.errorMessage,
    this.pendingMarkReadyJobWorkId,
    this.advancedToQc = false,
    this.markedReady = false,
  });

  final QcFormStatus status;
  final List<ProductionBatch> productionBatches;
  final List<JobWorkOrder> jobWorkOrders;
  final QcReferenceType referenceType;
  final ProductionBatch? selectedBatch;
  final JobWorkOrder? selectedOrder;
  final QcFormPrefill prefill;
  final String? errorMessage;
  final String? pendingMarkReadyJobWorkId;
  final bool advancedToQc;
  final bool markedReady;

  bool get hasSelectedReference =>
      selectedBatch != null || selectedOrder != null;

  QcFormState copyWith({
    QcFormStatus? status,
    List<ProductionBatch>? productionBatches,
    List<JobWorkOrder>? jobWorkOrders,
    QcReferenceType? referenceType,
    ProductionBatch? selectedBatch,
    bool clearSelectedBatch = false,
    JobWorkOrder? selectedOrder,
    bool clearSelectedOrder = false,
    QcFormPrefill? prefill,
    String? errorMessage,
    String? pendingMarkReadyJobWorkId,
    bool clearPendingMarkReady = false,
    bool? advancedToQc,
    bool? markedReady,
    bool clearWorkflow = false,
  }) {
    return QcFormState(
      status: status ?? this.status,
      productionBatches: productionBatches ?? this.productionBatches,
      jobWorkOrders: jobWorkOrders ?? this.jobWorkOrders,
      referenceType: referenceType ?? this.referenceType,
      selectedBatch:
          clearSelectedBatch ? null : (selectedBatch ?? this.selectedBatch),
      selectedOrder:
          clearSelectedOrder ? null : (selectedOrder ?? this.selectedOrder),
      prefill: prefill ?? this.prefill,
      errorMessage: errorMessage,
      pendingMarkReadyJobWorkId: clearWorkflow || clearPendingMarkReady
          ? null
          : (pendingMarkReadyJobWorkId ?? this.pendingMarkReadyJobWorkId),
      advancedToQc:
          clearWorkflow ? false : (advancedToQc ?? this.advancedToQc),
      markedReady: clearWorkflow ? false : (markedReady ?? this.markedReady),
    );
  }

  @override
  List<Object?> get props => [
        status,
        productionBatches,
        jobWorkOrders,
        referenceType,
        selectedBatch,
        selectedOrder,
        prefill,
        errorMessage,
        pendingMarkReadyJobWorkId,
        advancedToQc,
        markedReady,
      ];
}
