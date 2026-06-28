import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/job_work_invoice.dart';
import 'job_work_detail_row.dart';
import 'job_work_detail_section.dart';

class JobWorkInvoiceLineItemsSection extends StatelessWidget {
  const JobWorkInvoiceLineItemsSection({
    required this.lineItems,
    super.key,
  });

  final List<InvoiceLineItem> lineItems;

  @override
  Widget build(BuildContext context) {
    return JobWorkDetailSection(
      title: AppStrings.lineItems,
      icon: Icons.receipt_long_outlined,
      child: JobWorkDetailRows(
        rows: lineItems
            .map(
              (item) => JobWorkDetailRow(
                label: item.description,
                value: item.amount > 0
                    ? Formatters.currencyPkr(item.amount)
                    : '—',
              ),
            )
            .toList(),
      ),
    );
  }
}
