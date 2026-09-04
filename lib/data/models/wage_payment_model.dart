import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/wage_payment.dart';
import '../../domain/enums/invoice_enums.dart';

class WagePaymentModel {
  const WagePaymentModel({
    required this.id,
    required this.employeeId,
    required this.factoryId,
    required this.monthKey,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.recordedBy,
    required this.createdAt,
    this.notes,
    this.recordedByName,
  });

  final String id;
  final String employeeId;
  final String factoryId;
  final String monthKey;
  final double amount;
  final DateTime paymentDate;
  final PaymentMethod paymentMethod;
  final String? notes;
  final String recordedBy;
  final String? recordedByName;
  final DateTime createdAt;

  factory WagePaymentModel.fromFirestore(String id, Map<String, dynamic> data) {
    return WagePaymentModel(
      id: id,
      employeeId: data['employeeId'] as String? ?? '',
      factoryId: data['factoryId'] as String? ?? 'default',
      monthKey: data['monthKey'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      paymentDate:
          (data['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      paymentMethod: PaymentMethod.fromString(
        data['paymentMethod'] as String? ?? data['method'] as String?,
      ),
      notes: data['notes'] as String?,
      recordedBy: data['recordedBy'] as String? ?? '',
      recordedByName: data['recordedByName'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'id': id,
      'employeeId': employeeId,
      'factoryId': factoryId,
      'monthKey': monthKey,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod.firestoreValue,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'recordedBy': recordedBy,
      if (recordedByName != null && recordedByName!.isNotEmpty)
        'recordedByName': recordedByName,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  WagePayment toEntity() => WagePayment(
        id: id,
        employeeId: employeeId,
        factoryId: factoryId,
        monthKey: monthKey,
        amount: amount,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        notes: notes,
        recordedBy: recordedBy,
        recordedByName: recordedByName,
        createdAt: createdAt,
      );

  factory WagePaymentModel.fromEntity(WagePayment payment) => WagePaymentModel(
        id: payment.id,
        employeeId: payment.employeeId,
        factoryId: payment.factoryId,
        monthKey: payment.monthKey,
        amount: payment.amount,
        paymentDate: payment.paymentDate,
        paymentMethod: payment.paymentMethod,
        notes: payment.notes,
        recordedBy: payment.recordedBy,
        recordedByName: payment.recordedByName,
        createdAt: payment.createdAt,
      );
}
