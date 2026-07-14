import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_strings.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/enums/notification_enums.dart';
import '../repositories/job_work_invoice_repository.dart';
import '../repositories/job_work_load_repository.dart';
import '../repositories/job_work_repository.dart';
import '../repositories/notification_repository.dart';

/// Sprint 7 — factory-wide default-Load migration + orphan `loadId` stamp.
///
/// Safe attribution: empty Load → create default; single Load → stamp orphans;
/// multi-Load orphans are reported for manual review (not auto-stamped).
class JobWorkLoadsBackfillService {
  JobWorkLoadsBackfillService({
    required JobWorkRepository jobWorkRepository,
    required JobWorkLoadRepository loadRepository,
    required JobWorkInvoiceRepository invoiceRepository,
    required NotificationRepository notificationRepository,
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
  })  : _jobWorkRepository = jobWorkRepository,
        _loadRepository = loadRepository,
        _invoiceRepository = invoiceRepository,
        _notificationRepository = notificationRepository,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _preferences = preferences;

  static const _prefKeyPrefix = 'job_work_loads_backfill_v1_';
  static const _orphanPrefSuffix = '_multi_load_orphans';

  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;
  final JobWorkInvoiceRepository _invoiceRepository;
  final NotificationRepository _notificationRepository;
  final FirebaseFirestore _firestore;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  static String _orphanPrefsKey(String factoryId) =>
      '$_prefKeyPrefix$factoryId$_orphanPrefSuffix';

  /// Last multi-Load orphan JW ids persisted for [factoryId] (manual review).
  Future<List<String>> multiLoadOrphanJobWorkIds(String factoryId) async {
    final prefs = await _prefs;
    return prefs.getStringList(_orphanPrefsKey(factoryId)) ?? const [];
  }

  /// Runs once per factory while migration is incomplete; retries until
  /// [JobWorkLoadsBackfillReport.isComplete] is true.
  Future<JobWorkLoadsBackfillReport> runIfNeeded(String factoryId) async {
    final prefs = await _prefs;
    final key = '$_prefKeyPrefix$factoryId';
    if (prefs.getBool(key) == true) {
      return JobWorkLoadsBackfillReport.empty;
    }

    final report = await run(factoryId);
    debugPrint('JobWorkLoadsBackfill: $report');

    await prefs.setStringList(
      _orphanPrefsKey(factoryId),
      report.multiLoadOrphanJobWorkIds,
    );

    if (!report.isComplete) {
      await _notifyMultiLoadOrphans(factoryId, report);
    }

    if (report.isComplete) {
      await prefs.setBool(key, true);
      await prefs.remove(_orphanPrefsKey(factoryId));
    }
    return report;
  }

  Future<JobWorkLoadsBackfillReport> run(String factoryId) async {
    final orders = await _jobWorkRepository.getJobWorkOrders(factoryId);
    var ensuredLoads = 0;
    var markedAuthoritative = 0;
    final multiLoadOrphanJobWorkIds = <String>[];

    for (final order in orders) {
      try {
        final before = await _loadRepository.fetchLoadsForJobWork(
          factoryId: factoryId,
          jobWorkId: order.id,
        );
        await _loadRepository.ensureDefaultLoad(order.id);
        final after = await _loadRepository.fetchLoadsForJobWork(
          factoryId: factoryId,
          jobWorkId: order.id,
        );
        if (before.isEmpty && after.isNotEmpty) {
          ensuredLoads++;
        }
        final refreshed =
            await _jobWorkRepository.getJobWorkOrder(order.id) ?? order;
        if (refreshed.isLoadsAuthoritative) {
          markedAuthoritative++;
        }

        if (after.length > 1) {
          final orphanInvoices = await _countOrphanInvoices(
            factoryId: factoryId,
            jobWorkId: order.id,
          );
          final orphanCollections = await _countOrphanCollections(
            factoryId: factoryId,
            jobWorkId: order.id,
          );
          if (orphanInvoices > 0 || orphanCollections > 0) {
            multiLoadOrphanJobWorkIds.add(order.id);
          }
        }
      } catch (error, stack) {
        debugPrint(
          'JobWorkLoadsBackfill: failed for ${order.id}: $error\n$stack',
        );
      }
    }

    final remainingNullInvoiceLoadIds =
        await _countFactoryOrphanInvoices(factoryId);
    final remainingNullCollectionLoadIds =
        await _countFactoryOrphanCollections(factoryId);
    final remainingLegacyContainers =
        await _countLegacyContainers(factoryId);

    return JobWorkLoadsBackfillReport(
      ordersProcessed: orders.length,
      defaultLoadsEnsured: ensuredLoads,
      containersMarkedAuthoritative: markedAuthoritative,
      remainingNullInvoiceLoadIds: remainingNullInvoiceLoadIds,
      remainingNullCollectionLoadIds: remainingNullCollectionLoadIds,
      remainingLegacyContainers: remainingLegacyContainers,
      multiLoadOrphanJobWorkIds: List.unmodifiable(multiLoadOrphanJobWorkIds),
    );
  }

