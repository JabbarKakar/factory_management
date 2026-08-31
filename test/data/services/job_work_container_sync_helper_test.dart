import 'package:factory_management/data/services/job_work_container_sync_helper.dart';
import 'package:factory_management/domain/entities/job_work_invoice.dart';
import 'package:factory_management/domain/entities/job_work_load.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/entities/payment.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
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

    test('allows invoice at any stage when charges exist', () {
      final can = JobWorkContainerSyncHelper.canGenerateInvoice(
        order: buildOrder(status: JobWorkStatus.agreed),
        loads: [
          buildLoad(
            id: 'l1',
            status: JobWorkStatus.inCutting,
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

    test('allows JW-level generate when multiple loads exist with charges', () {
      final can = JobWorkContainerSyncHelper.canGenerateInvoice(
        order: buildOrder(status: JobWorkStatus.agreed),
        loads: [
          buildLoad(id: 'l1', status: JobWorkStatus.ready),
          buildLoad(id: 'l2', sequence: 2, status: JobWorkStatus.ready),
        ],
      );
      expect(can, isTrue);
    });
  });

  group('canGenerateInvoiceForLoad + financeStatusForLoad', () {
    test('allows ready load with charges', () {
      expect(
        JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(
          buildLoad(id: 'l1', status: JobWorkStatus.ready),
        ),
        isTrue,
      );
    });

    test('allows early stage load with charges', () {
      expect(
        JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(
          buildLoad(
            id: 'l1',
            status: JobWorkStatus.agreed,
            finalCuttingCharges: 1500,
          ),
        ),
        isTrue,
      );
    });

    test('allows collected load with charges', () {
      expect(
        JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(
          buildLoad(
            id: 'l1',
            status: JobWorkStatus.collected,
            finalCuttingCharges: 1500,
          ),
        ),
        isTrue,
      );
    });

    test('allows closed load with charges', () {
      expect(
        JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(
          buildLoad(
            id: 'l1',
            status: JobWorkStatus.closed,
            finalCuttingCharges: 1500,
          ),
        ),
        isTrue,
      );
    });

    test('blocks cancelled load', () {
      expect(
        JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(
          buildLoad(id: 'l1', status: JobWorkStatus.cancelled),
        ),
        isFalse,
      );
    });

    test('blocks when charges are zero', () {
      expect(
        JobWorkContainerSyncHelper.canGenerateInvoiceForLoad(
          buildLoad(
            id: 'l1',
            status: JobWorkStatus.ready,
            finalCuttingCharges: 0,
            balanceDue: 0,
          ),
        ),
        isFalse,
      );
    });

    test('finance status becomes paid when due is zero', () {
      final status = JobWorkContainerSyncHelper.financeStatusForLoad(
        load: buildLoad(id: 'l1', status: JobWorkStatus.invoiced),
        dueAmount: 0,
      );
      expect(status, JobWorkStatus.paid);
    });

    test('finance status does not clobber partially collected', () {
      final status = JobWorkContainerSyncHelper.financeStatusForLoad(
        load: buildLoad(
          id: 'l1',
          status: JobWorkStatus.partiallyCollected,
        ),
        dueAmount: 0,
      );
      expect(status, isNull);
    });

    test('finance status does not clobber collected', () {
      final status = JobWorkContainerSyncHelper.financeStatusForLoad(
        load: buildLoad(
          id: 'l1',
          status: JobWorkStatus.collected,
        ),
        dueAmount: 500,
      );
      expect(status, isNull);
    });


    test('finance status sets invoiced from ready', () {
      final status = JobWorkContainerSyncHelper.financeStatusForLoad(
        load: buildLoad(id: 'l1', status: JobWorkStatus.ready),
        dueAmount: 500,
      );
      expect(status, JobWorkStatus.invoiced);
    });
  });

  group('calculatePerLoadFinanceMap with line-item extraction', () {
    test('extracts per-load paid amounts from grand invoice line items', () {
      final order = buildOrder();
      final load1 = buildLoad(
        id: 'l1',
        sequence: 1,
        finalCuttingCharges: 1318691.64,
        advanceReceived: 0.0,
      );
      final load2 = buildLoad(
        id: 'l2',
        sequence: 2,
        finalCuttingCharges: 1361893.71,
        advanceReceived: 0.0,
      );
      final load3 = buildLoad(
        id: 'l3',
        sequence: 3,
        finalCuttingCharges: 29581.14,
        advanceReceived: 0.0,
      );

      final grandInvoice = JobWorkInvoice(
        id: 'inv-grand',
        invoiceNumber: 'JWI-2026-0002',
        factoryId: 'factory-1',
        jobWorkId: order.id,
        jobWorkNumber: order.jobWorkNumber,
        customerId: order.customerId,
        customerName: order.customerName,
        lineItems: const [
          InvoiceLineItem(
            description: 'JWL-2026-0001 · Total: Rs 1318692 · Paid: Rs 100000 · Remaining: Rs 1218692',
            amount: 1318691.64,
          ),
          InvoiceLineItem(
            description: 'JWL-2026-0002 · Total: Rs 1361894 · Paid: Rs 1361894 · Remaining: Rs 0',
            amount: 1361893.71,
          ),
          InvoiceLineItem(
            description: 'JWL-2026-0003 · Total: Rs 29581 · Paid: Rs 0 · Remaining: Rs 29581',
            amount: 29581.14,
          ),
        ],
        totalAmount: 2710166.49,
        paidAmount: 1461893.71,
        dueAmount: 1248272.78,
        status: InvoiceStatus.partial,
        createdAt: DateTime(2026, 1, 1),
      );

      final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
        order: order,
        loads: [load1, load2, load3],
        invoices: [grandInvoice],
      );

      // Load 1: Paid Rs 100,000 from line items
      expect(financeMap['l1']?.paid, closeTo(100000.0, 1.0));
      expect(financeMap['l1']?.due, closeTo(1218691.64, 1.0));

      // Load 2: Fully paid (Rs 1,361,894) from line items
      expect(financeMap['l2']?.paid, closeTo(1361893.71, 1.0));
      expect(financeMap['l2']?.due, closeTo(0.0, 1.0));

      // Load 3: Unpaid (Rs 0) from line items
      expect(financeMap['l3']?.paid, closeTo(0.0, 1.0));
      expect(financeMap['l3']?.due, closeTo(29581.14, 1.0));
    });
  });

  group('rollupInvoiceFinance grand invoice attribution', () {
    test('counts a shared grand invoice once across four loads', () {
      final order = buildOrder(invoiceId: 'grand-1');
      final loads = [
        buildLoad(id: 'l1', sequence: 1, finalCuttingCharges: 190491)
            .copyWith(invoiceId: 'grand-1'),
        buildLoad(id: 'l2', sequence: 2, finalCuttingCharges: 112200),
        buildLoad(id: 'l3', sequence: 3, finalCuttingCharges: 119500),
        buildLoad(id: 'l4', sequence: 4, finalCuttingCharges: 124500),
      ];
      final grandInvoice = JobWorkInvoice(
        id: 'grand-1',
        invoiceNumber: 'JWI-2026-0001',
        factoryId: 'factory-1',
        jobWorkId: order.id,
        jobWorkNumber: order.jobWorkNumber,
        customerId: order.customerId,
        customerName: order.customerName,
        // Legacy defect: this grand invoice is incorrectly stamped as l1.
        loadId: 'l1',
        loadNumber: 'JWL-1',
        lineItems: const [
          InvoiceLineItem(
            description: 'JWL-1 · Total: Rs 190491',
            amount: 190491,
          ),
          InvoiceLineItem(
            description: 'JWL-2 · Total: Rs 112200',
            amount: 112200,
          ),
          InvoiceLineItem(
            description: 'JWL-3 · Total: Rs 119500',
            amount: 119500,
          ),
          InvoiceLineItem(
            description: 'JWL-4 · Total: Rs 124500',
            amount: 124500,
          ),
        ],
        totalAmount: 546691,
        // Simulate the production defect: denormalized invoice finance is stale,
        // while the authoritative payment collection contains Rs 500,000.
        paidAmount: 0,
        dueAmount: 546691,
        status: InvoiceStatus.partial,
        createdAt: DateTime(2026, 8, 12),
      );

      final finance = JobWorkContainerSyncHelper.rollupInvoiceFinance(
        order: order,
        loads: loads,
        invoices: [grandInvoice],
        payments: [
          Payment(
            id: 'payment-1',
            factoryId: 'factory-1',
            customerId: order.customerId,
            customerName: order.customerName,
            invoiceId: grandInvoice.id,
            invoiceType: InvoiceType.jobWork,
            invoiceNumber: grandInvoice.invoiceNumber,
            amount: 500000,
            method: PaymentMethod.cash,
            paymentDate: DateTime(2026, 8, 12),
            createdAt: DateTime(2026, 8, 12),
          ),
        ],
      );

      expect(finance.charges, 546691);
      expect(finance.paid, 500000);
      expect(finance.due, 46691);

      final beforePaymentStream =
          JobWorkContainerSyncHelper.rollupInvoiceFinance(
        order: order,
        loads: loads,
        invoices: [
          grandInvoice.copyWith(
            paidAmount: 500000,
            dueAmount: 46691,
          ),
        ],
      );
      expect(beforePaymentStream.charges, 546691);
      expect(beforePaymentStream.paid, 500000);
      expect(beforePaymentStream.due, 46691);
    });
  });

  group('In Credit calculation with excess advance payments', () {
    test('accurately calculates in credit balance per load and for container', () {
      final order = buildOrder(finalCuttingCharges: 181884.56, advanceReceived: 450000);
      final load1 = buildLoad(
        id: 'load-1',
        sequence: 1,
        finalCuttingCharges: 106989.0,
        advanceReceived: 300000.0,
      );
      final load2 = buildLoad(
        id: 'load-2',
        sequence: 2,
        finalCuttingCharges: 74895.0,
        advanceReceived: 150000.0,
      );

      final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
        order: order,
        loads: [load1, load2],
        invoices: [],
      );

      // Load 1: 300k advance, 106,989 charges -> Paid: 106989, Due: 0, Credit: 193011
      expect(financeMap['load-1']?.charges, closeTo(106989.0, 0.01));
      expect(financeMap['load-1']?.paid, closeTo(106989.0, 0.01));
      expect(financeMap['load-1']?.due, closeTo(0.0, 0.01));
      expect(financeMap['load-1']?.credit, closeTo(193011.0, 0.01));

      // Load 2: 150k advance, 74,895 charges -> Paid: 74895, Due: 0, Credit: 75105
      expect(financeMap['load-2']?.charges, closeTo(74895.0, 0.01));
      expect(financeMap['load-2']?.paid, closeTo(74895.0, 0.01));
      expect(financeMap['load-2']?.due, closeTo(0.0, 0.01));
      expect(financeMap['load-2']?.credit, closeTo(75105.0, 0.01));

      // Order rollup: 450k advance, 181,884 charges -> Charges: 181884, Paid: 450000, Due: 0, Credit: 268116
      final rollup = JobWorkContainerSyncHelper.rollupInvoiceFinance(
        order: order,
        loads: [load1, load2],
        invoices: [],
      );

      expect(rollup.charges, closeTo(181884.0, 1.0));
      expect(rollup.paid, closeTo(450000.0, 0.01));
      expect(rollup.due, closeTo(0.0, 0.01));
      expect(rollup.credit, closeTo(268116.0, 1.0));
    });

    test('accurately calculates finance when grand invoice exists with payments ledger', () {
      final order = buildOrder(finalCuttingCharges: 181884.56, advanceReceived: 450000);
      final load1 = buildLoad(
        id: 'load-1',
        sequence: 1,
        finalCuttingCharges: 106989.0,
        advanceReceived: 300000.0,
      );
      final load2 = buildLoad(
        id: 'load-2',
        sequence: 2,
        finalCuttingCharges: 74895.0,
        advanceReceived: 150000.0,
      );
      final grandInvoice = JobWorkInvoice(
        id: 'grand-inv',
        invoiceNumber: 'INV-001',
        jobWorkNumber: 'JW-2026-0001',
        factoryId: 'factory-1',
        jobWorkId: 'jw-1',
        customerId: 'customer-1',
        customerName: 'Basir',
        lineItems: [
          const InvoiceLineItem(
            description: 'Load #1 · Total: Rs 106989 · Paid: Rs 0 · Remaining: Rs 106989',
            amount: 106989,
          ),
          const InvoiceLineItem(
            description: 'Load #2 · Total: Rs 74895 · Paid: Rs 0 · Remaining: Rs 74895',
            amount: 74895,
          ),
        ],
        totalAmount: 181884.56,
        paidAmount: 450000.0,
        dueAmount: 0.0,
        status: InvoiceStatus.paid,
        createdAt: DateTime(2026, 8, 19),
      );

      final payments = <Payment>[
        Payment(
          id: 'pay-1',
          factoryId: 'factory-1',
          customerId: 'customer-1',
          customerName: 'Basir',
          invoiceId: '',
          invoiceNumber: '',
          invoiceType: InvoiceType.jobWork,
          amount: 300000,
          method: PaymentMethod.cash,
          paymentDate: DateTime(2026, 8, 19),
          createdAt: DateTime(2026, 8, 19),
          isAdvance: true,
          orderId: 'jw-1',
          loadId: 'load-1',
        ),
        Payment(
          id: 'pay-2',
          factoryId: 'factory-1',
          customerId: 'customer-1',
          customerName: 'Basir',
          invoiceId: '',
          invoiceNumber: '',
          invoiceType: InvoiceType.jobWork,
          amount: 150000,
          method: PaymentMethod.cash,
          paymentDate: DateTime(2026, 8, 19),
          createdAt: DateTime(2026, 8, 19),
          isAdvance: true,
          orderId: 'jw-1',
          loadId: 'load-2',
        ),
      ];

      final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
        order: order,
        loads: [load1, load2],
        invoices: [grandInvoice],
        payments: payments,
      );

      expect(financeMap['load-1']?.charges, closeTo(106989.0, 0.01));
      expect(financeMap['load-1']?.paid, closeTo(106989.0, 0.01));
      expect(financeMap['load-1']?.due, closeTo(0.0, 0.01));
      expect(financeMap['load-1']?.credit, closeTo(193011.0, 0.01));

      expect(financeMap['load-2']?.charges, closeTo(74895.0, 0.01));
      expect(financeMap['load-2']?.paid, closeTo(74895.0, 0.01));
      expect(financeMap['load-2']?.due, closeTo(0.0, 0.01));
      expect(financeMap['load-2']?.credit, closeTo(75105.0, 0.01));
    });

    test('ignores Paid: Rs 0 in line items when fallback advanceReceived is present', () {
      final order = buildOrder(finalCuttingCharges: 181884.56, advanceReceived: 450000);
      final load1 = buildLoad(
        id: 'load-1',
        sequence: 1,
        finalCuttingCharges: 106989.0,
        advanceReceived: 300000.0,
      );
      final load2 = buildLoad(
        id: 'load-2',
        sequence: 2,
        finalCuttingCharges: 74895.0,
        advanceReceived: 150000.0,
      );
      final grandInvoice = JobWorkInvoice(
        id: 'grand-inv',
        invoiceNumber: 'INV-001',
        jobWorkNumber: 'JW-2026-0001',
        factoryId: 'factory-1',
        jobWorkId: 'jw-1',
        customerId: 'customer-1',
        customerName: 'Basir',
        lineItems: [
          const InvoiceLineItem(
            description: 'Load #1 · Total: Rs 106989 · Paid: Rs 0 · Remaining: Rs 106989',
            amount: 106989,
          ),
          const InvoiceLineItem(
            description: 'Load #2 · Total: Rs 74895 · Paid: Rs 0 · Remaining: Rs 74895',
            amount: 74895,
          ),
        ],
        totalAmount: 181884.56,
        paidAmount: 450000.0,
        dueAmount: 0.0,
        status: InvoiceStatus.paid,
        createdAt: DateTime(2026, 8, 19),
      );

      final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
        order: order,
        loads: [load1, load2],
        invoices: [grandInvoice],
        payments: [], // without payments stream loaded yet
      );

      expect(financeMap['load-1']?.paid, closeTo(106989.0, 0.01));
      expect(financeMap['load-1']?.due, closeTo(0.0, 0.01));
      expect(financeMap['load-1']?.credit, closeTo(193011.0, 0.01));

      expect(financeMap['load-2']?.paid, closeTo(74895.0, 0.01));
      expect(financeMap['load-2']?.due, closeTo(0.0, 0.01));
      expect(financeMap['load-2']?.credit, closeTo(75105.0, 0.01));
    });

    test('grand-invoice overpay with loadId settles remaining after advance', () {
      final order = buildOrder(
        finalCuttingCharges: 153504,
        advanceReceived: 103504,
      );
      final load = buildLoad(
        id: 'load-1',
        sequence: 1,
        finalCuttingCharges: 153504,
        advanceReceived: 103504,
        balanceDue: 50000,
      );
      final loadInvoice = JobWorkInvoice(
        id: 'inv-load',
        invoiceNumber: 'INV-L1',
        jobWorkNumber: 'JW-2026-0001',
        factoryId: 'factory-1',
        jobWorkId: 'jw-1',
        loadId: 'load-1',
        customerId: 'customer-1',
        customerName: 'Deen Muhammad',
        lineItems: const [
          InvoiceLineItem(description: 'Cutting', amount: 153504),
        ],
        totalAmount: 153504,
        paidAmount: 103504,
        dueAmount: 50000,
        status: InvoiceStatus.partial,
        createdAt: DateTime(2026, 8, 31),
      );
      final payments = [
        Payment(
          id: 'advance-1',
          factoryId: 'factory-1',
          customerId: 'customer-1',
          customerName: 'Deen Muhammad',
          invoiceId: 'inv-load',
          invoiceNumber: 'INV-L1',
          invoiceType: InvoiceType.jobWork,
          amount: 103504,
          appliedAmount: 103504,
          method: PaymentMethod.cash,
          paymentDate: DateTime(2026, 8, 1),
          createdAt: DateTime(2026, 8, 1),
          isAdvance: true,
          orderId: 'jw-1',
          loadId: 'load-1',
        ),
        Payment(
          id: 'overpay-1',
          factoryId: 'factory-1',
          customerId: 'customer-1',
          customerName: 'Deen Muhammad',
          invoiceId: 'inv-grand',
          invoiceNumber: 'INV-G',
          invoiceType: InvoiceType.jobWork,
          amount: 300000,
          appliedAmount: 50000,
          method: PaymentMethod.cash,
          paymentDate: DateTime(2026, 8, 31),
          createdAt: DateTime(2026, 8, 31),
          orderId: 'jw-1',
          loadId: 'load-1',
        ),
      ];

      final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
        order: order,
        loads: [load],
        invoices: [loadInvoice],
        payments: payments,
      );
      expect(financeMap['load-1']?.charges, closeTo(153504, 0.01));
      expect(financeMap['load-1']?.paid, closeTo(153504, 0.01));
      expect(financeMap['load-1']?.due, closeTo(0, 0.01));

      final rollup = JobWorkContainerSyncHelper.rollupInvoiceFinance(
        order: order,
        loads: [load],
        invoices: [loadInvoice],
        payments: payments,
      );
      expect(rollup.paid, closeTo(153504, 0.01));
      expect(rollup.due, closeTo(0, 0.01));
    });

    test('screenshot case: 50k advance, 103504 paid, 300k overpay on order invoice', () {
      final order = buildOrder(
        finalCuttingCharges: 153504,
        advanceReceived: 50000,
        invoiceId: 'inv-order',
      );
      final load = buildLoad(
        id: 'load-1',
        sequence: 1,
        finalCuttingCharges: 153504,
        advanceReceived: 50000,
        balanceDue: 50000,
      ).copyWith(invoiceId: 'inv-load');
      final loadInvoice = JobWorkInvoice(
        id: 'inv-load',
        invoiceNumber: 'INV-L1',
        jobWorkNumber: 'JW-2026-0001',
        factoryId: 'factory-1',
        jobWorkId: 'jw-1',
        loadId: 'load-1',
        customerId: 'customer-1',
        customerName: 'Deen Muhammad',
        lineItems: const [
          InvoiceLineItem(description: 'Cutting', amount: 153504),
        ],
        totalAmount: 153504,
        paidAmount: 103504,
        dueAmount: 50000,
        status: InvoiceStatus.partial,
        createdAt: DateTime(2026, 8, 31),
      );
      Payment payment({
        required String id,
        required String invoiceId,
        required double amount,
        double? appliedAmount,
        String? orderId,
        String? loadId,
      }) {
        return Payment(
          id: id,
          factoryId: 'factory-1',
          customerId: 'customer-1',
          customerName: 'Deen Muhammad',
          invoiceId: invoiceId,
          invoiceNumber: invoiceId == 'inv-order' ? 'INV-JW' : 'INV-L1',
          invoiceType: InvoiceType.jobWork,
          amount: amount,
          appliedAmount: appliedAmount,
          method: PaymentMethod.cash,
          paymentDate: DateTime(2026, 8, 1),
          createdAt: DateTime(2026, 8, 1),
          orderId: orderId,
          loadId: loadId,
        );
      }

      final prior = [
        payment(
          id: 'advance-1',
          invoiceId: 'inv-load',
          amount: 50000,
          appliedAmount: 50000,
          orderId: 'jw-1',
          loadId: 'load-1',
        ),
        payment(
          id: 'partial-1',
          invoiceId: 'inv-load',
          amount: 53504,
          appliedAmount: 53504,
          orderId: 'jw-1',
          loadId: 'load-1',
        ),
      ];

      void expectSettled(List<Payment> payments) {
        final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
          order: order,
          loads: [load],
          invoices: [loadInvoice],
          payments: payments,
        );
        expect(financeMap['load-1']?.paid, closeTo(153504, 0.01));
        expect(financeMap['load-1']?.due, closeTo(0, 0.01));

        final rollup = JobWorkContainerSyncHelper.rollupInvoiceFinance(
          order: order,
          loads: [load],
          invoices: [loadInvoice],
          payments: payments,
        );
        expect(rollup.paid, closeTo(153504, 0.01));
        expect(rollup.due, closeTo(0, 0.01));
      }

      expectSettled([
        ...prior,
        payment(
          id: 'overpay-linked',
          invoiceId: 'inv-order',
          amount: 300000,
          appliedAmount: 50000,
        ),
      ]);

      expectSettled([
        ...prior,
        payment(
          id: 'overpay-unapplied',
          invoiceId: 'inv-order',
          amount: 300000,
          appliedAmount: 0,
        ),
      ]);
    });

    test('remainingDueForPayment uses the side that still has due', () {
      final invoice = JobWorkInvoice(
        id: 'inv-1',
        invoiceNumber: 'INV-1',
        jobWorkNumber: 'JW-2026-0001',
        factoryId: 'factory-1',
        jobWorkId: 'jw-1',
        loadId: 'load-1',
        customerId: 'customer-1',
        customerName: 'Deen Muhammad',
        lineItems: const [
          InvoiceLineItem(description: 'Cutting', amount: 153504),
        ],
        totalAmount: 153504,
        paidAmount: 153504,
        dueAmount: 0,
        status: InvoiceStatus.paid,
        createdAt: DateTime(2026, 8, 31),
      );
      final load = buildLoad(
        id: 'load-1',
        finalCuttingCharges: 153504,
        advanceReceived: 50000,
        balanceDue: 50000,
      );
      expect(
        JobWorkContainerSyncHelper.remainingDueForPayment(
          invoice: invoice,
          load: load,
        ),
        closeTo(50000, 0.01),
      );
    });

    test('200k advance + 800k overpay settles 726804 job and keeps credit off the job', () {
      final order = buildOrder(
        finalCuttingCharges: 726804,
        advanceReceived: 200000,
        invoiceId: '',
      );
      final load = buildLoad(
        id: 'load-8',
        sequence: 8,
        finalCuttingCharges: 726804,
        advanceReceived: 200000,
        balanceDue: 526804,
      ).copyWith(loadNumber: 'JWL-2026-0008');
      final payments = [
        Payment(
          id: 'advance-200k',
          factoryId: 'factory-1',
          customerId: 'customer-1',
          customerName: 'JK Test',
          invoiceId: 'inv-load',
          invoiceNumber: 'JWL-2026-0008',
          invoiceType: InvoiceType.jobWork,
          amount: 200000,
          appliedAmount: 200000,
          method: PaymentMethod.cash,
          paymentDate: DateTime(2026, 8, 28),
          createdAt: DateTime(2026, 8, 28),
          orderId: 'jw-1',
          loadId: 'load-8',
          isAdvance: true,
        ),
        Payment(
          id: 'overpay-800k',
          factoryId: 'factory-1',
          customerId: 'customer-1',
          customerName: 'JK Test',
          invoiceId: 'deleted-invoice',
          invoiceNumber: '',
          invoiceType: InvoiceType.jobWork,
          amount: 800000,
          appliedAmount: 526804,
          method: PaymentMethod.cash,
          paymentDate: DateTime(2026, 8, 31),
          createdAt: DateTime(2026, 8, 31),
        ),
      ];

      final dangling = JobWorkContainerSyncHelper.relevantPaymentsForJobWork(
        order: order,
        loads: [load],
        invoices: const [],
        payments: payments,
        attachDanglingCustomerPayments: true,
      );
      expect(dangling.map((p) => p.id), containsAll(['advance-200k', 'overpay-800k']));

      final rollup = JobWorkContainerSyncHelper.rollupInvoiceFinance(
        order: order,
        loads: [load],
        invoices: const [],
        payments: payments,
        alreadyScoped: true,
      );
      expect(rollup.charges, closeTo(726804, 0.01));
      expect(rollup.paid, closeTo(726804, 0.01));
      expect(rollup.due, closeTo(0, 0.01));
      expect(rollup.credit, closeTo(0, 0.01));
      expect(Payment.unallocatedTotal(payments), closeTo(273196, 0.01));

      final financeMap = JobWorkContainerSyncHelper.calculatePerLoadFinanceMap(
        order: order,
        loads: [load],
        invoices: const [],
        payments: payments,
        alreadyScoped: true,
      );
      expect(financeMap['load-8']?.paid, closeTo(726804, 0.01));
      expect(financeMap['load-8']?.due, closeTo(0, 0.01));
    });
  });
}
