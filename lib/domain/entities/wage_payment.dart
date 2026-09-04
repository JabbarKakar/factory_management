import 'package:equatable/equatable.dart';

import '../enums/invoice_enums.dart';

class WagePayment extends Equatable {
  const WagePayment({
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

  WagePayment copyWith({
    String? id,
    String? employeeId,
    String? factoryId,
    String? monthKey,
    double? amount,
    DateTime? paymentDate,
    PaymentMethod? paymentMethod,
    String? notes,
    String? recordedBy,
    String? recordedByName,
    DateTime? createdAt,
  }) {
    return WagePayment(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      factoryId: factoryId ?? this.factoryId,
      monthKey: monthKey ?? this.monthKey,
      amount: amount ?? this.amount,
      paymentDate: paymentDate ?? this.paymentDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      recordedBy: recordedBy ?? this.recordedBy,
      recordedByName: recordedByName ?? this.recordedByName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        employeeId,
        factoryId,
        monthKey,
        amount,
        paymentDate,
        paymentMethod,
        notes,
        recordedBy,
        recordedByName,
        createdAt,
      ];
}
