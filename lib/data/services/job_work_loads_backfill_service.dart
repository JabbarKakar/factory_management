import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/job_work_invoice_repository.dart';
import '../repositories/job_work_load_repository.dart';
import '../repositories/job_work_repository.dart';

/// Sprint 7 — factory-wide default-Load migration + orphan `loadId` stamp.
///
/// Safe attribution: empty Load → create default; single Load → stamp orphans;
/// multi-Load orphans are reported for manual review (not auto-stamped).
class JobWorkLoadsBackfillService {
  JobWorkLoadsBackfillService({
    required JobWorkRepository jobWorkRepository,
    required JobWorkLoadRepository loadRepository,
    required JobWorkInvoiceRepository invoiceRepository,
    FirebaseFirestore? firestore,
    SharedPreferences? preferences,
  })  : _jobWorkRepository = jobWorkRepository,
        _loadRepository = loadRepository,
        _invoiceRepository = invoiceRepository,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _preferences = preferences;

  static const _prefKeyPrefix = 'job_work_loads_backfill_v1_';

  final JobWorkRepository _jobWorkRepository;
  final JobWorkLoadRepository _loadRepository;
  final JobWorkInvoiceRepository _invoiceRepository;
  final FirebaseFirestore _firestore;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
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
    if (report.isComplete) {
      await prefs.setBool(key, true);
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
      } catch (_) {
        // Continue remaining orders; incomplete report keeps retry enabled.
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
