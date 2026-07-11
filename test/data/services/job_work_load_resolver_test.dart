import 'package:factory_management/data/services/job_work_load_resolver.dart';
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
    JobWorkStatus status = JobWorkStatus.ready,
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
      output: const JobWorkOutput(
        smallStockOutputs: [
          StockOutput(
            size: '12x12',
            pieces: 100,
            squareFeet: 100,
            pricePerSqFt: 50,
            amount: 5000,
          ),
        ],
      ),
    );
  }

  JobWorkLoad buildPersistedLoad({
    required String id,
    int sequence = 1,
    LoadStatus status = JobWorkStatus.inCutting,
  }) {
    return JobWorkLoad.fromLegacyOrder(
      buildOrder(status: status),
      id: id,
      loadNumber: 'JWL-2026-0001',
      loadSequence: sequence,
      migratedFromJobWork: true,
    );
  }

  group('JobWorkSummaryStatus.fromLoadStatuses', () {
    test('empty → idle', () {
      expect(
        JobWorkSummaryStatus.fromLoadStatuses(const []),
        JobWorkSummaryStatus.idle,
      );
    });

    test('all cancelled → cancelled', () {
      expect(
        JobWorkSummaryStatus.fromLoadStatuses(const [
          JobWorkStatus.cancelled,
          JobWorkStatus.cancelled,
        ]),
        JobWorkSummaryStatus.cancelled,
      );
    });

    test('all completed → idle', () {
      expect(
        JobWorkSummaryStatus.fromLoadStatuses(const [
          JobWorkStatus.collected,
          JobWorkStatus.closed,
        ]),
        JobWorkSummaryStatus.idle,
      );
    });

    test('any pending pickup → pendingPickup', () {
      expect(
        JobWorkSummaryStatus.fromLoadStatuses(const [
          JobWorkStatus.inCutting,
          JobWorkStatus.ready,
        ]),
        JobWorkSummaryStatus.pendingPickup,
      );
    });

    test('active production without pickup → active', () {
      expect(
        JobWorkSummaryStatus.fromLoadStatuses(const [
          JobWorkStatus.inCutting,
          JobWorkStatus.qc,
        ]),
        JobWorkSummaryStatus.active,
      );
    });
  });

  group('JobWorkLoadResolver', () {
    test('synthesizeDefaultLoad marks virtual Load 1', () {
      final order = buildOrder();
      final load = JobWorkLoadResolver.synthesizeDefaultLoad(order);

      expect(load.isVirtual, isTrue);
      expect(load.loadSequence, 1);
      expect(load.jobWorkId, order.id);
      expect(load.status, order.status);
      expect(load.blockCount, order.blockCount);
      expect(load.marbleVariety, order.marbleVariety);
      expect(load.id, JobWorkLoadResolver.virtualLoadId(order.id));
    });

    test('resolveLoads returns virtual when no persisted loads', () {
      final order = buildOrder();
      final resolved = JobWorkLoadResolver.resolveLoads(order, const []);

      expect(resolved, hasLength(1));
      expect(resolved.single.isVirtual, isTrue);
    });

    test('resolveLoads prefers persisted loads and sorts by sequence', () {
      final order = buildOrder();
      final loads = [
        buildPersistedLoad(id: 'l2', sequence: 2),
        buildPersistedLoad(id: 'l1', sequence: 1),
      ];
      final resolved = JobWorkLoadResolver.resolveLoads(order, loads);

      expect(resolved, hasLength(2));
      expect(resolved.map((load) => load.id), ['l1', 'l2']);
      expect(resolved.every((load) => !load.isVirtual), isTrue);
    });

    test('preferredDefaultLoad prefers defaultLoadId then sequence 1', () {
      final order = buildOrder().copyWith(defaultLoadId: 'l2');
      final loads = [
        buildPersistedLoad(id: 'l1', sequence: 1),
        buildPersistedLoad(id: 'l2', sequence: 2),
      ];
      expect(
        JobWorkLoadResolver.preferredDefaultLoad(order, loads).id,
        'l2',
      );

      final withoutDefault = buildOrder();
      expect(
        JobWorkLoadResolver.preferredDefaultLoad(withoutDefault, loads).id,
        'l1',
      );
    });

    test('hasPersistedLoads gates ensureDefaultLoad create path', () {
      expect(JobWorkLoadResolver.hasPersistedLoads(const []), isFalse);
      expect(
        JobWorkLoadResolver.hasPersistedLoads([
          buildPersistedLoad(id: 'l1'),
        ]),
        isTrue,
      );
    });

    test('nextLoadSequence increments from max existing', () {
      expect(JobWorkLoadResolver.nextLoadSequence(const []), 1);
      expect(
        JobWorkLoadResolver.nextLoadSequence([
          buildPersistedLoad(id: 'l1', sequence: 1),
          buildPersistedLoad(id: 'l3', sequence: 3),
        ]),
        4,
      );
    });

    test('ensureDefaultLoad is idempotent when loads already exist', () {
      // Pure decision: with persisted loads, resolver must not synthesize.
      final order = buildOrder();
      final existing = [buildPersistedLoad(id: 'l1', sequence: 1)];
      expect(JobWorkLoadResolver.hasPersistedLoads(existing), isTrue);
      final resolved = JobWorkLoadResolver.resolveLoads(order, existing);
      expect(resolved, hasLength(1));
      expect(resolved.single.id, 'l1');
      expect(resolved.single.isVirtual, isFalse);
      expect(
        JobWorkLoadResolver.preferredDefaultLoad(order, existing).id,
        'l1',
      );
    });
  });

  group('LoadStatus typedef', () {
    test('shares firestore values with JobWorkStatus', () {
      const LoadStatus status = JobWorkStatus.partiallyCollected;
      expect(status.firestoreValue, 'partiallyCollected');
      expect(status.canCollectMaterial, isTrue);
      expect(status.isPendingPickup, isTrue);
    });
  });
}
