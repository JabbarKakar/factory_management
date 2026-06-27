import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/finished_goods/finished_goods_detail_bloc.dart';
import '../../../blocs/finished_goods/inventory_adjustment_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/enums/inventory_enums.dart';
import '../../widgets/settings_section.dart';

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
  final _reasonController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _quantityController.dispose();
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

    context.read<InventoryAdjustmentBloc>().add(
          InventoryAdjustmentSubmitted(
            quantity: double.parse(_quantityController.text.trim()),
            transactionDate: _transactionDate,
            reason: _reasonController.text.trim(),
            notes: _notesController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final isStockIn = widget.isStockIn;
    final detailState = context.watch<FinishedGoodsDetailBloc>().state;
    final item = detailState.item;

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

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isStockIn
                  ? AppStrings.adjustStockIn
                  : AppStrings.adjustStockOut,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                if (item != null)
                  SettingsSection(
                    title: item.productType.label,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.displaySubtitle),
                          const SizedBox(height: 8),
                          Text(
                            '${AppStrings.currentQuantity}: '
                            '${Formatters.stockQuantity(item.currentQuantity, 'sq. ft')}',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                SettingsSection(
                  title: AppStrings.recordStockAdjustment,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.movementDate),
                          subtitle:
                              Text(DateFormat.yMMMd().format(_transactionDate)),
                          trailing:
                              const Icon(Icons.calendar_today_outlined),
                          onTap: isSaving ? null : _pickDate,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _quantityController,
                          decoration: const InputDecoration(
                            labelText: 'Quantity (sq. ft)',
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
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.adjustmentReason,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppStrings.adjustmentReasonRequired;
                            }
                            return null;
                          },
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
                        : const Text(AppStrings.recordStockAdjustment),
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
