import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/entities/customer.dart';
import '../routes/route_paths.dart';
import '../utils/auth_context.dart';

Future<void> showCustomerPickerSheet(BuildContext context) async {
  final factoryId = readFactoryId(context);
  if (factoryId == null) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return _CustomerPickerSheet(factoryId: factoryId);
    },
  );
}

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet({required this.factoryId});

  final String factoryId;

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _searchController = TextEditingController();
  final _repository = getIt<CustomerRepository>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Customer> _filter(List<Customer> customers, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return customers;
    return customers
        .where(
          (customer) =>
              customer.name.toLowerCase().contains(trimmed) ||
              customer.phone.contains(trimmed),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.selectCustomerForStatement,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: AppStrings.searchCustomers,
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Customer>>(
                stream: _repository.watchCustomers(widget.factoryId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers = _filter(snapshot.data ?? const [], _searchController.text);
                  if (customers.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(AppStrings.noCustomersFound),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            customer.name.isNotEmpty
                                ? customer.name[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(customer.name),
                        subtitle: Text(customer.phone),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(RoutePaths.customerStatement(customer.id));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
