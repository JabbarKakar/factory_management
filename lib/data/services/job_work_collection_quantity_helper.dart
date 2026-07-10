import 'dart:math' as math;

import '../../core/constants/job_work_sizes.dart';
import '../../domain/entities/job_work_collection.dart';
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

/// Eligibility + remaining qty for Job Work Collect Material (Phase 1).
///
/// Collect is allowed once cutting has started ([JobWorkStatus.canCollectMaterial]),
/// independent of payment. Remaining is produced stock minus prior collections.
abstract final class JobWorkCollectionQuantityHelper {
  static List<StockOutput> producedStock(JobWorkOrder order) {
    final output = order.output;
    if (output != null && output.hasStockOutputs) {
      return _mergeBySize(output.allStockOutputs);
    }
    if (order.shiftLogs.any((shift) => shift.hasStockOutputs)) {
      final aggregated = JobWorkOutput.aggregateFromShifts(order.shiftLogs);
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
    final produced = producedStock(order);
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
    final lines = <JobWorkCollectionRemainingLine>[];
    for (final stock in producedStock(order)) {
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
}
