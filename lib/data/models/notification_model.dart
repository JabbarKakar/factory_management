import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/enums/invoice_enums.dart';
import '../../domain/enums/notification_enums.dart';

class NotificationModel {
  const NotificationModel({
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
    this.equipmentId,
    this.deliveryId,
    this.qualityCheckId,
    this.rawMaterialType,
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
  final String? equipmentId;
  final String? deliveryId;
  final String? qualityCheckId;
  final String? rawMaterialType;
  final List<String> readBy;
  final DateTime createdAt;
  final String dedupeKey;

  factory NotificationModel.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return NotificationModel(
      id: id,
      factoryId: data['factoryId'] as String? ?? 'default',
      type: NotificationType.fromString(data['type'] as String?),
      priority: NotificationPriority.fromString(data['priority'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      customerId: data['customerId'] as String?,
      invoiceId: data['invoiceId'] as String?,
      invoiceType: data['invoiceType'] == null
          ? null
          : InvoiceType.fromString(data['invoiceType'] as String?),
      jobWorkId: data['jobWorkId'] as String?,
      salesOrderId: data['salesOrderId'] as String?,
      invoiceNumber: data['invoiceNumber'] as String?,
      amountDue: (data['amountDue'] as num?)?.toDouble(),
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      daysOverdue: data['daysOverdue'] as int?,
      daysUntilDue: data['daysUntilDue'] as int?,
      equipmentId: data['equipmentId'] as String?,
      deliveryId: data['deliveryId'] as String?,
      qualityCheckId: data['qualityCheckId'] as String?,
      rawMaterialType: data['rawMaterialType'] as String?,
      readBy: (data['readBy'] as List?)?.whereType<String>().toList() ?? const [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dedupeKey: data['dedupeKey'] as String? ?? id,
    );
  }

  Map<String, dynamic> toFirestore({bool isCreate = false}) {
    return {
      'factoryId': factoryId,
      'type': type.firestoreValue,
      'priority': priority.firestoreValue,
      'title': title,
      'body': body,
      if (customerId != null) 'customerId': customerId,
      if (invoiceId != null) 'invoiceId': invoiceId,
      if (invoiceType != null) 'invoiceType': invoiceType!.firestoreValue,
      if (jobWorkId != null) 'jobWorkId': jobWorkId,
      if (salesOrderId != null) 'salesOrderId': salesOrderId,
      if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
      if (amountDue != null) 'amountDue': amountDue,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      if (daysOverdue != null) 'daysOverdue': daysOverdue,
      if (daysUntilDue != null) 'daysUntilDue': daysUntilDue,
      if (equipmentId != null) 'equipmentId': equipmentId,
      if (deliveryId != null) 'deliveryId': deliveryId,
      if (qualityCheckId != null) 'qualityCheckId': qualityCheckId,
      if (rawMaterialType != null) 'rawMaterialType': rawMaterialType,
      'readBy': readBy,
      'dedupeKey': dedupeKey,
      if (isCreate) 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  AppNotification toEntity() {
    return AppNotification(
      id: id,
      factoryId: factoryId,
      type: type,
      priority: priority,
      title: title,
      body: body,
      customerId: customerId,
      invoiceId: invoiceId,
      invoiceType: invoiceType,
      jobWorkId: jobWorkId,
      salesOrderId: salesOrderId,
      invoiceNumber: invoiceNumber,
      amountDue: amountDue,
      dueDate: dueDate,
      daysOverdue: daysOverdue,
      daysUntilDue: daysUntilDue,
      equipmentId: equipmentId,
      deliveryId: deliveryId,
      qualityCheckId: qualityCheckId,
      rawMaterialType: rawMaterialType,
      readBy: readBy,
      createdAt: createdAt,
      dedupeKey: dedupeKey,
    );
  }

  factory NotificationModel.fromEntity(AppNotification notification) {
    return NotificationModel(
      id: notification.id,
      factoryId: notification.factoryId,
      type: notification.type,
      priority: notification.priority,
      title: notification.title,
      body: notification.body,
      customerId: notification.customerId,
      invoiceId: notification.invoiceId,
      invoiceType: notification.invoiceType,
      jobWorkId: notification.jobWorkId,
      salesOrderId: notification.salesOrderId,
      invoiceNumber: notification.invoiceNumber,
      amountDue: notification.amountDue,
      dueDate: notification.dueDate,
      daysOverdue: notification.daysOverdue,
      daysUntilDue: notification.daysUntilDue,
      equipmentId: notification.equipmentId,
      deliveryId: notification.deliveryId,
      qualityCheckId: notification.qualityCheckId,
      rawMaterialType: notification.rawMaterialType,
      readBy: notification.readBy,
      createdAt: notification.createdAt,
      dedupeKey: notification.dedupeKey,
    );
  }
}
