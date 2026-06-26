import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';

class CustomerLedgerService {
  CustomerLedgerService({
    required CustomerRepository customerRepository,
    required JobWorkInvoiceRepository invoiceRepository,
  })  : _customerRepository = customerRepository,
        _invoiceRepository = invoiceRepository;

  final CustomerRepository _customerRepository;
  final JobWorkInvoiceRepository _invoiceRepository;

  Future<void> syncCustomerBalance(String customerId) async {
    final customer = await _customerRepository.getCustomer(customerId);
    if (customer == null) return;

    final invoices = await _invoiceRepository.getInvoicesForCustomer(customerId);
    final openDue = invoices
        .where((invoice) => invoice.dueAmount > 0)
        .fold<double>(0, (sum, invoice) => sum + invoice.dueAmount);

    DateTime? nextDueDate;
    for (final invoice in invoices) {
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