  Future<void> _notifyMultiLoadOrphans(
    String factoryId,
    JobWorkLoadsBackfillReport report,
  ) async {
    if (report.multiLoadOrphanJobWorkIds.isEmpty) return;

    final count = report.multiLoadOrphanJobWorkIds.length;
    await _notificationRepository.createNotification(
      AppNotification(
        id: '',
        factoryId: factoryId,
        type: NotificationType.jobWorkMigrationReview,
        priority: NotificationPriority.high,
        title: AppStrings.jobWorkMigrationReviewTitle,
        body: AppStrings.jobWorkMigrationReviewBody(count),
        createdAt: DateTime.now(),
        dedupeKey: 'jw_migration_review_summary_$factoryId',
        jobWorkId: report.multiLoadOrphanJobWorkIds.first,
      ),
    );

    for (final jobWorkId in report.multiLoadOrphanJobWorkIds.take(20)) {
      await _notificationRepository.createNotification(
        AppNotification(
          id: '',
          factoryId: factoryId,
          type: NotificationType.jobWorkMigrationReview,
          priority: NotificationPriority.medium,
          title: AppStrings.jobWorkMigrationReviewTitle,
          body: AppStrings.jobWorkMigrationReviewItemBody(jobWorkId),
          createdAt: DateTime.now(),
          dedupeKey: 'jw_migration_review_${factoryId}_$jobWorkId',
          jobWorkId: jobWorkId,
        ),
      );
    }
  }

  Future<int> _countOrphanInvoices({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final invoices = await _invoiceRepository.getInvoicesByJobWorkId(
      factoryId: factoryId,
      jobWorkId: jobWorkId,
    );
    return invoices
        .where(
          (invoice) =>
              invoice.loadId == null || invoice.loadId!.trim().isEmpty,
        )
        .length;
  }

  Future<int> _countOrphanCollections({
    required String factoryId,
    required String jobWorkId,
  }) async {
    final snap = await _firestore
        .collection('jobWorkCollections')
        .where('factoryId', isEqualTo: factoryId)
        .where('jobWorkOrderId', isEqualTo: jobWorkId)
        .get();
    return snap.docs.where((doc) {
      final loadId = doc.data()['loadId'] as String?;
      return loadId == null || loadId.trim().isEmpty;
    }).length;
  }

  Future<int> _countFactoryOrphanInvoices(String factoryId) async {
    final snap = await _firestore
        .collection('jobWorkInvoices')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    return snap.docs.where((doc) {
      final loadId = doc.data()['loadId'] as String?;
      return loadId == null || loadId.trim().isEmpty;
    }).length;
  }

  Future<int> _countFactoryOrphanCollections(String factoryId) async {
    final snap = await _firestore
        .collection('jobWorkCollections')
        .where('factoryId', isEqualTo: factoryId)
        .get();
    return snap.docs.where((doc) {
      final loadId = doc.data()['loadId'] as String?;
      return loadId == null || loadId.trim().isEmpty;
    }).length;
  }

  Future<int> _countLegacyContainers(String factoryId) async {
    final orders = await _jobWorkRepository.getJobWorkOrders(factoryId);
    return orders.where((order) => !order.isLoadsAuthoritative).length;
  }
}

class JobWorkLoadsBackfillReport {
  const JobWorkLoadsBackfillReport({
    required this.ordersProcessed,
    required this.defaultLoadsEnsured,
    required this.containersMarkedAuthoritative,
    required this.remainingNullInvoiceLoadIds,
    required this.remainingNullCollectionLoadIds,
    required this.remainingLegacyContainers,
    required this.multiLoadOrphanJobWorkIds,
  });

  static const empty = JobWorkLoadsBackfillReport(
    ordersProcessed: 0,
    defaultLoadsEnsured: 0,
    containersMarkedAuthoritative: 0,
    remainingNullInvoiceLoadIds: 0,
    remainingNullCollectionLoadIds: 0,
    remainingLegacyContainers: 0,
    multiLoadOrphanJobWorkIds: [],
  );

  final int ordersProcessed;
  final int defaultLoadsEnsured;
  final int containersMarkedAuthoritative;
  final int remainingNullInvoiceLoadIds;
  final int remainingNullCollectionLoadIds;
  final int remainingLegacyContainers;
  final List<String> multiLoadOrphanJobWorkIds;

  /// Complete when every container is authoritative and no null loadIds remain.
  bool get isComplete =>
      remainingLegacyContainers == 0 &&
      remainingNullInvoiceLoadIds == 0 &&
      remainingNullCollectionLoadIds == 0 &&
      multiLoadOrphanJobWorkIds.isEmpty;

  @override
  String toString() {
    return 'JobWorkLoadsBackfillReport('
        'orders=$ordersProcessed, '
        'ensured=$defaultLoadsEnsured, '
        'authoritative=$containersMarkedAuthoritative, '
        'nullInvoiceLoadIds=$remainingNullInvoiceLoadIds, '
        'nullCollectionLoadIds=$remainingNullCollectionLoadIds, '
        'legacyContainers=$remainingLegacyContainers, '
        'multiLoadOrphans=${multiLoadOrphanJobWorkIds.length}'
        ')';
  }
}
