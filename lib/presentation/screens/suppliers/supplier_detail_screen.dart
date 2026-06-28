import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/supplier/supplier_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../routes/route_paths.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/job_work/job_work_detail_row.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/suppliers/supplier_actions_bar.dart';
import '../../widgets/suppliers/supplier_detail_hero.dart';
import '../../widgets/suppliers/supplier_purchases_section.dart';

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
        final canRecordPurchase =
            context.userCanCreate(AppModule.expenses);
        final canStockIn = context.userCanCreate(AppModule.rawMaterials);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.supplierDetails),
                Text(
                  supplier.name,
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
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              SupplierDetailHero(supplier: supplier),
              SupplierActionsBar(
                canRecordPurchase: canRecordPurchase,
                canStockIn: canStockIn,
                onRecordPurchase: () => context.push(
                  RoutePaths.expensesAddForSupplier(
                    supplierId: supplier.id,
                    payeeName: supplier.name,
                  ),
                ),
                onStockIn: () => _showMaterialPicker(context, supplier),
              ),
              SupplierPurchasesSection(supplierId: supplier.id),
              JobWorkDetailSection(
                title: AppStrings.contactInformation,
                icon: Icons.contact_phone_outlined,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.phone,
                      value: supplier.phone,
                    ),
                    if (supplier.phoneSecondary != null)
                      JobWorkDetailRow(
                        label: AppStrings.secondaryPhone,
                        value: supplier.phoneSecondary!,
                      ),
                    if (supplier.contactPersonName != null)
                      JobWorkDetailRow(
                        label: AppStrings.contactPerson,
                        value: supplier.contactPersonName!,
                      ),
                    if (supplier.city != null)
                      JobWorkDetailRow(
                        label: AppStrings.city,
                        value: supplier.city!,
                      ),
                    if (supplier.address != null)
                      JobWorkDetailRow(
                        label: AppStrings.address,
                        value: supplier.address!,
                      ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.supplierInformation,
                icon: Icons.info_outline,
                child: JobWorkDetailRows(
                  rows: [
                    JobWorkDetailRow(
                      label: AppStrings.paymentTerms,
                      value: supplier.paymentTerms.label,
                    ),
                    if (supplier.cnicNtn != null)
                      JobWorkDetailRow(
                        label: AppStrings.cnicNtn,
                        value: supplier.cnicNtn!,
                      ),
                    if (supplier.materialsSupplied != null)
                      JobWorkDetailRow(
                        label: AppStrings.materialsSupplied,
                        value: supplier.materialsSupplied!,
                      ),
                    if (supplier.notes != null)
                      JobWorkDetailRow(
                        label: AppStrings.notes,
                        value: supplier.notes!,
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

  void _showMaterialPicker(BuildContext context, Supplier supplier) {
    final theme = Theme.of(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  AppStrings.selectMaterialForStockIn,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              ...RawMaterialType.values.map(
                (materialType) => ListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(
                    Icons.inventory_2_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(
                    materialType.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Text(
                    materialType.unit.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}
