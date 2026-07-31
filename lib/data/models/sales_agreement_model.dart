import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sales_agreement.dart';
import '../../domain/enums/sales_agreement_enums.dart';

class SalesAgreementModel {
  const SalesAgreementModel({
    required this.id,
    required this.agreementNumber,
    required this.factoryId,
    required this.customerId,
    required this.customerName,
    required this.createdAt,
    this.summaryStatus = SalesAgreementSummaryStatus.active,
    this.schemaVersion = SalesAgreementSchemaVersion.legacy,
    this.orderCount,
    this.activeOrderCount,
    this.totalAmount,
    this.paidAmount,
    this.balanceDue,
    this.notes,
    this.closedAt,
    this.updatedAt,
  });

  final String id;
  final String agreementNumber;
  final String factoryId;
  final String customerId;
  final String customerName;
  final SalesAgreementSummaryStatus summaryStatus;
  final int schemaVersion;
  final int? orderCount;
  final int? activeOrderCount;
  final double? totalAmount;
  final double? paidAmount;
  final double? balanceDue;
  final String? notes;
  final DateTime? closedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  factory SalesAgreementModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return SalesAgreementModel(
      id: id,
      agreementNumber: data['agreementNumber'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? '',
      summaryStatus: SalesAgreementSummaryStatus.fromString(
        data['summaryStatus'] as String?,
      ),
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ??
          SalesAgreementSchemaVersion.legacy,
      orderCount: (data['orderCount'] as num?)?.toInt(),
      activeOrderCount: (data['activeOrderCount'] as num?)?.toInt(),
      totalAmount: (data['totalAmount'] as num?)?.toDouble(),
      paidAmount: (data['paidAmount'] as num?)?.toDouble(),
      balanceDue: (data['balanceDue'] as num?)?.toDouble(),
      notes: data['notes'] as String?,
      closedAt: (data['closedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'agreementNumber': agreementNumber,
      'factoryId': factoryId,
      'customerId': customerId,
      'customerName': customerName,
      'summaryStatus': summaryStatus.firestoreValue,
      'schemaVersion': schemaVersion,
      if (orderCount != null) 'orderCount': orderCount,
      if (activeOrderCount != null) 'activeOrderCount': activeOrderCount,
      if (totalAmount != null) 'totalAmount': totalAmount,
      if (paidAmount != null) 'paidAmount': paidAmount,
      if (balanceDue != null) 'balanceDue': balanceDue,
      if (notes != null) 'notes': notes,
      if (closedAt != null) 'closedAt': Timestamp.fromDate(closedAt!),
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SalesAgreement toEntity() => SalesAgreement(
        id: id,
        agreementNumber: agreementNumber,
        factoryId: factoryId,
        customerId: customerId,
        customerName: customerName,
        summaryStatus: summaryStatus,
        schemaVersion: schemaVersion,
        orderCount: orderCount,
        activeOrderCount: activeOrderCount,
        totalAmount: totalAmount,
        paidAmount: paidAmount,
        balanceDue: balanceDue,
        notes: notes,
        closedAt: closedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory SalesAgreementModel.fromEntity(SalesAgreement agreement) =>
      SalesAgreementModel(
        id: agreement.id,
        agreementNumber: agreement.agreementNumber,
        factoryId: agreement.factoryId,
        customerId: agreement.customerId,
        customerName: agreement.customerName,
        summaryStatus: agreement.summaryStatus,
        schemaVersion: agreement.schemaVersion,
        orderCount: agreement.orderCount,
        activeOrderCount: agreement.activeOrderCount,
        totalAmount: agreement.totalAmount,
        paidAmount: agreement.paidAmount,
        balanceDue: agreement.balanceDue,
        notes: agreement.notes,
        closedAt: agreement.closedAt,
        createdAt: agreement.createdAt,
        updatedAt: agreement.updatedAt,
      );
}
