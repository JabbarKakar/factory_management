import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/finished_goods/finished_goods_detail_bloc.dart';
import '../../../blocs/finished_goods/inventory_adjustment_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/inventory_enums.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class RecordInventoryAdjustmentScreen extends StatefulWidget {
  const RecordInventoryAdjustmentScreen({
    required this.finishedGoodId,
    required this.movementTypeName,
    super.key,
  });

  final String finishedGoodId;
  final String movementTypeName;

  bool get isStockIn =>
      InventoryMovementType.fromString(movementTypeName) ==
      InventoryMovementType.adjustmentIn;

  @override
  State<RecordInventoryAdjustmentScreen> createState() =>
      _RecordInventoryAdjustmentScreenState();
}

class _RecordInventoryAdjustmentScreenState
    extends State<RecordInventoryAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _transactionDate = DateTime.now();
  final _quantityController = TextEditingController();
  final _unitCostController = TextEditingController();
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
    _unitCostController.dispose();
    _reasonController.dispose();
    _notesController.dispose();
    super.dispose();
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

    final unitCostText = _unitCostController.text.trim();
    final unitCost = unitCostText.isEmpty
        ? null
        : double.tryParse(unitCostText);

    context.read<InventoryAdjustmentBloc>().add(
          InventoryAdjustmentSubmitted(
            quantity: double.parse(_quantityController.text.trim()),
            transactionDate: _transactionDate,
            reason: _reasonController.text.trim(),
            unitCost: unitCost,
            notes: _notesController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isStockIn = widget.isStockIn;
    final detailState = context.watch<FinishedGoodsDetailBloc>().state;
    final item = detailState.item;
    final requiresUnitCost = isStockIn && (item == null || !item.hasStock);

    return BlocConsumer<InventoryAdjustmentBloc, InventoryAdjustmentState>(
      listener: (context, state) {
        if (state.status == InventoryAdjustmentStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.stockAdjustmentRecorded)),
          );
          context.pop(true);
        }
        if (state.status == InventoryAdjustmentStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final isSaving = state.status == InventoryAdjustmentStatus.saving;
        final title = isStockIn
            ? AppStrings.adjustStockIn
            : AppStrings.adjustStockOut;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: title,
              subtitle: item?.displaySubtitle ?? title,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                if (item != null)
                  JobWorkDetailSection(
                    title: item.productType.label,
                    icon: Icons.inventory_2_outlined,
                    child: AppFormSectionBody(
                      children: [
                        Text(
                          item.displaySubtitle,
                          style: AppFormFields.valueStyle(context),
                        ),
                        AppFormFields.gap,
                        AppFormSummaryRow(
                          label: AppStrings.currentQuantity,
                          value: Formatters.stockQuantity(
                            item.currentQuantity,
                            'sq. ft',
                          ),
                        ),
                      ],
                    ),
                  ),
                JobWorkDetailSection(
                  title: AppStrings.recordStockAdjustment,
                  icon: Icons.tune_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormDateField(
                        label: AppStrings.movementDate,
                        value: DateFormat.yMMMd().format(_transactionDate),
                        onTap: isSaving ? null : _pickDate,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _quantityController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Quantity (sq. ft)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Quantity is required';
                          }
                          final quantity = double.tryParse(value.trim());
                          if (quantity == null || quantity <= 0) {
                            return 'Enter a valid quantity';
                          }
                          if (!isStockIn &&
                              item != null &&
                              quantity > item.currentQuantity) {
                            return AppStrings.quantityExceedsStock;
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
                            label: AppStrings.unitCostPerSqFt,
                            hint: AppStrings.adjustmentUnitCostHint,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) {
                            if (!requiresUnitCost &&
                                (value == null || value.trim().isEmpty)) {
                              return null;
                            }
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.adjustmentUnitCostRequired;
                            }
                            final cost = double.tryParse(value.trim());
                            if (cost == null || cost < 0) {
                              return 'Enter a valid unit cost';
                            }
                            return null;
                          },
                          enabled: !isSaving,
                        ),
                      ],
                      AppFormFields.gap,
                      TextFormField(
                        controller: _reasonController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.adjustmentReason,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppStrings.adjustmentReasonRequired;
                          }
                          return null;
                        },
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
                ),
                AppFormSubmitBar(
                  label: AppStrings.recordStockAdjustment,
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
