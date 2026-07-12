import 'dart:math' as math;

import '../../core/constants/job_work_sizes.dart';
import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';
import '../../domain/entities/stock_output.dart';
import '../../domain/enums/job_work_enums.dart';

class JobWorkCollectionRemainingLine {
  const JobWorkCollectionRemainingLine({
    required this.size,
    required this.isSmall,
    required this.producedPieces,
    required this.producedSquareFeet,
    required this.remainingPieces,
    required this.remainingSquareFeet,
  });

  final String size;
  final bool isSmall;
  final int producedPieces;
  final double producedSquareFeet;
  final int remainingPieces;
  final double remainingSquareFeet;
}

class JobWorkCollectionTotals {
  const JobWorkCollectionTotals({
    required this.totalPieces,
    required this.totalSquareFeet,
    required this.collectedPieces,
    required this.collectedSquareFeet,
  });

  final int totalPieces;
  final double totalSquareFeet;
  final int collectedPieces;
  final double collectedSquareFeet;

  int get remainingPieces => math.max(0, totalPieces - collectedPieces);

  double get remainingSquareFeet =>
      math.max(0, totalSquareFeet - collectedSquareFeet);

  bool get hasCollections =>
      collectedPieces > 0 || collectedSquareFeet > 0;

  bool get hasProducedStock => totalPieces > 0 || totalSquareFeet > 0;

  bool get isFullyCollected =>
      hasProducedStock &&
      remainingPieces == 0 &&
      remainingSquareFeet <= 0.001;
}

/// Eligibility + remaining qty for Collect Material.
///
/// Sprint 4: prefer Load-scoped APIs; JW-order APIs remain for aggregates /
/// legacy single-pool reads.
abstract final class JobWorkCollectionQuantityHelper {
  static List<StockOutput> producedStock(JobWorkOrder order) {
    return producedStockFromOutput(
      output: order.output,
      shiftLogs: order.shiftLogs,
    );
  }

  static List<StockOutput> producedStockForLoad(JobWorkLoad load) {
    return producedStockFromOutput(
      output: load.output,
      shiftLogs: load.shiftLogs,
    );
  }

  static List<StockOutput> producedStockFromOutput({
    JobWorkOutput? output,
    List<JobWorkShiftLog> shiftLogs = const [],
  }) {
    if (output != null && output.hasStockOutputs) {
      return _mergeBySize(output.allStockOutputs);
    }
    if (shiftLogs.any((shift) => shift.hasStockOutputs)) {
      final aggregated = JobWorkOutput.aggregateFromShifts(shiftLogs);
      return _mergeBySize(aggregated.allStockOutputs);
    }
    return const [];
  }

  static List<StockOutput> _mergeBySize(List<StockOutput> outputs) {
    final bySize = <String, StockOutput>{};
    for (final output in outputs) {
      if (!output.hasProduction && output.squareFeet <= 0) continue;
      final existing = bySize[output.size];
      if (existing == null) {
        bySize[output.size] = output;
        continue;
      }
      bySize[output.size] = existing.copyWith(
        pieces: existing.pieces + output.pieces,
        squareFeet: existing.squareFeet + output.squareFeet,
        amount: existing.amount + output.amount,
      );
    }
    return bySize.values.toList();
  }

  static bool counts(JobWorkCollection collection) =>
      collection.status.countsTowardCollected;

  static int collectedPiecesForSize(
    String size,
    List<JobWorkCollection> collections, {
    String? excludeCollectionId,
  }) {
    var total = 0;
    for (final collection in collections) {
      if (excludeCollectionId != null &&
          collection.id == excludeCollectionId) {
        continue;
      }
      if (!counts(collection)) continue;
      for (final item in collection.lineItems) {
        if (item.size == size) total += item.pieces;
      }
    }
    return total;
  }

  static double collectedSquareFeetForSize(
    String size,
    List<JobWorkCollection> collections, {
    String? excludeCollectionId,
  }) {
    var total = 0.0;
    for (final collection in collections) {
      if (excludeCollectionId != null &&
          collection.id == excludeCollectionId) {
        continue;
      }
      if (!counts(collection)) continue;
      for (final item in collection.lineItems) {
        if (item.size == size) total += item.squareFeet;
      }
    }
    return total;
  }

