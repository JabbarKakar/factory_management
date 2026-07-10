import 'package:intl/intl.dart';

import '../../core/utils/formatters.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/finished_good.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/entities/raw_material.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/notification_enums.dart';
import '../../domain/enums/quality_enums.dart';
import '../repositories/delivery_repository.dart';
import '../repositories/equipment_repository.dart';
import '../repositories/finished_goods_repository.dart';
import '../repositories/job_work_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/raw_material_repository.dart';

class OperationalAlertScannerService {
  OperationalAlertScannerService({
    required RawMaterialRepository rawMaterialRepository,
    required FinishedGoodsRepository finishedGoodsRepository,
    required EquipmentRepository equipmentRepository,
    required DeliveryRepository deliveryRepository,
    required JobWorkRepository jobWorkRepository,
    required NotificationRepository notificationRepository,
  })  : _rawMaterialRepository = rawMaterialRepository,
        _finishedGoodsRepository = finishedGoodsRepository,
        _equipmentRepository = equipmentRepository,
        _deliveryRepository = deliveryRepository,
        _jobWorkRepository = jobWorkRepository,
        _notificationRepository = notificationRepository;

  final RawMaterialRepository _rawMaterialRepository;
  final FinishedGoodsRepository _finishedGoodsRepository;
  final EquipmentRepository _equipmentRepository;
  final DeliveryRepository _deliveryRepository;
  final JobWorkRepository _jobWorkRepository;
  final NotificationRepository _notificationRepository;

  Future<int> scan(String factoryId) async {
    final materials =
        await _rawMaterialRepository.watchMaterials(factoryId).first;
    final finishedGoods =
        await _finishedGoodsRepository.watchFinishedGoods(factoryId).first;
    final equipment =
        await _equipmentRepository.watchEquipment(factoryId).first;
    final deliveries =
        await _deliveryRepository.watchDeliveries(factoryId).first;
    final jobWorkOrders =
        await _jobWorkRepository.watchJobWorkOrders(factoryId).first;

    var created = 0;
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final scanDate = DateFormat('yyyy-MM-dd').format(todayDay);

    for (final material in materials) {
      created += await _createIfNew(
        _lowStockNotification(material, scanDate),
      );
    }

    for (final item in finishedGoods) {
      created += await _createIfNew(
        _lowFinishedGoodsNotification(item, scanDate),
      );
    }

    for (final item in equipment) {
      if (item.isMaintenanceOverdue(today: todayDay)) {
        final dueText = item.nextMaintenanceDueDate == null
            ? 'Schedule service soon.'
            : 'Was due ${DateFormat.yMMMd().format(item.nextMaintenanceDueDate!)}';
        created += await _createIfNew(
          _equipmentNotification(
            item,
            type: NotificationType.equipmentMaintenanceOverdue,
            priority: NotificationPriority.critical,
            title: 'Maintenance overdue — ${item.name}',
            body: dueText,
            dedupeKey: 'eq_overdue_${item.id}_$scanDate',
          ),
        );
      } else if (item.isMaintenanceDueSoon(today: todayDay)) {
        created += await _createIfNew(
          _equipmentNotification(
            item,
            type: NotificationType.equipmentMaintenanceDueSoon,
            priority: NotificationPriority.medium,
            title: 'Maintenance due soon — ${item.name}',
            body: item.nextMaintenanceDueDate == null
                ? 'Schedule preventive maintenance.'
                : 'Due ${DateFormat.yMMMd().format(item.nextMaintenanceDueDate!)}',
            dedupeKey: 'eq_due_${item.id}_$scanDate',
          ),
        );
      }
    }

    for (final delivery in deliveries) {
      created += await _createIfNew(
        _pendingDeliveryNotification(delivery, todayDay, scanDate),
      );
    }

    for (final order in jobWorkOrders) {
      if (order.status == JobWorkStatus.ready) {
        created += await _createIfNew(_jobWorkReadyNotification(order));
      }
      if (order.status.isPendingPickup) {
        created += await _createIfNew(
          _jobWorkStalePickupNotification(order, todayDay, scanDate),
        );
      }
    }

    return created;
  }

  Future<void> notifyQcReject(QualityCheck check) async {
    if (check.disposition != QcDisposition.reject) return;

    await _createIfNew(
      AppNotification(
        id: '',
        factoryId: check.factoryId,
        type: NotificationType.qcReject,
        priority: NotificationPriority.high,
        title: 'QC rejection — ${check.qcNumber}',
        body:
            '${check.referenceType.label} ${check.referenceNumber}: ${check.passRatePercent.toStringAsFixed(1)}% pass rate',
        qualityCheckId: check.id,
        jobWorkId: check.referenceType == QcReferenceType.jobWork
            ? check.referenceId
            : null,
        createdAt: DateTime.now(),
        dedupeKey: 'qc_reject_${check.id}',
      ),
    );
  }

  Future<void> notifyJobWorkReady(JobWorkOrder order) async {
    if (order.status != JobWorkStatus.ready) return;

    await _createIfNew(_jobWorkReadyNotification(order));
  }

