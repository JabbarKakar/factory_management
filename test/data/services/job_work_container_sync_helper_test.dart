import 'package:factory_management/data/services/job_work_container_sync_helper.dart';
import 'package:factory_management/domain/entities/job_work_load.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobWorkOrder buildOrder({
    JobWorkStatus status = JobWorkStatus.agreed,
    double finalCuttingCharges = 0,
    double advanceReceived = 0,
    double balanceDue = 0,
    String? invoiceId,
  }) {
    return JobWorkOrder(
      id: 'jw-1',
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
      advanceReceived: advanceReceived,
      balanceDue: balanceDue,
      finalCuttingCharges: finalCuttingCharges,
      paymentTerms: PaymentTerms.cash,
      createdAt: DateTime(2026, 1, 1),
      invoiceId: invoiceId,
    );
  }

  JobWorkLoad buildLoad({
    required String id,
    int sequence = 1,
    JobWorkStatus status = JobWorkStatus.ready,
    double finalCuttingCharges = 1000,
    double advanceReceived = 0,
    double balanceDue = 1000,
  }) {
    return JobWorkLoad.fromLegacyOrder(
      buildOrder(),
      id: id,
      loadNumber: 'JWL-$sequence',
      loadSequence: sequence,
    ).copyWith(
      status: status,
      finalCuttingCharges: finalCuttingCharges,
      advanceReceived: advanceReceived,
      balanceDue: balanceDue,
    );
  }

  group('resolveContainerStatus', () {
    test('keeps cancelled JW cancelled even if loads are active', () {
      final status = JobWorkContainerSyncHelper.resolveContainerStatus(
        order: buildOrder(status: JobWorkStatus.cancelled),
        loads: [
          buildLoad(id: 'load-1', status: JobWorkStatus.ready),
        ],
      );
      expect(status, JobWorkStatus.cancelled);
    });

    test('derives ready from loads when JW status is still agreed', () {
      final status = JobWorkContainerSyncHelper.resolveContainerStatus(
        order: buildOrder(status: JobWorkStatus.agreed),
        loads: [
          buildLoad(id: 'load-1', status: JobWorkStatus.ready),
        ],
      );
      expect(status, JobWorkStatus.ready);
    });

    test('keeps invoiced until collection statuses take over', () {
      final status = JobWorkContainerSyncHelper.resolveContainerStatus(
        order: buildOrder(status: JobWorkStatus.invoiced),
        loads: [
          buildLoad(id: 'load-1', status: JobWorkStatus.ready),
        ],
      );
      expect(status, JobWorkStatus.invoiced);
    });
  });

  group('rollup + canGenerateInvoice', () {
    test('rolls up cutting charges from loads', () {
      final charges = JobWorkContainerSyncHelper.rollupFinalCuttingCharges(
        order: buildOrder(finalCuttingCharges: 50),
        loads: [
          buildLoad(id: 'l1', finalCuttingCharges: 400),
          buildLoad(
            id: 'l2',
            sequence: 2,
            finalCuttingCharges: 600,
          ),
        ],
      );
      expect(charges, 1000);
    });

    test('allows invoice when loads are ready with charges', () {
      final can = JobWorkContainerSyncHelper.canGenerateInvoice(
        order: buildOrder(status: JobWorkStatus.agreed),
        loads: [
          buildLoad(
            id: 'l1',
            status: JobWorkStatus.ready,
            finalCuttingCharges: 2500,
          ),
        ],
      );
      expect(can, isTrue);
    });

    test('blocks invoice when cancelled', () {
      final can = JobWorkContainerSyncHelper.canGenerateInvoice(
        order: buildOrder(status: JobWorkStatus.cancelled),
        loads: [
          buildLoad(id: 'l1', status: JobWorkStatus.ready),
        ],
      );
      expect(can, isFalse);
    });

    test('blocks invoice when charges are zero', () {
      final can = JobWorkContainerSyncHelper.canGenerateInvoice(
        order: buildOrder(status: JobWorkStatus.agreed),
        loads: [
          buildLoad(
            id: 'l1',
            status: JobWorkStatus.ready,
            finalCuttingCharges: 0,
            balanceDue: 0,
          ),
        ],
      );
      expect(can, isFalse);
    });
  });
}