  static JobWorkCollectionTotals orderTotals(
    JobWorkOrder order,
    List<JobWorkCollection> collections, {
    String? excludeCollectionId,
  }) {
    return _totalsForProduced(
      producedStock(order),
      collections,
      excludeCollectionId: excludeCollectionId,
    );
  }

  static JobWorkCollectionTotals loadTotals(
    JobWorkLoad load,
    List<JobWorkCollection> collections, {
    String? excludeCollectionId,
  }) {
    return _totalsForProduced(
      producedStockForLoad(load),
      collectionsForLoad(load.id, collections),
      excludeCollectionId: excludeCollectionId,
    );
  }

  /// JW aggregate remaining across all Loads (or legacy order pool).
  static JobWorkCollectionTotals aggregateTotals({
    required JobWorkOrder order,
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
  }) {
    final orderLoads =
        loads.where((load) => load.jobWorkId == order.id).toList();
    if (orderLoads.isEmpty) {
      return orderTotals(order, collectionsForOrder(order.id, collections));
    }

    var totalPieces = 0;
    var totalSquareFeet = 0.0;
    var collectedPieces = 0;
    var collectedSquareFeet = 0.0;
    for (final load in orderLoads) {
      final totals = loadTotals(load, collections);
      totalPieces += totals.totalPieces;
      totalSquareFeet += totals.totalSquareFeet;
      collectedPieces += totals.collectedPieces;
      collectedSquareFeet += totals.collectedSquareFeet;
    }
    return JobWorkCollectionTotals(
      totalPieces: totalPieces,
      totalSquareFeet: totalSquareFeet,
      collectedPieces: collectedPieces,
      collectedSquareFeet: collectedSquareFeet,
    );
  }

  static JobWorkCollectionTotals _totalsForProduced(
    List<StockOutput> produced,
    List<JobWorkCollection> collections, {
    String? excludeCollectionId,
  }) {
    var totalPieces = 0;
    var totalSquareFeet = 0.0;
    for (final stock in produced) {
      totalPieces += stock.pieces;
      totalSquareFeet += stock.squareFeet;
    }

    var collectedPieces = 0;
    var collectedSquareFeet = 0.0;
    for (final collection in collections) {
      if (excludeCollectionId != null &&
          collection.id == excludeCollectionId) {
        continue;
      }
      if (!counts(collection)) continue;
      collectedPieces += collection.totalPieces;
      collectedSquareFeet += collection.totalSquareFeet;
    }

    return JobWorkCollectionTotals(
      totalPieces: totalPieces,
      totalSquareFeet: totalSquareFeet,
      collectedPieces: collectedPieces,
      collectedSquareFeet: collectedSquareFeet,
    );
  }

  static List<JobWorkCollectionRemainingLine> remainingLines(
    JobWorkOrder order,
    List<JobWorkCollection> collections, {
    String? excludeCollectionId,
  }) {
    return _remainingLinesForProduced(
      producedStock(order),
      collections,
      excludeCollectionId: excludeCollectionId,
    );
  }

  static List<JobWorkCollectionRemainingLine> remainingLinesForLoad(
    JobWorkLoad load,
    List<JobWorkCollection> collections, {
    String? excludeCollectionId,
  }) {
    return _remainingLinesForProduced(
      producedStockForLoad(load),
      collectionsForLoad(load.id, collections),
      excludeCollectionId: excludeCollectionId,
    );
  }

  static List<JobWorkCollectionRemainingLine> _remainingLinesForProduced(
    List<StockOutput> produced,
    List<JobWorkCollection> collections, {
    String? excludeCollectionId,
  }) {
    final lines = <JobWorkCollectionRemainingLine>[];
    for (final stock in produced) {
      final remainingPieces = math.max(
        0,
        stock.pieces -
            collectedPiecesForSize(
              stock.size,
              collections,
              excludeCollectionId: excludeCollectionId,
            ),
      );
      final remainingSquareFeet = math.max(
        0.0,
        stock.squareFeet -
            collectedSquareFeetForSize(
              stock.size,
              collections,
              excludeCollectionId: excludeCollectionId,
            ),
      );
      if (remainingPieces <= 0 && remainingSquareFeet <= 0) continue;
      lines.add(
        JobWorkCollectionRemainingLine(
          size: stock.size,
          isSmall: JobWorkSizes.isSmall(stock.size),
          producedPieces: stock.pieces,
          producedSquareFeet: stock.squareFeet,
          remainingPieces: remainingPieces,
          remainingSquareFeet: remainingSquareFeet,
        ),
      );
    }
    return lines;
  }

