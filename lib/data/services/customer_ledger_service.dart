import '../../core/di/injection.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_load_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../domain/entities/job_work_load.dart';
import '../../domain/entities/job_work_order.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_order.dart';
import 'customer_balance_calculator.dart';

class CustomerLedgerService {
  CustomerLedgerService({
    required CustomerRepository customerRepository,
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
    JobWorkRepository? jobWorkRepository,
    JobWorkLoadRepository? jobWorkLoadRepository,
    SalesOrderRepository? salesOrderRepository,
    PaymentRepository? paymentRepository,
  })  : _customerRepository = customerRepository,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _jobWorkRepository = jobWorkRepository,
        _jobWorkLoadRepository = jobWorkLoadRepository,
        _salesOrderRepository = salesOrderRepository,
        _paymentRepository = paymentRepository;

  final CustomerRepository _customerRepository;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final JobWorkRepository? _jobWorkRepository;
  final JobWorkLoadRepository? _jobWorkLoadRepository;
  final SalesOrderRepository? _salesOrderRepository;
  final PaymentRepository? _paymentRepository;

  PaymentRepository? get _effectivePaymentRepository {
    if (_paymentRepository != null) return _paymentRepository;
    if (getIt.isRegistered<PaymentRepository>()) {
      return getIt<PaymentRepository>();
    }
    return null;
  }

  Future<void> syncCustomerBalance(String customerId) async {
    final customer = await _customerRepository.getCustomer(customerId);
    if (customer == null) return;

    final factoryId = customer.factoryId;

    final List<SalesOrder> salesOrders = _salesOrderRepository != null
        ? await _salesOrderRepository!.watchSalesOrders(factoryId).first
        : const [];
    final salesInvoices =
        await _salesInvoiceRepository.getInvoicesForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    );

    final List<JobWorkOrder> jobWorkOrders = _jobWorkRepository != null
        ? await _jobWorkRepository!.watchOrdersForCustomer(customerId).first
        : const [];
    final List<JobWorkLoad> jobWorkLoads = _jobWorkLoadRepository != null
        ? await _jobWorkLoadRepository!.watchLoads(factoryId).first
        : const [];
    final jobWorkInvoices =
        await _jobWorkInvoiceRepository.getInvoicesForCustomer(
      factoryId: factoryId,
      customerId: customerId,
    );

    final paymentRepo = _effectivePaymentRepository;
    final List<Payment> payments = paymentRepo != null
        ? await paymentRepo.getPaymentsForCustomer(
            factoryId: factoryId,
            customerId: customerId,
          )
        : const [];

    final summary = CustomerBalanceCalculator.calculateCustomerSummary(
      customer: customer,
      salesOrders: salesOrders,
      salesInvoices: salesInvoices,
      jobWorkOrders: jobWorkOrders,
      jobWorkLoads: jobWorkLoads,
      jobWorkInvoices: jobWorkInvoices,
      payments: payments,
    );

    await _customerRepository.updateCustomer(
      customer.copyWith(
        balance: summary.totalDue,
        nextDueDate: summary.nextDueDate,
      ),
    );
  }
}
