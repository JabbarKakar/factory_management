import 'package:factory_management/data/services/job_work_load_production_helper.dart';
import 'package:factory_management/domain/entities/job_work_load.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/entities/job_work_output.dart';
import 'package:factory_management/domain/entities/stock_output.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';
import 'package:factory_management/domain/enums/job_work_load_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobWorkOrder buildOrder({
    JobWorkStatus status = JobWorkStatus.agreed,
    String id = 'jw-1',
  }) {
    return JobWorkOrder(
      id: id,
      jobWorkNumber: 'JW-2026-0001',
      factoryId: 'factory-1',
      customerId: 'customer-1',
      customerName: 'Customer',
      status: status,
      receivedDate: DateTime(2026, 1, 1),
      marbleVariety: 'Black Galaxy',
      blockCount: 10,
      totalTons: 20,
      cuttingStrategy: CuttingStrategy.bridgeSaw,
      targetProduct: TargetProduct.tiles,
      thickness: '18mm',
      finish: FinishType.polished,
      pricingModel: PricingModel.perSqFt,
      agreedRate: 50,
      advanceReceived: 0,
      balanceDue: 1000,
      paymentTerms: PaymentTerms.cash,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  JobWorkLoad buildLoad({
    required String id,
    required String jobWorkId,
    int sequence = 1,
    LoadStatus status = JobWorkStatus.agreed,
    bool isVirtual = false,
    JobWorkOutput? output,
    JobWorkExecution? execution,
  }) {
    return JobWorkLoad.fromLegacyOrder(
      buildOrder(id: jobWorkId, status: status),
      id: id,
      loadNumber: 'JWL-2026-${sequence.toString().padLeft(4, '0')}',
      loadSequence: sequence,
    ).copyWith(
      status: status,
      isVirtual: isVirtual,
      output: output,
      execution: execution,
    );
  }

  const recordedOutput = JobWorkOutput(
    smallStockOutputs: [
      StockOutput(
        size: '12x12',
        pieces: 10,
        squareFeet: 100,
        pricePerSqFt: 50,
        amount: 5000,
      ),
    ],
    recordedAt: null, // set below via copyWith in tests
  );

  group('statusAfterOutputSaved', () {
    test('agreed + usable output → inCutting', () {
      final load = buildLoad(
        id: 'load-1',
        jobWorkId: 'jw-1',
        status: JobWorkStatus.agreed,
        output: recordedOutput.copyWith(recordedAt: DateTime(2026, 1, 2)),
      );
      expect(
        JobWorkLoadProductionHelper.statusAfterOutputSaved(load),
        JobWorkStatus.inCutting,
      );
    });

    test('agreed + cutting start → inCutting', () {
      final load = buildLoad(
        id: 'load-1',
        jobWorkId: 'jw-1',
        status: JobWorkStatus.agreed,
        output: const JobWorkOutput(
          wasteAmount: 1,
          recordedAt: null,
        ).copyWith(recordedAt: DateTime(2026, 1, 2)),
        execution: const JobWorkExecution(
          cuttingStartDate: null,
        ).copyWith(cuttingStartDate: DateTime(2026, 1, 2)),
      );
      // Ensure execution has start - JobWorkExecution may need different construction
      final withStart = load.copyWith(
        execution: JobWorkExecution(cuttingStartDate: DateTime(2026, 1, 2)),
        output: const JobWorkOutput(wasteAmount: 1)
            .copyWith(recordedAt: DateTime(2026, 1, 2)),
      );
      expect(
        JobWorkLoadProductionHelper.statusAfterOutputSaved(withStart),
        JobWorkStatus.inCutting,
      );
    });

    test('inCutting + completion date → qc', () {
      final load = buildLoad(
        id: 'load-1',
        jobWorkId: 'jw-1',
        status: JobWorkStatus.inCutting,
        output: recordedOutput.copyWith(recordedAt: DateTime(2026, 1, 2)),
        execution: JobWorkExecution(
          cuttingStartDate: DateTime(2026, 1, 1),
          cuttingCompletionDate: DateTime(2026, 1, 3),
        ),
      );
      expect(
        JobWorkLoadProductionHelper.statusAfterOutputSaved(load),
        JobWorkStatus.qc,
      );
    });

    test('qc + completion date → ready', () {
      final load = buildLoad(
        id: 'load-1',
        jobWorkId: 'jw-1',
        status: JobWorkStatus.qc,
        output: recordedOutput.copyWith(recordedAt: DateTime(2026, 1, 2)),
        execution: JobWorkExecution(
          cuttingCompletionDate: DateTime(2026, 1, 3),
        ),
      );
      expect(
        JobWorkLoadProductionHelper.statusAfterOutputSaved(load),
        JobWorkStatus.ready,
      );
    });

    test('unrecorded output leaves status unchanged', () {
      final load = buildLoad(
        id: 'load-1',
        jobWorkId: 'jw-1',
        status: JobWorkStatus.agreed,
        output: const JobWorkOutput(),
      );
      expect(
        JobWorkLoadProductionHelper.statusAfterOutputSaved(load),
        JobWorkStatus.agreed,
      );
    });
  });

  group('preferredLoadForRecordOutput', () {
    test('prefers inCutting over agreed', () {
      final preferred = JobWorkLoadProductionHelper.preferredLoadForRecordOutput([
        buildLoad(
          id: 'load-2',
          jobWorkId: 'jw-1',
          sequence: 2,
          status: JobWorkStatus.agreed,
        ),
        buildLoad(
          id: 'load-1',
          jobWorkId: 'jw-1',
          sequence: 1,
          status: JobWorkStatus.inCutting,
        ),
      ]);
      expect(preferred?.id, 'load-1');
    });

    test('skips virtual loads', () {
      final preferred = JobWorkLoadProductionHelper.preferredLoadForRecordOutput([
        buildLoad(
          id: 'virtual',
          jobWorkId: 'jw-1',
          status: JobWorkStatus.agreed,
          isVirtual: true,
        ),
      ]);
      expect(preferred, isNull);
    });

    test('returns null when no load can record', () {
      final preferred = JobWorkLoadProductionHelper.preferredLoadForRecordOutput([
        buildLoad(
          id: 'load-1',
          jobWorkId: 'jw-1',
          status: JobWorkStatus.closed,
        ),
      ]);
      expect(preferred, isNull);
    });
  });

  group('orderCanRecordOutput', () {
    test('uses load capability when loads exist', () {
      final order = buildOrder(status: JobWorkStatus.collected);
      final can = JobWorkLoadProductionHelper.orderCanRecordOutput(
        order: order,
        loads: [
          buildLoad(
            id: 'load-1',
            jobWorkId: order.id,
            status: JobWorkStatus.agreed,
          ),
        ],
      );
      expect(can, isTrue);
    });

    test('falls back to order status when no loads', () {
      final order = buildOrder(status: JobWorkStatus.agreed);
      expect(
        JobWorkLoadProductionHelper.orderCanRecordOutput(
          order: order,
          loads: const [],
        ),
        isTrue,
      );
    });
  });

  group('isAwaitingQcInspection', () {
    test('load in qc without load QC is awaiting', () {
      final order = buildOrder(status: JobWorkStatus.agreed);
      expect(
        JobWorkLoadProductionHelper.isAwaitingQcInspection(
          order: order,
          loads: [
            buildLoad(
              id: 'load-1',
              jobWorkId: order.id,
              status: JobWorkStatus.qc,
            ),
          ],
          loadIdsWithQc: const {},
          jobWorkIdsWithQc: const {},
        ),
        isTrue,
      );
    });

    test('load in qc with load QC is not awaiting', () {
      final order = buildOrder(status: JobWorkStatus.agreed);
      expect(
        JobWorkLoadProductionHelper.isAwaitingQcInspection(
          order: order,
          loads: [
            buildLoad(
              id: 'load-1',
              jobWorkId: order.id,
              status: JobWorkStatus.qc,
            ),
          ],
          loadIdsWithQc: const {'load-1'},
          jobWorkIdsWithQc: const {},
        ),
        isFalse,
      );
    });

    test('legacy order qc without loads still works', () {
      final order = buildOrder(status: JobWorkStatus.qc);
      expect(
        JobWorkLoadProductionHelper.isAwaitingQcInspection(
          order: order,
          loads: const [],
          loadIdsWithQc: const {},
          jobWorkIdsWithQc: const {},
        ),
        isTrue,
      );
    });

    test('multi-load: only counts loads missing QC', () {
      final order = buildOrder();
      expect(
        JobWorkLoadProductionHelper.awaitingQcCount(
          orders: [order],
          loads: [
            buildLoad(
              id: 'load-1',
              jobWorkId: order.id,
              sequence: 1,
              status: JobWorkStatus.qc,
            ),
            buildLoad(
              id: 'load-2',
              jobWorkId: order.id,
              sequence: 2,
              status: JobWorkStatus.agreed,
            ),
          ],
          loadIdsWithQc: const {},
          jobWorkIdsWithQc: const {},
        ),
        1,
      );
    });
  });
}
