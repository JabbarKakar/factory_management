import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/delivery/delivery_confirm_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/delivery.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

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

  String _appBarSubtitle(Delivery delivery) {
    if (delivery.deliveryNumber.isNotEmpty) {
      return '${delivery.deliveryNumber} · ${delivery.customerName}';
    }
    return delivery.customerName;
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
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.confirmDelivery,
                subtitle: AppStrings.confirmDelivery,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final delivery = state.delivery;
        if (delivery == null) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.confirmDelivery,
                subtitle: AppStrings.confirmDelivery,
              ),
            ),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.deliveryNotFound),
            ),
          );
        }

        _initFields(delivery);
        final isSaving = state.status == DeliveryConfirmStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.confirmDelivery,
              subtitle: _appBarSubtitle(delivery),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            children: [
              JobWorkDetailSection(
                title: AppStrings.actualDeliveryDate,
                icon: Icons.event_outlined,
                child: AppFormSectionBody(
                  children: [
                    AppFormDateField(
                      label: AppStrings.actualDeliveryDate,
                      value: DateFormat.yMMMd().format(_actualDate),
                      onTap: isSaving ? null : _pickDate,
                    ),
                  ],
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.itemsToDeliver,
                icon: Icons.inventory_2_outlined,
                child: AppFormSectionBody(
                  children: _fields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field.item.displayLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Scheduled: ${field.item.quantity} ${field.item.quantityUnit.label}',
                            style: AppFormFields.labelStyle(context),
                          ),
                          AppFormFields.gap,
                          TextFormField(
                            controller: field.controller,
                            enabled: !isSaving,
                            style: AppFormFields.valueStyle(context),
                            decoration: AppFormFields.decoration(
                              context,
                              label:
                                  '${AppStrings.deliveredQuantity} (${field.item.quantityUnit.label})',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              JobWorkDetailSection(
                title: AppStrings.notes,
                icon: Icons.notes_outlined,
                child: AppFormSectionBody(
                  children: [
                    TextFormField(
                      controller: _notesController,
                      enabled: !isSaving,
                      style: AppFormFields.valueStyle(context),
                      decoration: AppFormFields.decoration(
                        context,
                        label: AppStrings.notes,
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              AppFormSubmitBar(
                label: AppStrings.confirmDelivery,
                isLoading: isSaving,
                onPressed: isSaving ? null : () => _submit(context),
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
