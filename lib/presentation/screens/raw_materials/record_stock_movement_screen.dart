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
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

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
    final title =
        isStockIn ? AppStrings.recordStockIn : AppStrings.recordStockOut;

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
            title: AppFormAppBarTitle(
              title: title,
              subtitle: materialType.label,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: materialType.label,
                  icon: Icons.category_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormDateField(
                        label: isStockIn
                            ? AppStrings.receiptDate
                            : AppStrings.movementDate,
                        value: DateFormat.yMMMd().format(_transactionDate),
                        onTap: isSaving ? null : _pickDate,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _quantityController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label:
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
                        enabled: !isSaving,
                      ),
                      if (isStockIn) ...[
                        AppFormFields.gap,
                        TextFormField(
                          controller: _unitCostController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.unitCostPkr,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
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
                          enabled: !isSaving,
                        ),
                        if (_totalCost != null) ...[
                          AppFormFields.gap,
                          AppFormSummaryRow(
                            label: AppStrings.totalCost,
                            value: Formatters.currencyPkr(_totalCost!),
                            highlight: true,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                if (isStockIn)
                  JobWorkDetailSection(
                    title: AppStrings.optionalDetails,
                    icon: Icons.more_horiz_outlined,
                    child: AppFormSectionBody(
                      children: [
                        if (factoryId != null)
                          StreamBuilder<List<Supplier>>(
                            stream: getIt<SupplierRepository>()
                                .watchSuppliers(factoryId),
                            builder: (context, snapshot) {
                              final suppliers = snapshot.data ?? const [];
                              final supplierValue = _supplierId != null &&
                                      suppliers.any(
                                        (supplier) =>
                                            supplier.id == _supplierId,
                                      )
                                  ? _supplierId
                                  : null;
                              return DropdownButtonFormField<String?>(
                                key: ValueKey(supplierValue),
                                initialValue: supplierValue,
                                style: AppFormFields.valueStyle(context),
                                decoration: AppFormFields.decoration(
                                  context,
                                  label: AppStrings.linkSupplier,
                                ),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text(
                                      AppStrings.noSupplierLinked,
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  ...suppliers.map(
                                    (supplier) => DropdownMenuItem<String?>(
                                      value: supplier.id,
                                      child: Text(
                                        supplier.name,
                                        style: const TextStyle(fontSize: 13),
                                      ),
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
                        if (factoryId != null) AppFormFields.gap,
                        TextFormField(
                          controller: _referenceController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.referenceNumber,
                          ),
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _notesController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.notes,
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          enabled: !isSaving,
                        ),
                      ],
                    ),
                  )
                else
                  JobWorkDetailSection(
                    title: AppStrings.optionalDetails,
                    icon: Icons.more_horiz_outlined,
                    child: AppFormSectionBody(
                      children: [
                        TextFormField(
                          controller: _notesController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.consumptionReason,
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) => Validators.requiredText(
                            value,
                            field: 'Reason',
                          ),
                          enabled: !isSaving,
                        ),
                      ],
                    ),
                  ),
                AppFormSubmitBar(
                  label: title,
                  isLoading: isSaving,
                  onPressed: isSaving ? null : () => _submit(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
