import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/quality_check.dart';
import '../../domain/enums/quality_enums.dart';

class QualityCheckModel {
  const QualityCheckModel({
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

  factory QualityCheckModel.fromFirestore(String id, Map<String, dynamic> data) {
    final defectValues = (data['defects'] as List<dynamic>?)
            ?.map((value) => QcDefectType.fromString(value as String?))
            .toList() ??
        const <QcDefectType>[];

    return QualityCheckModel(
      id: id,
      qcNumber: data['qcNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      referenceType:
          QcReferenceType.fromString(data['referenceType'] as String?),
      referenceId: data['referenceId'] as String? ?? '',
      referenceNumber: data['referenceNumber'] as String? ?? '',
      referenceLabel: data['referenceLabel'] as String? ?? '',
      productLabel: data['productLabel'] as String? ?? '',
      marbleVariety: data['marbleVariety'] as String? ?? '',
      sizeThickness: data['sizeThickness'] as String?,
      inspectionDate:
          (data['inspectionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      inspectorName: data['inspectorName'] as String? ?? '',
      quantityInspected: (data['quantityInspected'] as num?)?.toDouble() ?? 0,
      gradeASqFt: (data['gradeASqFt'] as num?)?.toDouble() ?? 0,
      gradeBSqFt: (data['gradeBSqFt'] as num?)?.toDouble() ?? 0,
      gradeCSqFt: (data['gradeCSqFt'] as num?)?.toDouble() ?? 0,
      rejectSqFt: (data['rejectSqFt'] as num?)?.toDouble() ?? 0,
      defects: defectValues,
      disposition: QcDisposition.fromString(data['disposition'] as String?),
      notes: data['notes'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'qcNumber': qcNumber,
      'factoryId': factoryId,
      'referenceType': referenceType.firestoreValue,
      'referenceId': referenceId,
      'referenceNumber': referenceNumber,
      'referenceLabel': referenceLabel,
      'productLabel': productLabel,
      'marbleVariety': marbleVariety,
      if (sizeThickness != null && sizeThickness!.isNotEmpty)
        'sizeThickness': sizeThickness,
      'inspectionDate': Timestamp.fromDate(inspectionDate),
      'inspectorName': inspectorName,
      'quantityInspected': quantityInspected,
      'gradeASqFt': gradeASqFt,
      'gradeBSqFt': gradeBSqFt,
      'gradeCSqFt': gradeCSqFt,
      'rejectSqFt': rejectSqFt,
      'defects': defects.map((defect) => defect.firestoreValue).toList(),
      'disposition': disposition.firestoreValue,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  QualityCheck toEntity() => QualityCheck(
        id: id,
        qcNumber: qcNumber,
        factoryId: factoryId,
        referenceType: referenceType,
        referenceId: referenceId,
        referenceNumber: referenceNumber,
        referenceLabel: referenceLabel,
        productLabel: productLabel,
        marbleVariety: marbleVariety,
        sizeThickness: sizeThickness,
        inspectionDate: inspectionDate,
        inspectorName: inspectorName,
        quantityInspected: quantityInspected,
        gradeASqFt: gradeASqFt,
        gradeBSqFt: gradeBSqFt,
        gradeCSqFt: gradeCSqFt,
        rejectSqFt: rejectSqFt,
        defects: defects,
        disposition: disposition,
        notes: notes,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory QualityCheckModel.fromEntity(QualityCheck check) => QualityCheckModel(
        id: check.id,
        qcNumber: check.qcNumber,
        factoryId: check.factoryId,
        referenceType: check.referenceType,
        referenceId: check.referenceId,
        referenceNumber: check.referenceNumber,
        referenceLabel: check.referenceLabel,
        productLabel: check.productLabel,
        marbleVariety: check.marbleVariety,
        sizeThickness: check.sizeThickness,
        inspectionDate: check.inspectionDate,
        inspectorName: check.inspectorName,
        quantityInspected: check.quantityInspected,
        gradeASqFt: check.gradeASqFt,
        gradeBSqFt: check.gradeBSqFt,
        gradeCSqFt: check.gradeCSqFt,
        rejectSqFt: check.rejectSqFt,
        defects: check.defects,
        disposition: check.disposition,
        notes: check.notes,
        createdAt: check.createdAt,
        updatedAt: check.updatedAt,
      );
}
