import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/customer/customer_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/customers/customer_balance_indicator.dart';
import '../../widgets/customers/customer_detail_hero.dart';
import '../../widgets/customers/customer_ledger_section.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({required this.customerId, super.key});

  final String customerId;

  String _formatAddress(String? street, String? city, String? province) {
    final parts = [street, city, province]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '—';
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CustomerFormBloc, CustomerFormState>(
      builder: (context, state) {
        if (state.status == CustomerFormStatus.loading ||
            state.status == CustomerFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.customerDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.customerDetails)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.customerNotFound),
            ),
          );
        }

        final customer = state.customer!;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.customerDetails),
                Text(
                  customer.name,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            actions: [
              if (context.userCanEdit(AppModule.customers))
                IconButton(
                  onPressed: () => context.push(
                    RoutePaths.customerEdit(customer.id),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editCustomer,
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              CustomerDetailHero(customer: customer),
              JobWorkDetailSection(
                title: AppStrings.accountSummary,
                icon: Icons.payments_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.balance,
                      value: Formatters.currencyPkr(customer.balance),
                      bold: true,
                      highlight: true,
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.paymentStatus,
                      valueWidget: Align(
                        alignment: Alignment.centerRight,
                        child: CustomerBalanceIndicator(
                          status: customer.balanceStatus,
                        ),
                      ),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.creditLimit,
                      value: Formatters.currencyPkr(customer.creditLimit),
                    ),
                    JobWorkDetailRow(
                      label: AppStrings.paymentTerms,
                      value: customer.paymentTerms.label,
                    ),
                    if (customer.nextDueDate != null)
                      JobWorkDetailRow(
                        label: AppStrings.nextDueDate,
                        value:
                            DateFormat.yMMMd().format(customer.nextDueDate!),
                      ),
                  ],
                ),
              ),
              CustomerLedgerSection(
                customerId: customer.id,
                customerName: customer.name,
              ),
              if (context.userCanExport(AppModule.customers))
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: DashboardSurfaceCard(
                    compact: true,
                    borderRadius: 14,
                    padding: const EdgeInsets.all(12),
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        RoutePaths.customerStatement(customer.id),
                      ),
                      icon: const Icon(Icons.receipt_long_outlined, size: 16),
                      label: Text(
                        AppStrings.generateStatement,
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
              JobWorkDetailSection(
                title: AppStrings.contactInformation,
                icon: Icons.contact_phone_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.phone,
                      value: customer.phone,
                    ),
                    if (customer.phoneSecondary != null)
                      JobWorkDetailRow(
                        label: AppStrings.secondaryPhone,
                        value: customer.phoneSecondary!,
                      ),
                    if (customer.whatsApp != null)
                      JobWorkDetailRow(
                        label: AppStrings.whatsApp,
                        value: customer.whatsApp!,
                      ),
                    if (customer.email != null)
                      JobWorkDetailRow(
                        label: AppStrings.email,
                        value: customer.email!,
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.address,
                icon: Icons.location_on_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.billingAddress,
                      value: _formatAddress(
                        customer.billingStreet,
                        customer.billingCity,
                        customer.billingProvince,
                      ),
                    ),
                    if (!customer.useSameShippingAddress)
                      JobWorkDetailRow(
                        label: AppStrings.shippingAddress,
                        value: _formatAddress(
                          customer.shippingStreet,
                          customer.shippingCity,
                          customer.shippingProvince,
                        ),
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.businessDetails,
                icon: Icons.business_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.customerType,
                      value: customer.customerType.label,
                    ),
                    if (customer.contactPersonName != null)
                      JobWorkDetailRow(
                        label: AppStrings.contactPerson,
                        value: customer.contactPersonName!,
                      ),
                    JobWorkDetailRow(
                      label: AppStrings.customerCategory,
                      value: customer.category.label,
                    ),
                    if (customer.cnicNtn != null)
                      JobWorkDetailRow(
                        label: AppStrings.cnicNtn,
                        value: customer.cnicNtn!,
                      ),
                    if (customer.referredBy != null)
                      JobWorkDetailRow(
                        label: AppStrings.referredBy,
                        value: customer.referredBy!,
                      ),
                    if (customer.otherServiceDescription != null)
                      JobWorkDetailRow(
                        label: AppStrings.otherServiceDescription,
                        value: customer.otherServiceDescription!,
                      ),
                    if (customer.notes != null)
                      JobWorkDetailRow(
                        label: AppStrings.notes,
                        value: customer.notes!,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