  Future<int> _createIfNew(AppNotification? notification) async {
    if (notification == null) return 0;

    final exists = await _notificationRepository.existsByDedupeKey(
      notification.factoryId,
      notification.dedupeKey,
    );
    if (exists) return 0;

    await _notificationRepository.createNotification(notification);
    return 1;
  }

  AppNotification? _lowStockNotification(RawMaterial material, String scanDate) {
    if (!material.isLowStock) return null;

    return AppNotification(
      id: '',
      factoryId: material.factoryId,
      type: NotificationType.lowRawMaterialStock,
      priority: NotificationPriority.high,
      title: 'Low stock — ${material.materialType.label}',
      body:
          '${Formatters.stockQuantity(material.currentStock, material.unit.label)} on hand (reorder at ${Formatters.stockQuantity(material.reorderLevel, material.unit.label)})',
      rawMaterialType: material.materialType.firestoreValue,
      createdAt: DateTime.now(),
      dedupeKey: 'low_stock_${material.id}_$scanDate',
    );
  }

  AppNotification? _lowFinishedGoodsNotification(
    FinishedGood item,
    String scanDate,
  ) {
    if (!item.isLowStock) return null;

    return AppNotification(
      id: '',
      factoryId: item.factoryId,
      type: NotificationType.lowFinishedGoodsStock,
      priority: NotificationPriority.high,
      title: 'Low finished goods — ${item.productType.label}',
      body:
          '${item.displaySubtitle}: ${Formatters.stockQuantity(item.currentQuantity, 'sq. ft')} on hand (reorder at ${Formatters.stockQuantity(item.reorderLevel, 'sq. ft')})',
      finishedGoodId: item.id,
      createdAt: DateTime.now(),
      dedupeKey: 'low_fg_${item.id}_$scanDate',
    );
  }

  AppNotification _equipmentNotification(
    Equipment item, {
    required NotificationType type,
    required NotificationPriority priority,
    required String title,
    required String body,
    required String dedupeKey,
  }) {
    return AppNotification(
      id: '',
      factoryId: item.factoryId,
      type: type,
      priority: priority,
      title: title,
      body: body,
      equipmentId: item.id,
      createdAt: DateTime.now(),
      dedupeKey: dedupeKey,
    );
  }

  AppNotification? _pendingDeliveryNotification(
    Delivery delivery,
    DateTime today,
    String scanDate,
  ) {
    if (!delivery.status.isActive) return null;

    final scheduledDay = DateTime(
      delivery.scheduledDate.year,
      delivery.scheduledDate.month,
      delivery.scheduledDate.day,
    );
    if (scheduledDay.isAfter(today)) return null;

    final isOverdue = scheduledDay.isBefore(today);
    final daysLate = today.difference(scheduledDay).inDays;

    return AppNotification(
      id: '',
      factoryId: delivery.factoryId,
      type: NotificationType.pendingDelivery,
      priority:
          isOverdue ? NotificationPriority.high : NotificationPriority.medium,
      title: isOverdue
          ? 'Overdue delivery — ${delivery.customerName}'
          : 'Delivery due today — ${delivery.customerName}',
      body: isOverdue
          ? '${delivery.deliveryNumber} was scheduled ${daysLate == 0 ? 'today' : '$daysLate day${daysLate == 1 ? '' : 's'} ago'}'
          : '${delivery.deliveryNumber} is scheduled for delivery today',
      customerId: delivery.customerId,
      salesOrderId: delivery.salesOrderId,
      deliveryId: delivery.id,
      daysOverdue: isOverdue ? daysLate : null,
      createdAt: DateTime.now(),
      dedupeKey: 'delivery_${delivery.id}_$scanDate',
    );
  }

  AppNotification _jobWorkReadyNotification(JobWorkOrder order) {
    return AppNotification(
      id: '',
      factoryId: order.factoryId,
      type: NotificationType.jobWorkReadyForPickup,
      priority: NotificationPriority.medium,
      title: 'Ready for pickup — ${order.customerName}',
      body:
          '${order.jobWorkNumber} is ready. Notify the customer to collect material.',
      customerId: order.customerId,
      jobWorkId: order.id,
      createdAt: DateTime.now(),
      dedupeKey: 'jw_ready_${order.id}',
    );
  }

  AppNotification? _jobWorkStalePickupNotification(
    JobWorkOrder order,
    DateTime today,
    String scanDate,
  ) {
    final reference = order.updatedAt ?? order.createdAt;
    final referenceDay =
        DateTime(reference.year, reference.month, reference.day);
    final daysWaiting = today.difference(referenceDay).inDays;
    if (daysWaiting < 7) return null;

    return AppNotification(
      id: '',
      factoryId: order.factoryId,
      type: NotificationType.jobWorkNotCollected,
      priority: NotificationPriority.medium,
      title: 'Material not collected — ${order.customerName}',
      body:
          '${order.jobWorkNumber} has been waiting $daysWaiting days for customer pickup',
      customerId: order.customerId,
      jobWorkId: order.id,
      daysOverdue: daysWaiting,
      createdAt: DateTime.now(),
      dedupeKey: 'jw_stale_${order.id}_$scanDate',
    );
  }
}
