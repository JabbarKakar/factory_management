import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';

class CustomerLedgerService {
  CustomerLedgerService({
    required CustomerRepository customerRepository,
    required JobWorkInvoiceRepository jobWorkInvoiceRepository,
    required SalesInvoiceRepository salesInvoiceRepository,
  })  : _customerRepository = customerRepository,
        _jobWorkInvoiceRepository = jobWorkInvoiceRepository,
        _salesInvoiceRepository = salesInvoiceRepository;

  final CustomerRepository _customerRepository;
  final JobWorkInvoiceRepository _jobWorkInvoiceRepository;
  final SalesInvoiceRepository _salesInvoiceRepository;

  Future<void> syncCustomerBalance(String customerId) async {
    final customer = await _customerRepository.getCustomer(customerId);
    if (customer == null) return;

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

    final openDue = jobWorkInvoices
            .where((invoice) => invoice.dueAmount > 0)
            .fold<double>(0, (sum, invoice) => sum + invoice.dueAmount) +
        salesInvoices
            .where((invoice) => invoice.dueAmount > 0)
            .fold<double>(0, (sum, invoice) => sum + invoice.dueAmount);

    DateTime? nextDueDate;
    for (final invoice in jobWorkInvoices) {
      if (invoice.dueAmount <= 0 || invoice.dueDate == null) continue;
      final due = invoice.dueDate!;
      if (nextDueDate == null || due.isBefore(nextDueDate)) {
        nextDueDate = due;
      }
    }
    for (final invoice in salesInvoices) {
      if (invoice.dueAmount <= 0 || invoice.dueDate == null) continue;
      final due = invoice.dueDate!;
      if (nextDueDate == null || due.isBefore(nextDueDate)) {
        nextDueDate = due;
      }
    }

    await _customerRepository.updateCustomer(
      customer.copyWith(
        balance: customer.openingBalance + openDue,
        nextDueDate: nextDueDate,
      ),
    );
  }
}
