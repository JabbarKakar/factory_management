import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/supplier/supplier_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/settings_section.dart';
import '../../widgets/suppliers/supplier_purchases_section.dart';
import '../../widgets/suppliers/supplier_type_chip.dart';

class SupplierDetailScreen extends StatelessWidget {
  const SupplierDetailScreen({required this.supplierId, super.key});

  final String supplierId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SupplierFormBloc, SupplierFormState>(
      builder: (context, state) {
        if (state.status == SupplierFormStatus.loading ||
            state.status == SupplierFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.supplierDetails)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.supplier == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.supplierDetails)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.supplierNotFound),
            ),
          );
        }

        final supplier = state.supplier!;

        return Scaffold(
          appBar: AppBar(
            title: const Text(AppStrings.supplierDetails),
            actions: [
              if (context.userCanEdit(AppModule.suppliers))
                IconButton(
                  onPressed: () => context.push(
                    RoutePaths.supplierEdit(supplier.id),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: AppStrings.editSupplier,
                ),
            ],
          ),
          floatingActionButton:
              (context.userCanCreate(AppModule.expenses) ||
                      context.userCanCreate(AppModule.rawMaterials))
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (context.userCanCreate(AppModule.expenses))
                          FloatingActionButton.extended(
                            heroTag: 'fab-supplier-purchase',
                            onPressed: () => context.push(
                              RoutePaths.expensesAddForSupplier(
                                supplierId: supplier.id,
                                payeeName: supplier.name,
                              ),
                            ),
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                            label: const Text(AppStrings.recordPurchase),
                          ),
                        if (context.userCanCreate(AppModule.expenses) &&
                            context.userCanCreate(AppModule.rawMaterials))
                          const SizedBox(height: 12),
                        if (context.userCanCreate(AppModule.rawMaterials))
                          FloatingActionButton.extended(
                            heroTag: 'fab-supplier-stock-in',
                            onPressed: () =>
                                _showMaterialPicker(context, supplier),
                            icon: const Icon(Icons.inventory_2_outlined),
                            label: const Text(AppStrings.stockIn),
                          ),
                      ],
                    )
                  : null,
          body: ListView(
            padding: const EdgeInsets.only(bottom: 140),
            children: [
              _ProfileHeader(supplier: supplier),
              SupplierPurchasesSection(supplierId: supplier.id),
              SettingsSection(
                title: AppStrings.contactInformation,
                child: _DetailList(
                  items: [
                    _DetailItem(AppStrings.phone, supplier.phone),
                    if (supplier.phoneSecondary != null)
                      _DetailItem(
                        AppStrings.secondaryPhone,
                        supplier.phoneSecondary!,
                      ),
                    if (supplier.contactPersonName != null)
                      _DetailItem(
                        AppStrings.contactPerson,
                        supplier.contactPersonName!,
                      ),
                    if (supplier.city != null)
                      _DetailItem(AppStrings.city, supplier.city!),
                    if (supplier.address != null)
                      _DetailItem(AppStrings.address, supplier.address!),
                  ],
                ),
              ),
              SettingsSection(
                title: AppStrings.supplierInformation,
                child: _DetailList(
                  items: [
                    _DetailItem(
                      AppStrings.paymentTerms,
                      supplier.paymentTerms.label,
                    ),
                    if (supplier.cnicNtn != null)
                      _DetailItem(AppStrings.cnicNtn, supplier.cnicNtn!),
                    if (supplier.materialsSupplied != null)
                      _DetailItem(
                        AppStrings.materialsSupplied,
                        supplier.materialsSupplied!,
                      ),
                    if (supplier.notes != null)
                      _DetailItem(AppStrings.notes, supplier.notes!),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMaterialPicker(BuildContext context, Supplier supplier) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  AppStrings.selectMaterialForStockIn,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              ...RawMaterialType.values.map(
                (materialType) => ListTile(
                  title: Text(materialType.label),
                  subtitle: Text(materialType.unit.label),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.push(
                      RoutePaths.rawMaterialStockIn(
                        materialType.name,
                        supplierId: supplier.id,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.supplier});

  final Supplier supplier;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              supplier.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              supplier.supplierNumber,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: muted,
                  ),
            ),
            const SizedBox(height: 12),
            SupplierTypeChip(supplierType: supplier.supplierType),
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
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

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
    required this.value,
  });

  final String label;
  final String value;

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
            style: TextStyle(color: muted),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
