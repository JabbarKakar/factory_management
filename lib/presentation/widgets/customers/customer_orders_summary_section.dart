import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/job_work_repository.dart';
import '../../../data/repositories/sales_order_repository.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/enums/customer_enums.dart';
import '../job_work/job_work_detail_row.dart';
import '../job_work/job_work_detail_section.dart';

/// Shows how many job work and sales orders a customer has,
/// gated by the customer's service type.
class CustomerOrdersSummarySection extends StatelessWidget {
  const CustomerOrdersSummarySection({required this.customer, super.key});

  final Customer customer;

  bool get _tracksJobWork =>
      customer.serviceType != CustomerServiceType.buyer;

  bool get _tracksSales =>
      customer.serviceType != CustomerServiceType.jobWork;

  @override
  Widget build(BuildContext context) {
    final jobWorkStream = _tracksJobWork
        ? getIt<JobWorkRepository>()
            .watchActiveOrderCountForCustomer(customer.id)
        : Stream<int>.value(0);
    final salesStream = _tracksSales
        ? getIt<SalesOrderRepository>()
            .watchActiveOrderCountForCustomer(customer.id)
        : Stream<int>.value(0);

    return StreamBuilder<int>(
      stream: jobWorkStream,
      builder: (context, jobWorkSnapshot) {
        return StreamBuilder<int>(
          stream: salesStream,
          builder: (context, salesSnapshot) {
            final jobWorkCount = jobWorkSnapshot.data ?? 0;
            final salesCount = salesSnapshot.data ?? 0;

            // For "other" service types, only surface counts that exist.
            final isOther =
                customer.serviceType == CustomerServiceType.other;
            final showJobWork =
                _tracksJobWork && (!isOther || jobWorkCount > 0);
            final showSales = _tracksSales && (!isOther || salesCount > 0);

            if (!showJobWork && !showSales) {
              return const SizedBox.shrink();
            }

            return JobWorkDetailSection(
              title: AppStrings.ordersSummary,
              icon: Icons.assignment_outlined,
              child: JobWorkDetailRows(
                rows: [
                  if (showJobWork)
                    JobWorkDetailRow(
                      label: AppStrings.jobWorkOrdersLabel,
                      value: '$jobWorkCount',
                      bold: true,
                    ),
                  if (showSales)
                    JobWorkDetailRow(
                      label: AppStrings.salesOrdersLabel,
                      value: '$salesCount',
                      bold: true,
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