  static bool canOpenCollectMaterial(
    JobWorkOrder order,
    List<JobWorkCollection> collections,
  ) {
    if (!order.status.canCollectMaterial) return false;
    final totals = orderTotals(order, collections);
    return totals.remainingPieces > 0 || totals.remainingSquareFeet > 0.001;
  }

  static bool canOpenCollectMaterialForLoad(
    JobWorkLoad load,
    List<JobWorkCollection> collections,
  ) {
    if (load.isVirtual) return false;
    if (!load.status.canCollectMaterial) return false;
    final totals = loadTotals(load, collections);
    return totals.remainingPieces > 0 || totals.remainingSquareFeet > 0.001;
  }

  /// Pending pickup for dashboard/list.
  static bool isPendingPickup(
    JobWorkOrder order,
    List<JobWorkCollection> collections,
  ) {
    return canOpenCollectMaterial(order, collections);
  }

  static bool isPendingPickupForOrder({
    required JobWorkOrder order,
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
  }) {
    final orderLoads =
        loads.where((load) => load.jobWorkId == order.id).toList();
    if (orderLoads.isEmpty) {
      return isPendingPickup(order, collectionsForOrder(order.id, collections));
    }
    return orderLoads.any(
      (load) => canOpenCollectMaterialForLoad(load, collections),
    );
  }

  /// Customer-facing pending: ready → partiallyCollected with remaining stock.
  static bool isCustomerFacingPendingPickup(
    JobWorkOrder order,
    List<JobWorkCollection> collections,
  ) {
    if (!order.status.isPendingPickup) return false;
    return isPendingPickup(order, collections);
  }

  static bool isCustomerFacingPendingPickupForOrder({
    required JobWorkOrder order,
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
  }) {
    final orderLoads =
        loads.where((load) => load.jobWorkId == order.id).toList();
    if (orderLoads.isEmpty) {
      return isCustomerFacingPendingPickup(
        order,
        collectionsForOrder(order.id, collections),
      );
    }
    return orderLoads.any((load) {
      if (!load.status.isPendingPickup) return false;
      return canOpenCollectMaterialForLoad(load, collections);
    });
  }

  static const int stalePickupAfterDays = 7;

  static DateTime pickupWaitReferenceDate(
    JobWorkOrder order,
    List<JobWorkCollection> collections,
  ) {
    return _pickupWaitReference(
      collections: collections,
      cuttingCompletionDate: order.execution?.cuttingCompletionDate,
      createdAt: order.createdAt,
    );
  }

  static DateTime pickupWaitReferenceDateForLoad(
    JobWorkLoad load,
    List<JobWorkCollection> collections,
  ) {
    return _pickupWaitReference(
      collections: collectionsForLoad(load.id, collections),
      cuttingCompletionDate: load.execution?.cuttingCompletionDate,
      createdAt: load.createdAt,
    );
  }

  static DateTime _pickupWaitReference({
    required List<JobWorkCollection> collections,
    required DateTime? cuttingCompletionDate,
    required DateTime createdAt,
  }) {
    DateTime? latestCollection;
    for (final collection in collections) {
      if (!counts(collection)) continue;
      final at = collection.collectedAt;
      if (latestCollection == null || at.isAfter(latestCollection)) {
        latestCollection = at;
      }
    }
    if (latestCollection != null) return latestCollection;
    if (cuttingCompletionDate != null) return cuttingCompletionDate;
    return createdAt;
  }

  static int pickupDaysWaiting(
    JobWorkOrder order,
    List<JobWorkCollection> collections, {
    DateTime? reference,
  }) {
    if (!isCustomerFacingPendingPickup(order, collections)) return 0;
    return _daysWaiting(
      pickupWaitReferenceDate(order, collections),
      reference,
    );
  }

