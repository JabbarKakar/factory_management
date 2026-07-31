import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/sales_order.dart';
import '../repositories/sales_agreement_repository.dart';
import '../repositories/sales_order_repository.dart';

/// Sprint 1 — 1:1 legacy Sales Order → Sales Agreement backfill.
///
/// For each order missing `agreementId`, creates a parent Agreement and stamps
/// the order + its invoices. Idempotent per order and per factory completion flag.
class SalesAgreementBackfillService {
  SalesAgreementBackfillService({
    required SalesOrderRepository salesOrderRepository,
    required SalesAgreementRepository salesAgreementRepository,
    SharedPreferences? preferences,
  })  : _salesOrderRepository = salesOrderRepository,
        _salesAgreementRepository = salesAgreementRepository,
        _preferences = preferences;

  static const _prefKeyPrefix = 'sales_agreement_backfill_v1_';

  final SalesOrderRepository _salesOrderRepository;
  final SalesAgreementRepository _salesAgreementRepository;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  /// Runs once per factory while migration is incomplete; retries until
  /// [SalesAgreementBackfillReport.isComplete] is true.
  Future<SalesAgreementBackfillReport> runIfNeeded(String factoryId) async {
    final prefs = await _prefs;
    final key = '$_prefKeyPrefix$factoryId';
    if (prefs.getBool(key) == true) {
      return SalesAgreementBackfillReport.empty;
    }

    final report = await run(factoryId);
    debugPrint('SalesAgreementBackfill: $report');

    if (report.isComplete) {
      await prefs.setBool(key, true);
    }
    return report;
  }

  Future<SalesAgreementBackfillReport> run(String factoryId) async {
    final orders = await _salesOrderRepository.getSalesOrders(factoryId);
    var linked = 0;
    var alreadyLinked = 0;
    var failed = 0;

    for (final order in orders) {
      try {
        if (order.hasAgreement) {
          alreadyLinked++;
          continue;
        }
        await _salesAgreementRepository.ensureAgreementForOrder(order);
        linked++;
      } catch (error, stack) {
        failed++;
        debugPrint(
          'SalesAgreementBackfill: failed for ${order.id}: $error\n$stack',
        );
      }
    }

    final remainingLegacy = await _countLegacyOrders(factoryId);

    return SalesAgreementBackfillReport(
      ordersProcessed: orders.length,
      agreementsEnsured: linked,
      alreadyLinked: alreadyLinked,
      failed: failed,
      remainingLegacyOrders: remainingLegacy,
    );
  }

  Future<int> _countLegacyOrders(String factoryId) async {
    final orders = await _salesOrderRepository.getSalesOrders(factoryId);
    return orders.where((SalesOrder order) => !order.hasAgreement).length;
  }
}

class SalesAgreementBackfillReport {
  const SalesAgreementBackfillReport({
    required this.ordersProcessed,
    required this.agreementsEnsured,
    required this.alreadyLinked,
    required this.failed,
    required this.remainingLegacyOrders,
  });

  static const empty = SalesAgreementBackfillReport(
    ordersProcessed: 0,
    agreementsEnsured: 0,
    alreadyLinked: 0,
    failed: 0,
    remainingLegacyOrders: 0,
  );

  final int ordersProcessed;
  final int agreementsEnsured;
  final int alreadyLinked;
  final int failed;
  final int remainingLegacyOrders;

  bool get isComplete => remainingLegacyOrders == 0 && failed == 0;

  @override
  String toString() {
    return 'SalesAgreementBackfillReport('
        'processed: $ordersProcessed, '
        'ensured: $agreementsEnsured, '
        'alreadyLinked: $alreadyLinked, '
        'failed: $failed, '
        'remainingLegacy: $remainingLegacyOrders)';
  }
}
