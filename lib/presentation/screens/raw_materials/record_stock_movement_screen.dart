import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/raw_material/stock_movement_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/di/injection.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../data/repositories/supplier_repository.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/enums/raw_material_enums.dart';
import '../../utils/auth_context.dart';
import '../../widgets/settings_section.dart';

class RecordStockMovementScreen extends StatefulWidget {
  const RecordStockMovementScreen({
    required this.materialTypeName,
    required this.movementTypeName,
    this.initialSupplierId,
    super.key,
  });

  final String materialTypeName;
  final String movementTypeName;
  final String? initialSupplierId;

  bool get isStockIn =>
      StockMovementType.fromString(movementTypeName) ==
      StockMovementType.stockIn;

  RawMaterialType get materialType =>
      RawMaterialType.fromString(materialTypeName);

  @override
  State<RecordStockMovementScreen> createState() =>
      _RecordStockMovementScreenState();
}

class _RecordStockMovementScreenState extends State<RecordStockMovementScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _transactionDate = DateTime.now();
  String? _supplierId;

  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.isStockIn && widget.initialSupplierId != null) {
      _supplierId = widget.initialSupplierId;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? get _totalCost {
    final quantity = double.tryParse(_quantityController.text.trim());
    final unitCost = double.tryParse(_unitCostController.text.trim());
    if (quantity == null || unitCost == null) return null;
    return quantity * unitCost;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _transactionDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _transactionDate = picked);
    }
  }

  void _submit(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final quantity = double.parse(_quantityController.text.trim());
    final unitCost = widget.isStockIn
        ? double.tryParse(_unitCostController.text.trim())
        : null;

    context.read<StockMovementBloc>().add(
          StockMovementSubmitted(
            quantity: quantity,
            unitCost: unitCost,
            transactionDate: _transactionDate,
            supplierId: _supplierId,
            referenceNumber: _referenceController.text.trim().isEmpty
                ? null
                : _referenceController.text.trim(),
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final materialType = widget.materialType;
    final isStockIn = widget.isStockIn;
    final factoryId = readFactoryId(context);

    return BlocConsumer<StockMovementBloc, StockMovementState>(
      listener: (context, state) {
        if (state.status == StockMovementStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isStockIn
                    ? AppStrings.stockInRecorded
                    : AppStrings.stockOutRecorded,
              ),
            ),
          );
          context.pop(true);
        }
        if (state.status == StockMovementStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state.status == StockMovementStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isStockIn ? AppStrings.recordStockIn : AppStrings.recordStockOut,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: materialType.label,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            isStockIn
                                ? AppStrings.receiptDate
                                : AppStrings.movementDate,
                          ),
                          subtitle:
                              Text(DateFormat.yMMMd().format(_transactionDate)),
                          trailing:
                              const Icon(Icons.calendar_today_outlined),
                          onTap: isSaving ? null : _pickDate,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _quantityController,
                          decoration: InputDecoration(
                            labelText:
                                '${AppStrings.quantity} (${materialType.unit.label})',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Quantity is required';
                            }
                            final quantity = double.tryParse(value.trim());
                            if (quantity == null || quantity <= 0) {
                              return 'Enter a valid quantity';
                            }
                            return null;
                          },
                        ),
                        if (isStockIn) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _unitCostController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.unitCostPkr,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Unit cost is required';
                              }
                              final cost = double.tryParse(value.trim());
                              if (cost == null || cost < 0) {
                                return 'Enter a valid unit cost';
                              }
                              return null;
                            },
                          ),
                          if (_totalCost != null) ...[
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text(AppStrings.totalCost),
                              trailing: Text(
                                Formatters.currencyPkr(_totalCost!),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
                if (isStockIn)
                  SettingsSection(
                    title: AppStrings.optionalDetails,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (factoryId != null)
                            StreamBuilder<List<Supplier>>(
                              stream: getIt<SupplierRepository>()
                                  .watchSuppliers(factoryId),
                              builder: (context, snapshot) {
                                final suppliers = snapshot.data ?? const [];
                                return DropdownButtonFormField<String?>(
                                  initialValue: _supplierId != null &&
                                          suppliers.any(
                                            (supplier) =>
                                                supplier.id == _supplierId,
                                          )
                                      ? _supplierId
                                      : null,
                                  decoration: const InputDecoration(
                                    labelText: AppStrings.linkSupplier,
                                  ),
                                  items: [
                                    const DropdownMenuItem<String?>(
                                      value: null,
                                      child: Text(AppStrings.noSupplierLinked),
                                    ),
                                    ...suppliers.map(
                                      (supplier) => DropdownMenuItem<String?>(
                                        value: supplier.id,
                                        child: Text(supplier.name),
                                      ),
                                    ),
                                  ],
                                  onChanged: isSaving
                                      ? null
                                      : (value) =>
                                          setState(() => _supplierId = value),
                                );
                              },
                            ),
                          if (factoryId != null) const SizedBox(height: 12),
                          TextFormField(
                            controller: _referenceController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.referenceNumber,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.notes,
                            ),
                            maxLines: 3,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SettingsSection(
                    title: AppStrings.optionalDetails,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: AppStrings.consumptionReason,
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) => Validators.requiredText(
                          value,
                          field: 'Reason',
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed: isSaving ? null : () => _submit(context),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isStockIn
                                ? AppStrings.recordStockIn
                                : AppStrings.recordStockOut,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