  static int pickupDaysWaitingForOrder({
    required JobWorkOrder order,
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
    DateTime? reference,
  }) {
    if (!isCustomerFacingPendingPickupForOrder(
      order: order,
      collections: collections,
      loads: loads,
    )) {
      return 0;
    }
    final orderLoads =
        loads.where((load) => load.jobWorkId == order.id).toList();
    if (orderLoads.isEmpty) {
      return pickupDaysWaiting(order, collections, reference: reference);
    }

    var maxDays = 0;
    for (final load in orderLoads) {
      if (!load.status.isPendingPickup) continue;
      if (!canOpenCollectMaterialForLoad(load, collections)) continue;
      final days = _daysWaiting(
        pickupWaitReferenceDateForLoad(load, collections),
        reference,
      );
      if (days > maxDays) maxDays = days;
    }
    return maxDays;
  }

  static int _daysWaiting(DateTime waitFrom, DateTime? reference) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final waitDay = DateTime(waitFrom.year, waitFrom.month, waitFrom.day);
    return today.difference(waitDay).inDays;
  }

  static bool isPickupOverdue(
    JobWorkOrder order,
    List<JobWorkCollection> collections, {
    DateTime? reference,
    int staleAfterDays = stalePickupAfterDays,
  }) {
    return pickupDaysWaiting(
          order,
          collections,
          reference: reference,
        ) >=
        staleAfterDays;
  }

  static bool isPickupOverdueForOrder({
    required JobWorkOrder order,
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
    DateTime? reference,
    int staleAfterDays = stalePickupAfterDays,
  }) {
    return pickupDaysWaitingForOrder(
          order: order,
          collections: collections,
          loads: loads,
          reference: reference,
        ) >=
        staleAfterDays;
  }

  static bool canOpenCollectMaterialForOrder({
    required JobWorkOrder order,
    required List<JobWorkCollection> collections,
    required List<JobWorkLoad> loads,
  }) {
    return isPendingPickupForOrder(
      order: order,
      collections: collections,
      loads: loads,
    );
  }

  /// List/badge status when Loads are authoritative.
  ///
  /// Prefers collection-facing Load statuses so the JW row does not stay on
  /// stale container `order.status` after per-Load collect.
  static JobWorkStatus displayStatusForOrder({
    required JobWorkOrder order,
    required List<JobWorkLoad> loads,
  }) {
    final orderLoads = loads
        .where((load) => load.jobWorkId == order.id && !load.isVirtual)
        .toList();
    if (orderLoads.isEmpty) return order.status;

    if (orderLoads.any(
      (load) => load.status == JobWorkStatus.partiallyCollected,
    )) {
      return JobWorkStatus.partiallyCollected;
    }

    final nonCancelled = orderLoads
        .where((load) => load.status != JobWorkStatus.cancelled)
        .toList();
    if (nonCancelled.isEmpty) return JobWorkStatus.cancelled;

    if (nonCancelled.every((load) => load.status.isCompleted)) {
      if (nonCancelled.every((load) => load.status == JobWorkStatus.closed)) {
        return JobWorkStatus.closed;
      }
      return JobWorkStatus.collected;
    }

    final active = nonCancelled
        .where((load) => !load.status.isCompleted)
        .toList()
      ..sort((a, b) {
        final rank = a.status.listSortRank.compareTo(b.status.listSortRank);
        if (rank != 0) return rank;
        return a.status.index.compareTo(b.status.index);
      });
    return active.first.status;
  }

  static List<JobWorkCollection> collectionsForOrder(
    String jobWorkOrderId,
    List<JobWorkCollection> allCollections,
  ) {
    return allCollections
        .where((collection) => collection.jobWorkOrderId == jobWorkOrderId)
        .toList();
  }

  static List<JobWorkCollection> collectionsForLoad(
    String loadId,
    List<JobWorkCollection> allCollections,
  ) {
    return allCollections
        .where(
          (collection) =>
              collection.loadId != null && collection.loadId == loadId,
        )
        .toList();
  }
}
