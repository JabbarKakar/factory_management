import 'package:flutter_test/flutter_test.dart';
import 'package:factory_management/blocs/job_work/job_work_invoice_bloc.dart';
import 'package:factory_management/data/repositories/job_work_invoice_repository.dart';
import 'package:factory_management/data/repositories/job_work_load_repository.dart';
import 'package:factory_management/data/repositories/job_work_repository.dart';
import 'package:factory_management/data/repositories/payment_repository.dart';
import 'package:factory_management/data/services/customer_ledger_service.dart';
import 'package:factory_management/data/services/payment_due_scanner_service.dart';
import 'package:factory_management/domain/entities/job_work_invoice.dart';
import 'package:factory_management/domain/entities/job_work_load.dart';
import 'package:factory_management/domain/entities/job_work_order.dart';
import 'package:factory_management/domain/entities/payment.dart';
import 'package:factory_management/domain/enums/customer_enums.dart';
import 'package:factory_management/domain/enums/invoice_enums.dart';
import 'package:factory_management/domain/enums/job_work_enums.dart';

class _FakeJobWorkInvoiceRepository implements JobWorkInvoiceRepository {
  JobWorkInvoice? invoiceToReturn;
  List<JobWorkInvoice> invoicesByJobWork = [];

  @override
  Stream<JobWorkInvoice?> watchInvoice(String id) =>
      Stream.value(invoiceToReturn);

  @override
  Stream<List<JobWorkInvoice>> watchInvoicesByJobWorkId({
    required String factoryId,
    required String jobWorkId,
  }) =>
      Stream.value(invoicesByJobWork);

  @override
  Future<JobWorkInvoice?> getInvoice(String id) async => invoiceToReturn;

  @override
  Future<List<JobWorkInvoice>> getInvoicesByJobWorkId({
    required String factoryId,
    required String jobWorkId,
  }) async =>
      invoicesByJobWork;

