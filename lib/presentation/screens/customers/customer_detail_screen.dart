import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/customer/customer_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/customers/customer_balance_indicator.dart';
import '../../widgets/customers/customer_ledger_section.dart';
import '../../widgets/customers/service_type_chip.dart';
import '../../widgets/settings_section.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({required this.customerId, super.key});

  final String customerId;

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
            title: const Text(AppStrings.customerDetails),
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
              _ProfileHeader(customer: customer),
              SettingsSection(
                title: AppStrings.accountSummary,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _DetailRow(
                        label: AppStrings.balance,
                        value: Formatters.currencyPkr(customer.balance),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: AppStrings.paymentStatus,
                        valueWidget: CustomerBalanceIndicator(
                          status: customer.balanceStatus,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: AppStrings.creditLimit,
                        value: Formatters.currencyPkr(customer.creditLimit),
                      ),
                      const SizedBox(height: 12),
                      _DetailRow(
                        label: AppStrings.paymentTerms,
                        value: customer.paymentTerms.label,
                      ),
                      if (customer.nextDueDate != null) ...[
                        const SizedBox(height: 12),
                        _DetailRow(
                          label: AppStrings.nextDueDate,
                          value: DateFormat.yMMMd().format(customer.nextDueDate!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              CustomerLedgerSection(customerId: customer.id),
              SettingsSection(
                title: AppStrings.contactInformation,
                child: _DetailList(
                  items: [
                    _DetailItem(AppStrings.phone, customer.phone),
                    if (customer.phoneSecondary != null)
                      _DetailItem(
                        AppStrings.secondaryPhone,
                        customer.phoneSecondary!,
                      ),
                    if (customer.whatsApp != null)
                      _DetailItem(AppStrings.whatsApp, customer.whatsApp!),
                    if (customer.email != null)
                      _DetailItem(AppStrings.email, customer.email!),
                  ],
                ),
              ),
              SettingsSection(
                title: AppStrings.address,
                child: _DetailList(
                  items: [
                    _DetailItem(
                      AppStrings.billingAddress,
                      _formatAddress(
                        customer.billingStreet,
                        customer.billingCity,
                        customer.billingProvince,
                      ),
                    ),
                    if (!customer.useSameShippingAddress)
                      _DetailItem(
                        AppStrings.shippingAddress,
                        _formatAddress(
                          customer.shippingStreet,
                          customer.shippingCity,
                          customer.shippingProvince,
                        ),
                      ),
                  ],
                ),
              ),
              SettingsSection(
                title: AppStrings.businessDetails,
                child: _DetailList(
                  items: [
                    _DetailItem(
                      AppStrings.customerType,
                      customer.customerType.label,
                    ),
                    if (customer.contactPersonName != null)
                      _DetailItem(
                        AppStrings.contactPerson,
                        customer.contactPersonName!,
                      ),
                    _DetailItem(
                      AppStrings.customerCategory,
                      customer.category.label,
                    ),
                    if (customer.cnicNtn != null)
                      _DetailItem(AppStrings.cnicNtn, customer.cnicNtn!),
                    if (customer.referredBy != null)
                      _DetailItem(AppStrings.referredBy, customer.referredBy!),
                    if (customer.otherServiceDescription != null)
                      _DetailItem(
                        AppStrings.otherServiceDescription,
                        customer.otherServiceDescription!,
                      ),
                    if (customer.notes != null)
                      _DetailItem(AppStrings.notes, customer.notes!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatAddress(String? street, String? city, String? province) {
    final parts = [street, city, province]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '—';
    return parts.join(', ');
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              customer.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ServiceTypeChip(serviceType: customer.serviceType),
          ],
        ),
      ),
    );
  }
}

class _DetailList extends StatelessWidget {
  const _DetailList({required this.items});

  final List<_DetailItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: _DetailRow(label: items[i].label, value: items[i].value),
          ),
          if (i < items.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }
}

class _DetailItem {
  const _DetailItem(this.label, this.value);

  final String label;
  final String value;
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: muted,
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: valueWidget ??
              Text(
                value ?? '—',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.end,
              ),
        ),
      ],
    );
  }
}
