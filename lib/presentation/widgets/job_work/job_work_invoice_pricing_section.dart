import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import 'job_work_detail_row.dart';
import 'job_work_detail_section.dart';

class JobWorkInvoicePricingSection extends StatelessWidget {
  const JobWorkInvoicePricingSection({
    required this.invoice,
    super.key,
  });

  final JobWorkInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return JobWorkDetailSection(
      title: AppStrings.pricingAgreement,
      icon: Icons.payments_outlined,
      child: JobWorkDetailRows(
        rows: [
          JobWorkDetailRow(
            label: AppStrings.invoiceTotal,
            value: Formatters.currencyPkr(invoice.totalAmount),
          ),
          JobWorkDetailRow(
            label: AppStrings.amountPaid,
            value: Formatters.currencyPkr(invoice.paidAmount),
          ),
          JobWorkDetailRow(
            label: AppStrings.amountDue,
            value: Formatters.currencyPkr(invoice.dueAmount),
            bold: true,
            highlight: invoice.dueAmount > 0,
          ),
          if (invoice.dueDate != null)
            JobWorkDetailRow(
              label: AppStrings.paymentDueDate,
              value: DateFormat.yMMMd().format(invoice.dueDate!),
            ),
        ],
      ),
    );
  }
}