  @override
  Future<JobWorkInvoice?> syncGrandInvoice({
    required String factoryId,
    required String jobWorkId,
  }) async =>
      invoiceToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentRepository implements PaymentRepository {
  String? recordedLoadId;
  double? recordedAmount;
  String? recordedInvoiceId;

  @override
  Future<Payment> recordJobWorkPayment({
    required String invoiceId,
    required double amount,
    required PaymentMethod method,
    required DateTime paymentDate,
    String? loadId,
    String? idempotencyKey,
    String? reference,
    String? notes,
  }) async {
    recordedInvoiceId = invoiceId;
    recordedAmount = amount;
    recordedLoadId = loadId;
    return Payment(
      id: 'p1',
      factoryId: 'f1',
      customerId: 'c1',
      customerName: 'Customer 1',
      invoiceId: invoiceId,
      invoiceType: InvoiceType.jobWork,
      invoiceNumber: 'INV-001',
      amount: amount,
      method: method,
      paymentDate: paymentDate,
      orderId: 'jw1',
      loadId: loadId,
      createdAt: DateTime.now(),
    );
  }

  @override
  Stream<List<Payment>> watchPaymentsForInvoice({
    required String factoryId,
    required String invoiceId,
  }) =>
      Stream.value(const []);

  @override
  Future<void> ensureInvoicePaidAmountRecorded({
    required String invoiceId,
    required InvoiceType invoiceType,
  }) async {}

  @override
  Future<List<Payment>> getPaymentsForInvoice({
    required String factoryId,
    required String invoiceId,
  }) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeJobWorkLoadRepository implements JobWorkLoadRepository {
  List<JobWorkLoad> loads = [];

  @override
  Future<List<JobWorkLoad>> fetchLoadsForJobWork({
    required String factoryId,
    required String jobWorkId,
  }) async =>
      loads;

  @override
  Stream<List<JobWorkLoad>> watchLoadsForJobWork({
    required String factoryId,
    required String jobWorkId,
  }) =>
      Stream.value(loads);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeJobWorkRepository implements JobWorkRepository {
  JobWorkOrder? order;

  @override
  Future<JobWorkOrder?> getJobWorkOrder(String id) async => order;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCustomerLedgerService implements CustomerLedgerService {
  @override
  Future<void> syncCustomerBalance(String customerId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePaymentDueScannerService implements PaymentDueScannerService {
  @override
  Future<int> scan(String factoryId) async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeJobWorkInvoiceRepository invoiceRepo;
  late _FakePaymentRepository paymentRepo;
  late _FakeJobWorkLoadRepository loadRepo;
  late _FakeJobWorkRepository jobWorkRepo;
  late _FakeCustomerLedgerService ledgerService;
  late _FakePaymentDueScannerService scannerService;
  late JobWorkInvoiceBloc bloc;

  final testDate = DateTime(2026, 8, 20);

  JobWorkOrder buildOrder({
    required String id,
    double finalCuttingCharges = 0,
    double advanceReceived = 0,
    double balanceDue = 0,
  }) {
    return JobWorkOrder(
      id: id,
      jobWorkNumber: 'JW-001',
      factoryId: 'f1',
      customerId: 'c1',
      customerName: 'Test Customer',
      status: JobWorkStatus.invoiced,
      receivedDate: testDate,
      marbleVariety: 'Ziarat White',
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
      createdAt: testDate,
    );
  }

  JobWorkLoad buildLoad({
    required String id,
    int sequence = 1,
    double finalCuttingCharges = 1000,
    double advanceReceived = 0,
    double balanceDue = 1000,
  }) {
    return JobWorkLoad.fromLegacyOrder(
      buildOrder(id: 'jw1'),
      id: id,
      loadNumber: 'LOAD-0$sequence',
      loadSequence: sequence,
    ).copyWith(
      status: JobWorkStatus.invoiced,
      finalCuttingCharges: finalCuttingCharges,
      advanceReceived: advanceReceived,
      balanceDue: balanceDue,
    );
  }

  setUp(() {
    invoiceRepo = _FakeJobWorkInvoiceRepository();
    paymentRepo = _FakePaymentRepository();
    loadRepo = _FakeJobWorkLoadRepository();
    jobWorkRepo = _FakeJobWorkRepository();
    ledgerService = _FakeCustomerLedgerService();
    scannerService = _FakePaymentDueScannerService();

    bloc = JobWorkInvoiceBloc(
      invoiceRepository: invoiceRepo,
      paymentRepository: paymentRepo,
      ledgerService: ledgerService,
      scannerService: scannerService,
      loadRepository: loadRepo,
      jobWorkRepository: jobWorkRepo,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('passes loadId when recording payment on a grand invoice', () async {
    final invoice = JobWorkInvoice(
      id: 'inv_grand',
      invoiceNumber: 'INV-GRAND-01',
      factoryId: 'f1',
      customerId: 'c1',
      customerName: 'Test Customer',
      jobWorkId: 'jw1',
      jobWorkNumber: 'JW-001',
      loadId: null, // Grand invoice
      totalAmount: 500000,
      paidAmount: 100000,
      dueAmount: 400000,
      status: InvoiceStatus.partial,
      lineItems: const [],
      createdAt: testDate,
    );

    invoiceRepo.invoiceToReturn = invoice;
    invoiceRepo.invoicesByJobWork = [invoice];

    loadRepo.loads = [
      buildLoad(
        id: 'load_1',
        sequence: 1,
        finalCuttingCharges: 300000,
        advanceReceived: 100000,
        balanceDue: 200000,
      ),
      buildLoad(
        id: 'load_2',
        sequence: 2,
        finalCuttingCharges: 200000,
        advanceReceived: 0,
        balanceDue: 200000,
      ),
    ];

    jobWorkRepo.order = buildOrder(
      id: 'jw1',
      finalCuttingCharges: 500000,
      advanceReceived: 100000,
      balanceDue: 400000,
    );

    // 1. Load invoice by ID
    bloc.add(const JobWorkInvoiceLoadById('inv_grand'));
    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<JobWorkInvoiceState>(
          (s) =>
              s.status == JobWorkInvoiceStatus.loaded &&
              s.loads.length == 2 &&
              s.perLoadFinance.containsKey('load_1') &&
              s.perLoadFinance.containsKey('load_2'),
        ),
      ),
    );

    // 2. Submit payment allocated to Load 2
    bloc.add(
      JobWorkInvoicePaymentSubmitted(
        invoiceId: 'inv_grand',
        amount: 150000,
        method: PaymentMethod.cash,
        paymentDate: testDate,
        loadId: 'load_2',
      ),
    );

    await expectLater(
      bloc.stream,
      emitsThrough(
        predicate<JobWorkInvoiceState>(
          (s) => s.status == JobWorkInvoiceStatus.paymentRecorded,
        ),
      ),
    );

    // Verify PaymentRepository was called with the loadId
    expect(paymentRepo.recordedInvoiceId, equals('inv_grand'));
    expect(paymentRepo.recordedAmount, equals(150000));
    expect(paymentRepo.recordedLoadId, equals('load_2'));
  });
}
