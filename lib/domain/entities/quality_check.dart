import 'package:equatable/equatable.dart';

import '../enums/quality_enums.dart';

class QualityCheck extends Equatable {
  const QualityCheck({
    required this.id,
    required this.qcNumber,
    required this.factoryId,
    required this.referenceType,
    required this.referenceId,
    required this.referenceNumber,
    required this.referenceLabel,
    required this.productLabel,
    required this.marbleVariety,
    required this.inspectionDate,
    required this.inspectorName,
    required this.quantityInspected,
    required this.gradeASqFt,
    required this.gradeBSqFt,
    required this.gradeCSqFt,
    required this.rejectSqFt,
    required this.defects,
    required this.disposition,
    required this.createdAt,
    this.sizeThickness,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String qcNumber;
  final String factoryId;
  final QcReferenceType referenceType;
  final String referenceId;
  final String referenceNumber;
  final String referenceLabel;
  final String productLabel;
  final String marbleVariety;
  final String? sizeThickness;
  final DateTime inspectionDate;
  final String inspectorName;
  final double quantityInspected;
  final double gradeASqFt;
  final double gradeBSqFt;
  final double gradeCSqFt;
  final double rejectSqFt;
  final List<QcDefectType> defects;
  final QcDisposition disposition;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  double get totalUsableSqFt => gradeASqFt + gradeBSqFt + gradeCSqFt;

  double get totalGradedSqFt => totalUsableSqFt + rejectSqFt;

  double get passRatePercent {
    if (quantityInspected <= 0) return 0;
    return (totalUsableSqFt / quantityInspected) * 100;
  }

  String get referenceTypeLabel => referenceType.label;

  QualityCheck copyWith({
    String? id,
    String? qcNumber,
    String? factoryId,
    QcReferenceType? referenceType,
    String? referenceId,
    String? referenceNumber,
    String? referenceLabel,
    String? productLabel,
    String? marbleVariety,
    String? sizeThickness,
    DateTime? inspectionDate,
    String? inspectorName,
    double? quantityInspected,
    double? gradeASqFt,
    double? gradeBSqFt,
    double? gradeCSqFt,
    double? rejectSqFt,
    List<QcDefectType>? defects,
    QcDisposition? disposition,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QualityCheck(
      id: id ?? this.id,
      qcNumber: qcNumber ?? this.qcNumber,
      factoryId: factoryId ?? this.factoryId,
      referenceType: referenceType ?? this.referenceType,
      referenceId: referenceId ?? this.referenceId,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      referenceLabel: referenceLabel ?? this.referenceLabel,
      productLabel: productLabel ?? this.productLabel,
      marbleVariety: marbleVariety ?? this.marbleVariety,
      sizeThickness: sizeThickness ?? this.sizeThickness,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      inspectorName: inspectorName ?? this.inspectorName,
      quantityInspected: quantityInspected ?? this.quantityInspected,
      gradeASqFt: gradeASqFt ?? this.gradeASqFt,
      gradeBSqFt: gradeBSqFt ?? this.gradeBSqFt,
      gradeCSqFt: gradeCSqFt ?? this.gradeCSqFt,
      rejectSqFt: rejectSqFt ?? this.rejectSqFt,
      defects: defects ?? this.defects,
      disposition: disposition ?? this.disposition,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        qcNumber,
        factoryId,
        referenceType,
        referenceId,
        referenceNumber,
        referenceLabel,
        productLabel,
        marbleVariety,
        sizeThickness,
        inspectionDate,
        inspectorName,
        quantityInspected,
        gradeASqFt,
        gradeBSqFt,
        gradeCSqFt,
        rejectSqFt,
        defects,
        disposition,
        notes,
        createdAt,
        updatedAt,
      ];
}
