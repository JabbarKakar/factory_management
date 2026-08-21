import '../../domain/entities/job_work_collection.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../constants/job_work_sizes.dart';
import 'job_work_charges_calculator.dart';

class JobWorkCollectionSlipTotals {
  const JobWorkCollectionSlipTotals({
    required this.smallItems,
    required this.largeItems,
    required this.smallPieces,
    required this.largePieces,
    required this.smallSqFt,
    required this.largeSqFt,
    required this.smallAmount,
    required this.largeAmount,
  });

  final List<JobWorkCollectionLineItem> smallItems;
  final List<JobWorkCollectionLineItem> largeItems;
  final int smallPieces;
  final int largePieces;
  final double smallSqFt;
  final double largeSqFt;
  final double smallAmount;
  final double largeAmount;

  int get grandPieces => smallPieces + largePieces;
  double get grandSqFt => smallSqFt + largeSqFt;
  double get grandAmount => smallAmount + largeAmount;

  static JobWorkCollectionSlipTotals fromCollection({
    required JobWorkCollection collection,
    JobWorkLoad? load,
    JobWorkOrder? order,
  }) {
    final activeItems = collection.lineItems
        .where((item) => item.pieces > 0 || item.squareFeet > 0)
        .toList();
    final items = activeItems.isNotEmpty ? activeItems : collection.lineItems;

    final smallItems = items
        .where(
          (item) =>
              JobWorkSizes.isSmall(item.size) ||
              (item.isSmall && !JobWorkSizes.isLarge(item.size)),
        )
        .toList();
    final largeItems = items
        .where(
          (item) =>
              JobWorkSizes.isLarge(item.size) ||
              (!item.isSmall && !JobWorkSizes.isSmall(item.size)),
        )
        .toList();

    final categorized = {...smallItems, ...largeItems};
    final uncategorized =
        items.where((item) => !categorized.contains(item)).toList();
    if (uncategorized.isNotEmpty) {
      smallItems.addAll(uncategorized);
    }

    var smallPieces = 0;
    var largePieces = 0;
    var smallSqFt = 0.0;
    var largeSqFt = 0.0;
    var smallAmount = 0.0;
    var largeAmount = 0.0;

    for (final item in smallItems) {
      smallPieces += item.pieces;
      smallSqFt += item.squareFeet;
      smallAmount += _chargesFor(item, load: load, order: order);
    }
    for (final item in largeItems) {
      largePieces += item.pieces;
      largeSqFt += item.squareFeet;
      largeAmount += _chargesFor(item, load: load, order: order);
    }

    return JobWorkCollectionSlipTotals(
      smallItems: smallItems,
      largeItems: largeItems,
      smallPieces: smallPieces,
      largePieces: largePieces,
      smallSqFt: smallSqFt,
      largeSqFt: largeSqFt,
      smallAmount: smallAmount,
      largeAmount: largeAmount,
    );
  }

  static bool _isSmallItem(JobWorkCollectionLineItem item) {
    return JobWorkSizes.isSmall(item.size) ||
        (item.isSmall && !JobWorkSizes.isLarge(item.size));
  }

  static double _chargesFor(
    JobWorkCollectionLineItem item, {
    JobWorkLoad? load,
    JobWorkOrder? order,
  }) {
    final rate = _rateFor(item, load: load, order: order);
    if (rate <= 0) return 0;
    return item.squareFeet > 0 ? item.squareFeet * rate : item.pieces * rate;
  }

  static double _rateFor(
    JobWorkCollectionLineItem item, {
    JobWorkLoad? load,
    JobWorkOrder? order,
  }) {
    final isSmall = _isSmallItem(item);
    final outputs = isSmall
        ? (load?.output?.smallStockOutputs ??
            order?.output?.smallStockOutputs ??
            const [])
        : (load?.output?.largeStockOutputs ??
            order?.output?.largeStockOutputs ??
            const []);

    for (final output in outputs) {
      if (output.size.trim().toLowerCase() == item.size.trim().toLowerCase() &&
          output.pricePerSqFt > 0) {
        return output.pricePerSqFt;
      }
    }

    if (isSmall) {
      if (load != null) {
        final fromLoad =
            JobWorkChargesCalculator.defaultSmallPricePerSqFtForLoad(load);
        if (fromLoad > 0) return fromLoad;
        if (load.smallStockPrice > 0) return load.smallStockPrice;
      }
      if (order != null) {
        final fromOrder =
            JobWorkChargesCalculator.defaultSmallPricePerSqFt(order);
        if (fromOrder > 0) return fromOrder;
        if (order.smallStockPrice > 0) return order.smallStockPrice;
      }
    } else {
      if (load != null) {
        final fromLoad =
            JobWorkChargesCalculator.defaultLargePricePerSqFtForLoad(load);
        if (fromLoad > 0) return fromLoad;
        if (load.largeStockPrice > 0) return load.largeStockPrice;
      }
      if (order != null) {
        final fromOrder =
            JobWorkChargesCalculator.defaultLargePricePerSqFt(order);
        if (fromOrder > 0) return fromOrder;
        if (order.largeStockPrice > 0) return order.largeStockPrice;
      }
    }

    if (load != null && load.agreedRate > 0) return load.agreedRate;
    if (order != null && order.agreedRate > 0) return order.agreedRate;
    return 0;
  }
}
