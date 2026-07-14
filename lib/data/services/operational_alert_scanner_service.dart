import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/entities/delivery.dart';
import '../../domain/entities/equipment.dart';
import '../../domain/entities/finished_good.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/quality_check.dart';
import '../../domain/entities/raw_material.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/notification_enums.dart';
import '../../domain/enums/quality_enums.dart';
import '../repositories/delivery_repository.dart';
import '../repositories/equipment_repository.dart';
import '../repositories/finished_goods_repository.dart';
import '../repositories/job_work_collection_repository.dart';
import '../repositories/job_work_load_repository.dart';
import '../repositories/job_work_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/raw_material_repository.dart';
import 'job_work_collection_quantity_helper.dart';

class OperationalAlertScannerService {
  OperationalAlertScannerService({
    required RawMaterialRepository rawMaterialRepository,
    required FinishedGoodsRepository finishedGoodsRepository,
    required EquipmentRepository equipmentRepository,
    required DeliveryRepository deliveryRepository,
    required JobWorkRepository jobWorkRepository,
    required JobWorkLoadRepository jobWorkLoadRepository,
    required JobWorkCollectionRepository jobWorkCollectionRepository,
    required NotificationRepository notificationRepository,
  })  : _rawMaterialRepository = rawMaterialRepository,
        _finishedGoodsRepository = finishedGoodsRepository,
        _equipmentRepository = equipmentRepository,
        _deliveryRepository = deliveryRepository,
        _jobWorkRepository = jobWorkRepository,
        _jobWorkLoadRepository = jobWorkLoadRepository,
        _jobWorkCollectionRepository = jobWorkCollectionRepository,
        _notificationRepository = notificationRepository;

