import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../data/repositories/job_work_repository.dart';
import '../../../data/repositories/sales_order_repository.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/customer_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../job_work/job_work_detail_row.dart';
import '../job_work/job_work_detail_section.dart';

/// Shows how many job work and sales orders a customer has,
/// gated by the customer's service type.
///
/// Decision C: when an open Job Work exists, primary CTA is Add Load;
/// New Job Work remains secondary.
class CustomerOrdersSummarySection extends StatelessWidget {
  const CustomerOrdersSummarySection({required this.customer, super.key});

  final Customer customer;

  bool get _tracksJobWork =>
      customer.serviceType != CustomerServiceType.buyer;

  bool get _tracksSales =>
      customer.serviceType != CustomerServiceType.jobWork;

  JobWorkOrder? _preferredOpenJobWork(List<JobWorkOrder> orders) {
    final open = orders
        .where((order) => order.status != JobWorkStatus.cancelled)
        .toList();
    if (open.isEmpty) return null;
    open.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return open.first;
  }

  @override
  Widget build(BuildContext context) {
    final jobWorkStream = _tracksJobWork
        ? getIt<JobWorkRepository>().watchOrdersForCustomer(customer.id)
        : Stream<List<JobWorkOrder>>.value(const []);
    final salesStream = _tracksSales
        ? getIt<SalesOrderRepository>()
            .watchActiveOrderCountForCustomer(customer.id)
        : Stream<int>.value(0);

    return StreamBuilder<List<JobWorkOrder>>(
      stream: jobWorkStream,
      builder: (context, jobWorkSnapshot) {
        return StreamBuilder<int>(
          stream: salesStream,
          builder: (context, salesSnapshot) {
            final jobWorkOrders = jobWorkSnapshot.data ?? const [];
            final jobWorkCount = jobWorkOrders.length;
            final salesCount = salesSnapshot.data ?? 0;
            final openJobWork = _preferredOpenJobWork(jobWorkOrders);

            // For "other" service types, only surface counts that exist.
            final isOther =
                customer.serviceType == CustomerServiceType.other;
            final showJobWork =
                _tracksJobWork && (!isOther || jobWorkCount > 0);
            final showSales = _tracksSales && (!isOther || salesCount > 0);
            final canEditJobWork = context.userCanEdit(AppModule.jobWork);

            if (!showJobWork && !showSales) {
              return const SizedBox.shrink();
            }

            return JobWorkDetailSection(
              title: AppStrings.ordersSummary,
              icon: Icons.assignment_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  JobWorkDetailRows(
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
                  if (showJobWork && canEditJobWork) ...[
                    const SizedBox(height: 12),
                    if (openJobWork != null) ...[
                      FilledButton.icon(
                        onPressed: () => context.push(
                          RoutePaths.jobWorkAddLoad(openJobWork.id),
                        ),
                        icon: const Icon(Icons.add_box_outlined),
                        label: Text(
                          '${AppStrings.addLoad} · ${openJobWork.jobWorkNumber}',
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.push(RoutePaths.jobWorkAdd),
                        icon: const Icon(Icons.note_add_outlined),
                        label: const Text(AppStrings.newJobWorkOrder),
                      ),
                    ] else
                      FilledButton.icon(
                        onPressed: () => context.push(RoutePaths.jobWorkAdd),
                        icon: const Icon(Icons.note_add_outlined),
                        label: const Text(AppStrings.newJobWorkOrder),
                      ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
