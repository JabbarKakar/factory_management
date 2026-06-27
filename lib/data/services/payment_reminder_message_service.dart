import 'package:intl/intl.dart';

import '../../core/constants/app_strings.dart';
import '../../core/utils/formatters.dart';
import '../../domain/enums/invoice_enums.dart';

class PaymentReminderMessageService {
  String build({
    required String customerName,
    required String invoiceNumber,
    required double amountDue,
    required DateTime? dueDate,
    required InvoiceType invoiceType,
    String factoryName = AppStrings.appName,
    bool isOverdue = false,
  }) {
    final dateFormat = DateFormat.yMMMd();
    final amountLabel = Formatters.currencyForExport(amountDue);
    final invoiceLabel = invoiceType == InvoiceType.sales
        ? AppStrings.salesInvoice
        : AppStrings.jobWorkInvoice;

    final dueLine = dueDate == null
        ? ''
        : isOverdue
            ? '${AppStrings.paymentOverdueSince}: ${dateFormat.format(dueDate)}'
            : '${AppStrings.paymentDueDate}: ${dateFormat.format(dueDate)}';

    final greeting = '${AppStrings.dearCustomer} ${Formatters.textForExport(customerName)},';
    final body = isOverdue
        ? AppStrings.paymentReminderOverdueBody
        : AppStrings.paymentReminderBody;

    return [
      greeting,
      '',
      body,
      '',
      '$invoiceLabel: ${Formatters.textForExport(invoiceNumber)}',
      '${AppStrings.amountDue}: $amountLabel',
      if (dueLine.isNotEmpty) dueLine,
      '',
      AppStrings.paymentReminderClosing,
      factoryName,
    ].join('\n');
  }
}
