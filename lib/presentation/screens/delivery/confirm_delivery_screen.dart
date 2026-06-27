import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/delivery/delivery_confirm_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/delivery.dart';
import '../../widgets/settings_section.dart';

class ConfirmDeliveryScreen extends StatefulWidget {
  const ConfirmDeliveryScreen({required this.deliveryId, super.key});

  final String deliveryId;

  @override
  State<ConfirmDeliveryScreen> createState() => _ConfirmDeliveryScreenState();
}

class _ConfirmDeliveryScreenState extends State<ConfirmDeliveryScreen> {
  final _notesController = TextEditingController();
  final List<_DeliveredQtyField> _fields = [];
  DateTime _actualDate = DateTime.now();

  @override
  void dispose() {
    _notesController.dispose();
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  void _initFields(Delivery delivery) {
    if (_fields.isNotEmpty) return;
    for (final item in delivery.lineItems) {
      _fields.add(
        _DeliveredQtyField(
          item: item,
          initialQuantity: item.quantity,
        ),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _actualDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _actualDate = picked);
  }

  void _submit(BuildContext context) {
    final lineItems = <DeliveryLineItem>[];
    for (final field in _fields) {
      final delivered = double.tryParse(field.controller.text.trim());
      if (delivered == null) return;
      lineItems.add(
        field.item.copyWith(quantityDelivered: delivered),
      );
    }

    context.read<DeliveryConfirmBloc>().add(
          DeliveryConfirmSubmitted(
            actualDeliveryDate: _actualDate,
            lineItems: lineItems,
            notes: _notesController.text.trim(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryConfirmBloc, DeliveryConfirmState>(
      listener: (context, state) {
        if (state.status == DeliveryConfirmStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.deliveryConfirmed)),
          );
          context.pop(true);
        }
        if (state.status == DeliveryConfirmStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == DeliveryConfirmStatus.loading ||
            state.status == DeliveryConfirmStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.confirmDelivery)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final delivery = state.delivery;
        if (delivery == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.confirmDelivery)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.deliveryNotFound),
            ),
          );
        }

        _initFields(delivery);
        final isSaving = state.status == DeliveryConfirmStatus.saving;

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.confirmDelivery)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              SettingsSection(
                title: AppStrings.actualDeliveryDate,
                child: ListTile(
                  title: Text(DateFormat.yMMMd().format(_actualDate)),
                  trailing: const Icon(Icons.calendar_today_outlined),
                  onTap: isSaving ? null : _pickDate,
                ),
              ),
              SettingsSection(
                title: AppStrings.itemsToDeliver,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: _fields.map((field) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              field.item.displayLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Scheduled: ${field.item.quantity} ${field.item.quantityUnit.label}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: field.controller,
                              enabled: !isSaving,
                              decoration: InputDecoration(
                                labelText:
                                    '${AppStrings.deliveredQuantity} (${field.item.quantityUnit.label})',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SettingsSection(
                title: AppStrings.notes,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _notesController,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      labelText: AppStrings.notes,
                    ),
                    maxLines: 3,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: isSaving ? null : () => _submit(context),
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.confirmDelivery),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DeliveredQtyField {
  _DeliveredQtyField({
    required this.item,
    required double initialQuantity,
  }) : controller = TextEditingController(text: initialQuantity.toString());

  final DeliveryLineItem item;
  final TextEditingController controller;

  void dispose() => controller.dispose();
}
