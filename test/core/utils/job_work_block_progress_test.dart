import 'package:factory_management/core/utils/job_work_block_progress.dart';
import 'package:factory_management/domain/entities/job_work_output.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobWorkShiftLog shift({required int blocksCut, String id = '1'}) {
    return JobWorkShiftLog(
      id: id,
      shiftDate: DateTime(2026, 1, 1),
      blocksCut: blocksCut,
      recordedAt: DateTime(2026, 1, 1),
    );
  }

  group('JobWorkBlockProgress', () {
    test('totalBlocksCut sums all shifts', () {
      final shifts = [
        shift(blocksCut: 5, id: '1'),
        shift(blocksCut: 3, id: '2'),
        shift(blocksCut: 4, id: '3'),
      ];

      expect(JobWorkBlockProgress.totalBlocksCut(shifts), 12);
    });

    test('totalBlocksCut treats missing values as zero', () {
      final shifts = [
        shift(blocksCut: 0, id: '1'),
        shift(blocksCut: 2, id: '2'),
      ];

      expect(JobWorkBlockProgress.totalBlocksCut(shifts), 2);
    });

    test('remainingBlocks subtracts cut blocks from total', () {
      final shifts = [
        shift(blocksCut: 5, id: '1'),
        shift(blocksCut: 3, id: '2'),
      ];

      expect(
        JobWorkBlockProgress.remainingBlocks(totalBlocks: 20, shifts: shifts),
        12,
      );
    });

    test('remainingBlocks never goes below zero', () {
      final shifts = [shift(blocksCut: 25, id: '1')];

      expect(
        JobWorkBlockProgress.remainingBlocks(totalBlocks: 20, shifts: shifts),
        0,
      );
    });

    test('maxBlocksForNextShift excludes current shift when editing', () {
      final shifts = [
        shift(blocksCut: 5, id: '1'),
        shift(blocksCut: 3, id: '2'),
      ];

      expect(
        JobWorkBlockProgress.maxBlocksForNextShift(
          totalBlocks: 20,
          existingShifts: shifts,
        ),
        12,
      );

      expect(
        JobWorkBlockProgress.maxBlocksForNextShift(
          totalBlocks: 20,
          existingShifts: shifts,
          excludeShiftId: '2',
        ),
        15,
      );
    });

    test('remainingAfterShift updates live for dialog preview', () {
      expect(
        JobWorkBlockProgress.remainingAfterShift(
          totalBlocks: 20,
          blocksAlreadyCut: 18,
          blocksCutThisShift: 2,
        ),
        0,
      );

      expect(
        JobWorkBlockProgress.remainingAfterShift(
          totalBlocks: 20,
          blocksAlreadyCut: 15,
          blocksCutThisShift: 3,
        ),
        2,
      );
    });

    test('completionPercent calculates rounded progress', () {
      expect(
        JobWorkBlockProgress.completionPercent(
          totalBlocks: 20,
          blocksCut: 12,
        ),
        60,
      );

      expect(
        JobWorkBlockProgress.completionPercent(
          totalBlocks: 0,
          blocksCut: 5,
        ),
        0,
      );
    });
  });
}
