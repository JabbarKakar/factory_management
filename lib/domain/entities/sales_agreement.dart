import 'package:equatable/equatable.dart';

import '../enums/sales_agreement_enums.dart';

/// Parent Sales Agreement container (Job Work equivalent).
class SalesAgreement extends Equatable {
  const SalesAgreement({
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

  bool get isOrdersAuthoritative =>
      schemaVersion >= SalesAgreementSchemaVersion.ordersAuthoritative;

  SalesAgreement copyWith({
    String? id,
    String? agreementNumber,
    String? factoryId,
    String? customerId,
    String? customerName,
    SalesAgreementSummaryStatus? summaryStatus,
    int? schemaVersion,
    int? orderCount,
    int? activeOrderCount,
    double? totalAmount,
    double? paidAmount,
    double? balanceDue,
    String? notes,
    DateTime? closedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SalesAgreement(
      id: id ?? this.id,
      agreementNumber: agreementNumber ?? this.agreementNumber,
      factoryId: factoryId ?? this.factoryId,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      summaryStatus: summaryStatus ?? this.summaryStatus,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      orderCount: orderCount ?? this.orderCount,
      activeOrderCount: activeOrderCount ?? this.activeOrderCount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      balanceDue: balanceDue ?? this.balanceDue,
      notes: notes ?? this.notes,
      closedAt: closedAt ?? this.closedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        agreementNumber,
        factoryId,
        customerId,
        customerName,
        summaryStatus,
        schemaVersion,
        orderCount,
        activeOrderCount,
        totalAmount,
        paidAmount,
        balanceDue,
        notes,
        closedAt,
        createdAt,
        updatedAt,
      ];
}
