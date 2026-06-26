import 'package:equatable/equatable.dart';

import '../enums/invoice_enums.dart';
import '../enums/notification_enums.dart';

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.factoryId,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.dedupeKey,
    this.customerId,
    this.invoiceId,
    this.invoiceType,
    this.jobWorkId,
    this.salesOrderId,
    this.invoiceNumber,
    this.amountDue,
    this.dueDate,
    this.daysOverdue,
    this.daysUntilDue,
    this.readBy = const [],
  });

  final String id;
  final String factoryId;
  final NotificationType type;
  final NotificationPriority priority;
  final String title;
  final String body;
  final String? customerId;
  final String? invoiceId;
  final InvoiceType? invoiceType;
  final String? jobWorkId;
  final String? salesOrderId;
  final String? invoiceNumber;
  final double? amountDue;
  final DateTime? dueDate;
  final int? daysOverdue;
  final int? daysUntilDue;
  final List<String> readBy;
  final DateTime createdAt;
  final String dedupeKey;

  bool isReadBy(String userId) => readBy.contains(userId);

  bool get isSalesInvoice =>
      invoiceType == InvoiceType.sales ||
      (invoiceType == null && salesOrderId != null);

  AppNotification copyWith({
    String? id,
    String? factoryId,
    NotificationType? type,
    NotificationPriority? priority,
    String? title,
    String? body,
    String? customerId,
    String? invoiceId,
    InvoiceType? invoiceType,
    String? jobWorkId,
    String? salesOrderId,
    String? invoiceNumber,
    double? amountDue,
    DateTime? dueDate,
    int? daysOverdue,
    int? daysUntilDue,
    List<String>? readBy,
    DateTime? createdAt,
    String? dedupeKey,
  }) {
    return AppNotification(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      title: title ?? this.title,
      body: body ?? this.body,
      customerId: customerId ?? this.customerId,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceType: invoiceType ?? this.invoiceType,
      jobWorkId: jobWorkId ?? this.jobWorkId,
      salesOrderId: salesOrderId ?? this.salesOrderId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      amountDue: amountDue ?? this.amountDue,
      dueDate: dueDate ?? this.dueDate,
      daysOverdue: daysOverdue ?? this.daysOverdue,
      daysUntilDue: daysUntilDue ?? this.daysUntilDue,
      readBy: readBy ?? this.readBy,
      createdAt: createdAt ?? this.createdAt,
      dedupeKey: dedupeKey ?? this.dedupeKey,
    );
  }

  @override
  List<Object?> get props => [
        id,
        factoryId,
        type,
        priority,
        title,
        body,
        customerId,
        invoiceId,
        invoiceType,
        jobWorkId,
        salesOrderId,
        invoiceNumber,
        amountDue,
        dueDate,
        daysOverdue,
        daysUntilDue,
        readBy,
        createdAt,
        dedupeKey,
      ];
}

class PaymentDueSummary extends Equatable {
  const PaymentDueSummary({
    required this.dueThisWeekCount,
    required this.dueThisWeekAmount,
    required this.overdueCount,
    required this.overdueAmount,
  });

  static const empty = PaymentDueSummary(
    dueThisWeekCount: 0,
    dueThisWeekAmount: 0,
    overdueCount: 0,
    overdueAmount: 0,
  );

  final int dueThisWeekCount;
  final double dueThisWeekAmount;
  final int overdueCount;
  final double overdueAmount;

  bool get hasAlerts => dueThisWeekCount > 0 || overdueCount > 0;

  @override
  List<Object?> get props => [
        dueThisWeekCount,
        dueThisWeekAmount,
        overdueCount,
        overdueAmount,
      ];
}
