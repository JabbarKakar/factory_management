import '../../core/constants/app_strings.dart';
import '../../domain/entities/customer_statement.dart';
import '../../domain/entities/job_work_invoice.dart';
import '../../domain/entities/payment.dart';
import '../../domain/entities/sales_invoice.dart';
import '../../domain/enums/invoice_enums.dart';
import '../repositories/customer_repository.dart';
import '../repositories/job_work_invoice_repository.dart';
import '../repositories/payment_repository.dart';
import '../repositories/sales_invoice_repository.dart';

class CustomerStatementService {
  CustomerStatementService({
    required CustomerRepository customerRepository,
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
    required PaymentRepository paymentRepository,
  })  : _customerRepository = customerRepository,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository,
        _paymentRepository = paymentRepository;

  final CustomerRepository _customerRepository;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;
  final PaymentRepository _paymentRepository;

  Future<CustomerStatement?> buildStatement({
    required String customerId,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final customer = await _customerRepository.getCustomer(customerId);
    if (customer == null) return null;

    final from = _startOfDay(fromDate);
    final to = _endOfDay(toDate);
    if (to.isBefore(from)) return null;

    final jobWorkInvoices =
        await _jobWorkInvoiceRepository.getInvoicesForCustomer(
      factoryId: customer.factoryId,
      customerId: customerId,
    );
    final salesInvoices =
        await _salesInvoiceRepository.getInvoicesForCustomer(
      factoryId: customer.factoryId,
      customerId: customerId,
    );
    final payments = await _paymentRepository.getPaymentsForCustomer(
      factoryId: customer.factoryId,
      customerId: customerId,
    );

    final transactions = <_StatementTxn>[
      ...jobWorkInvoices
          .where((invoice) => invoice.status != InvoiceStatus.cancelled)
          .map(_txnFromJobWorkInvoice),
      ...salesInvoices
          .where((invoice) => invoice.status != InvoiceStatus.cancelled)
          .map(_txnFromSalesInvoice),
      ...payments.map(_txnFromPayment),
    ]..sort((a, b) => a.date.compareTo(b.date));

    var openingBalance = customer.openingBalance;
    for (final txn in transactions) {
      if (txn.date.isBefore(from)) {
        openingBalance += txn.debit - txn.credit;
      }
    }

    final lines = <CustomerStatementLine>[];
    for (final txn in transactions) {
      if (txn.date.isBefore(from) || txn.date.isAfter(to)) continue;
      lines.add(
        CustomerStatementLine(
          date: txn.date,
          description: txn.description,
          reference: txn.reference,
          debit: txn.debit,
          credit: txn.credit,
        ),
      );
    }

    final closingBalance = openingBalance +
        lines.fold<double>(0, (sum, line) => sum + line.debit - line.credit);

    return CustomerStatement(
      customer: customer,
      fromDate: from,
      toDate: to,
      openingBalance: openingBalance,
      lines: lines,
      closingBalance: closingBalance,
    );
  }

  _StatementTxn _txnFromJobWorkInvoice(JobWorkInvoice invoice) {
    final refs = <String>[
      invoice.invoiceNumber,
      if (invoice.jobWorkNumber.isNotEmpty) invoice.jobWorkNumber,
      if (invoice.loadNumber != null && invoice.loadNumber!.trim().isNotEmpty)
        invoice.loadNumber!.trim(),
    ];
    return _StatementTxn(
      date: invoice.createdAt,
      description: AppStrings.invoiceTypeJobWork,
      reference: refs.join(' · '),
      debit: invoice.totalAmount,
      credit: 0,
    );
  }

  _StatementTxn _txnFromSalesInvoice(SalesInvoice invoice) {
    return _StatementTxn(
      date: invoice.createdAt,
      description: AppStrings.invoiceTypeSales,
      reference: invoice.invoiceNumber,
      debit: invoice.totalAmount,
      credit: 0,
    );
  }

  _StatementTxn _txnFromPayment(Payment payment) {
    return _StatementTxn(
      date: payment.paymentDate,
      description: AppStrings.paymentReceived,
      reference: payment.invoiceNumber,
      debit: 0,
      credit: payment.amount,
    );
  }

  DateTime _startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  DateTime _endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}

class _StatementTxn {
  const _StatementTxn({
    required this.date,
    required this.description,
    required this.reference,
    required this.debit,
    required this.credit,
  });

  final DateTime date;
  final String description;
  final String reference;
  final double debit;
  final double credit;
}
