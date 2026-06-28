import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/customer_repository.dart';
import '../../domain/entities/customer.dart';
import '../routes/route_paths.dart';
import '../utils/auth_context.dart';
import '../widgets/dialogs/app_bottom_sheet.dart';
import '../widgets/job_work/job_work_search_bar.dart';

Future<void> showCustomerPickerSheet(BuildContext context) async {
  final factoryId = readFactoryId(context);
  if (factoryId == null) return;

  await AppBottomSheet.show<void>(
    context,
    isScrollControlled: true,
    useSafeArea: true,
    child: _CustomerPickerSheet(factoryId: factoryId),
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

  void _onSearchClear() {
    _searchController.clear();
    setState(() {});
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppBottomSheet(
              title: AppStrings.selectCustomerForStatement,
              subtitle: AppStrings.searchCustomers,
              icon: Icons.person_search_outlined,
              showDragHandle: false,
              child: const SizedBox.shrink(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: JobWorkSearchBar(
                controller: _searchController,
                hintText: AppStrings.searchCustomers,
                onChanged: (_) => setState(() {}),
                onClear: _onSearchClear,
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Customer>>(
                stream: _repository.watchCustomers(widget.factoryId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final customers =
                      _filter(snapshot.data ?? const [], _searchController.text);
                  if (customers.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          AppStrings.noCustomersFound,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scrollController,
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return AppBottomSheetListTile(
                        title: customer.name,
                        subtitle: customer.phone,
                        leadingIcon: Icons.person_outline,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(
                            RoutePaths.customerStatement(customer.id),
                          );
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
