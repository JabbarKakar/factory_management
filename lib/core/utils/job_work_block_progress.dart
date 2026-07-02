import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/job_work_output.dart';

/// Block-cutting progress derived from job work shifts.
abstract final class JobWorkBlockProgress {
  static int totalBlocksCut(Iterable<JobWorkShiftLog> shifts) {
    return shifts.fold<int>(0, (sum, shift) => sum + shift.blocksCut);
  }

  static int remainingBlocks({
    required int totalBlocks,
    required Iterable<JobWorkShiftLog> shifts,
  }) {
    if (totalBlocks <= 0) return 0;
    return (totalBlocks - totalBlocksCut(shifts)).clamp(0, totalBlocks);
  }

  static int maxBlocksForNextShift({
    required int totalBlocks,
    required Iterable<JobWorkShiftLog> existingShifts,
    String? excludeShiftId,
  }) {
    final alreadyCut = existingShifts
        .where((shift) => excludeShiftId == null || shift.id != excludeShiftId)
        .fold<int>(0, (sum, shift) => sum + shift.blocksCut);
    return (totalBlocks - alreadyCut).clamp(0, totalBlocks);
  }

  static int remainingAfterShift({
    required int totalBlocks,
    required int blocksAlreadyCut,
    required int blocksCutThisShift,
  }) {
    return (totalBlocks - blocksAlreadyCut - blocksCutThisShift)
        .clamp(0, totalBlocks);
  }

  static double completionPercent({
    required int totalBlocks,
    required int blocksCut,
  }) {
    if (totalBlocks <= 0) return 0;
    final percent = (blocksCut / totalBlocks) * 100;
    return percent.clamp(0, 100).toDouble();
  }

  static int totalBlocksCutFor(JobWorkOrder order) =>
      totalBlocksCut(order.shiftLogs);

  static int remainingBlocksFor(JobWorkOrder order) => remainingBlocks(
        totalBlocks: order.blockCount,
        shifts: order.shiftLogs,
      );

  static double completionPercentFor(JobWorkOrder order) =>
      completionPercent(
        totalBlocks: order.blockCount,
        blocksCut: totalBlocksCutFor(order),
      );
}