  final RawMaterialRepository _rawMaterialRepository;
  final FinishedGoodsRepository _finishedGoodsRepository;
  final EquipmentRepository _equipmentRepository;
  final DeliveryRepository _deliveryRepository;
  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _jobWorkLoadRepository;
  final JobWorkCollectionRepository _jobWorkCollectionRepository;
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
    final jobWorkLoads =
        await _jobWorkLoadRepository.watchLoads(factoryId).first;
    final jobWorkCollections =
        await _jobWorkCollectionRepository.watchCollections(factoryId).first;

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
      final orderLoads =
          jobWorkLoads.where((load) => load.jobWorkId == order.id).toList();
      final collections = JobWorkCollectionQuantityHelper.collectionsForOrder(
        order.id,
        jobWorkCollections,
      );
      if (orderLoads.isEmpty &&
          order.status == JobWorkStatus.ready &&
          JobWorkCollectionQuantityHelper.isPendingPickup(
            order,
            collections,
          )) {
        created += await _createIfNew(_jobWorkReadyNotification(order));
      }
      if (orderLoads.isEmpty &&
          JobWorkCollectionQuantityHelper.isPickupOverdue(
            order,
            collections,
            reference: todayDay,
          )) {
        created += await _createIfNew(
          _jobWorkStalePickupNotification(
            order,
            collections,
            todayDay,
            scanDate,
          ),
        );
      }
    }

    final ordersById = {for (final order in jobWorkOrders) order.id: order};
    for (final load in jobWorkLoads) {
      if (load.isVirtual) continue;
      final order = ordersById[load.jobWorkId];
      if (order == null) continue;

      if (load.status == JobWorkStatus.ready &&
          JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
            load,
            jobWorkCollections,
          )) {
        created += await _createIfNew(
          _jobWorkLoadReadyNotification(order, load),
        );
      }

      if (JobWorkCollectionQuantityHelper.isPickupOverdueForLoad(
        load,
        jobWorkCollections,
        reference: todayDay,
      )) {
        created += await _createIfNew(
          _jobWorkLoadStalePickupNotification(
            order,
            load,
            jobWorkCollections,
            todayDay,
            scanDate,
          ),
        );
      }
    }

    return created;
  }

  Future<void> notifyQcReject(QualityCheck check) async {
    if (check.disposition != QcDisposition.reject) return;

    String? jobWorkId;
    String? loadId;
    if (check.referenceType == QcReferenceType.jobWork) {
      jobWorkId = check.referenceId;
    } else if (check.referenceType == QcReferenceType.jobWorkLoad) {
      loadId = check.referenceId;
      final load = await _jobWorkLoadRepository.getLoad(check.referenceId);
      jobWorkId = load?.jobWorkId;
    }

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
        jobWorkId: jobWorkId,
        loadId: loadId,
        createdAt: DateTime.now(),
        dedupeKey: 'qc_reject_${check.id}',
      ),
    );
  }

  Future<void> notifyJobWorkReady(
    JobWorkOrder order, {
    JobWorkLoad? load,
  }) async {
    if (load != null) {
      if (load.status != JobWorkStatus.ready) return;
      final collections =
          await _jobWorkCollectionRepository.fetchCollectionsForJobWork(
        factoryId: order.factoryId,
        jobWorkOrderId: order.id,
      );
      if (!JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
        load,
        collections,
      )) {
        return;
      }
      await _createIfNew(_jobWorkLoadReadyNotification(order, load));
      return;
    }

    final collections =
        await _jobWorkCollectionRepository.fetchCollectionsForJobWork(
      factoryId: order.factoryId,
      jobWorkOrderId: order.id,
    );
    final loads = await _jobWorkLoadRepository.fetchLoadsForJobWork(
      factoryId: order.factoryId,
      jobWorkId: order.id,
    );
    final persisted =
        loads.where((item) => !item.isVirtual).toList(growable: false);

    // When Loads exist, always notify per Load — never a JW-only ready alert.
    if (persisted.isNotEmpty) {
      for (final item in persisted) {
        if (item.status != JobWorkStatus.ready) continue;
        if (!JobWorkCollectionQuantityHelper.canOpenCollectMaterialForLoad(
          item,
          collections,
        )) {
          continue;
        }
        await _createIfNew(_jobWorkLoadReadyNotification(order, item));
      }
      return;
    }

    if (order.status != JobWorkStatus.ready) return;
    if (!JobWorkCollectionQuantityHelper.isPendingPickup(
      order,
      collections,
    )) {
      return;
    }

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
      title: '${AppStrings.readyForPickupAlert} — ${order.customerName}',
      body:
          '${order.jobWorkNumber} ${AppStrings.readyForPickupAlertBody}',
      customerId: order.customerId,
      jobWorkId: order.id,
      createdAt: DateTime.now(),
      dedupeKey: 'jw_ready_${order.id}',
    );
  }

  AppNotification _jobWorkLoadReadyNotification(
    JobWorkOrder order,
    JobWorkLoad load,
  ) {
    final loadLabel = load.loadNumber.isEmpty
        ? 'Load #${load.loadSequence}'
        : load.loadNumber;
    return AppNotification(
      id: '',
      factoryId: order.factoryId,
      type: NotificationType.jobWorkReadyForPickup,
      priority: NotificationPriority.medium,
      title: '${AppStrings.readyForPickupAlert} — ${order.customerName}',
      body:
          '${order.jobWorkNumber} · $loadLabel ${AppStrings.readyForPickupAlertBody}',
      customerId: order.customerId,
      jobWorkId: order.id,
      loadId: load.id,
      createdAt: DateTime.now(),
      dedupeKey: 'jw_load_ready_${load.id}',
    );
  }

  AppNotification? _jobWorkStalePickupNotification(
    JobWorkOrder order,
    List<JobWorkCollection> collections,
    DateTime today,
    String scanDate,
  ) {
    final daysWaiting = JobWorkCollectionQuantityHelper.pickupDaysWaiting(
      order,
      collections,
      reference: today,
    );
    if (daysWaiting < JobWorkCollectionQuantityHelper.stalePickupAfterDays) {
      return null;
    }

    final totals = JobWorkCollectionQuantityHelper.aggregateTotals(
      order: order,
      collections: collections,
      loads: const [],
    );

    return AppNotification(
      id: '',
      factoryId: order.factoryId,
      type: NotificationType.jobWorkNotCollected,
      priority: NotificationPriority.medium,
      title: '${AppStrings.stalePickupAlert} — ${order.customerName}',
      body:
          '${order.jobWorkNumber} has ${totals.remainingPieces} pcs remaining, '
          'waiting $daysWaiting days for pickup',
      customerId: order.customerId,
      jobWorkId: order.id,
      daysOverdue: daysWaiting,
      createdAt: DateTime.now(),
      dedupeKey: 'jw_stale_${order.id}_$scanDate',
    );
  }

  AppNotification? _jobWorkLoadStalePickupNotification(
    JobWorkOrder order,
    JobWorkLoad load,
    List<JobWorkCollection> collections,
    DateTime today,
    String scanDate,
  ) {
    final daysWaiting = JobWorkCollectionQuantityHelper.pickupDaysWaitingForLoad(
      load,
      collections,
      reference: today,
    );
    if (daysWaiting < JobWorkCollectionQuantityHelper.stalePickupAfterDays) {
      return null;
    }

    final totals = JobWorkCollectionQuantityHelper.loadTotals(
      load,
      collections,
    );
    final loadLabel = load.loadNumber.isEmpty
        ? 'Load #${load.loadSequence}'
        : load.loadNumber;

    return AppNotification(
      id: '',
      factoryId: order.factoryId,
      type: NotificationType.jobWorkNotCollected,
      priority: NotificationPriority.medium,
      title: '${AppStrings.stalePickupAlert} — ${order.customerName}',
      body:
          '${order.jobWorkNumber} · $loadLabel has ${totals.remainingPieces} pcs remaining, '
          'waiting $daysWaiting days for pickup',
      customerId: order.customerId,
      jobWorkId: order.id,
      loadId: load.id,
      daysOverdue: daysWaiting,
      createdAt: DateTime.now(),
      dedupeKey: 'jw_load_stale_${load.id}_$scanDate',
    );
  }
}
