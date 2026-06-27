import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/delivery/delivery_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../utils/auth_context.dart';
import '../../widgets/settings_section.dart';

class CreateDeliveryScreen extends StatefulWidget {
  const CreateDeliveryScreen({this.salesOrderId, super.key});

  final String? salesOrderId;

  @override
  State<CreateDeliveryScreen> createState() => _CreateDeliveryScreenState();
}

class _CreateDeliveryScreenState extends State<CreateDeliveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _notesController = TextEditingController();
  final _driverNameController = TextEditingController();

  DateTime _scheduledDate = DateTime.now();
  String? _selectedOrderId;
  String? _selectedDriverId;
  final List<_LineItemFields> _lineItems = [];

  @override
  void dispose() {
    _addressController.dispose();
    _vehicleController.dispose();
    _supervisorController.dispose();
    _notesController.dispose();
    _driverNameController.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _syncFromOrder(SalesOrder? order) {
    for (final item in _lineItems) {
      item.dispose();
    }
    _lineItems.clear();

    if (order == null) {
      _selectedOrderId = null;
      _addressController.clear();
      _scheduledDate = DateTime.now();
      return;
    }

    _selectedOrderId = order.id;
    _addressController.text = order.deliveryAddress ?? '';
    _scheduledDate = order.expectedDeliveryDate ?? DateTime.now();

    for (final item in order.lineItems) {
      _lineItems.add(
        _LineItemFields(
          item: DeliveryLineItem(
            productType: item.productType,
            marbleVariety: item.marbleVariety,
            sizeThickness: item.sizeThickness,
            quantity: item.quantity,
            quantityUnit: item.quantityUnit,
          ),
          initialQuantity: item.quantity,
        ),
      );
    }
  }

  void _onDriverSelected(String? employeeId, List<Employee> employees) {
    setState(() {
      _selectedDriverId = employeeId;
      if (employeeId == null) return;
      final employee = employees.firstWhere((e) => e.id == employeeId);
      _driverNameController.text = employee.fullName;
    });
  }

  Delivery? _buildDelivery(String factoryId) {
    if (_selectedOrderId == null) return null;

    final lineItems = <DeliveryLineItem>[];
    for (final fields in _lineItems) {
      final quantity = double.tryParse(fields.quantityController.text.trim());
      if (quantity == null || quantity <= 0) return null;
      lineItems.add(fields.item.copyWith(quantity: quantity));
    }

    return Delivery(
      id: '',
      deliveryNumber: '',
      factoryId: factoryId,
      salesOrderId: _selectedOrderId!,
      salesOrderNumber: '',
      customerId: '',
      customerName: '',
      deliveryAddress: _addressController.text.trim(),
      scheduledDate: _scheduledDate,
      status: DeliveryStatus.scheduled,
      lineItems: lineItems,
      vehicleNumber: _vehicleController.text.trim().isEmpty
          ? null
          : _vehicleController.text.trim(),
      driverName: _driverNameController.text.trim().isEmpty
          ? null
          : _driverNameController.text.trim(),
      driverEmployeeId: _selectedDriverId,
      loadingSupervisor: _supervisorController.text.trim().isEmpty
          ? null
          : _supervisorController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduledDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduledDate = picked);
  }

  void _submit(BuildContext context, String factoryId) {
    if (!_formKey.currentState!.validate()) return;
    final delivery = _buildDelivery(factoryId);
    if (delivery == null) return;
    context.read<DeliveryFormBloc>().add(DeliveryFormSubmitted(delivery));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryFormBloc, DeliveryFormState>(
      listener: (context, state) {
        if (state.status == DeliveryFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.deliverySaved)),
          );
          context.pop(true);
        }
        if (state.status == DeliveryFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
        if (state.status == DeliveryFormStatus.ready &&
            state.selectedOrder != null &&
            _selectedOrderId != state.selectedOrder!.id) {
          _syncFromOrder(state.selectedOrder);
          setState(() {});
        }
      },
      builder: (context, state) {
        if (state.status == DeliveryFormStatus.loading ||
            state.status == DeliveryFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.scheduleDelivery)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == DeliveryFormStatus.failure &&
            state.eligibleOrders.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.scheduleDelivery)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  state.errorMessage ?? AppStrings.noDeliveryEligibleOrders,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final isSaving = state.status == DeliveryFormStatus.saving;

        if (widget.salesOrderId != null &&
            _selectedOrderId == null &&
            state.selectedOrder != null) {
          _syncFromOrder(state.selectedOrder);
        }

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.scheduleDelivery)),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: AppStrings.linkedSalesOrder,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (state.eligibleOrders.isEmpty)
                          Text(AppStrings.noDeliveryEligibleOrders)
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _selectedOrderId,
                            decoration: const InputDecoration(
                              labelText: AppStrings.selectSalesOrder,
                            ),
                            items: state.eligibleOrders
                                .map(
                                  (order) => DropdownMenuItem(
                                    value: order.id,
                                    child: Text(
                                      '${order.orderNumber} · ${order.customerName}',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: isSaving
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    context.read<DeliveryFormBloc>().add(
                                          DeliveryFormSalesOrderSelected(value),
                                        );
                                  },
                            validator: (value) =>
                                value == null ? 'Select a sales order' : null,
                          ),
                      ],
                    ),
                  ),
                ),
                if (_selectedOrderId != null) ...[
                  SettingsSection(
                    title: AppStrings.deliveryDetails,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _addressController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.deliveryAddress,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 2,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Delivery address is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(AppStrings.scheduledDeliveryDate),
                            subtitle: Text(DateFormat.yMMMd().format(_scheduledDate)),
                            trailing: const Icon(Icons.calendar_today_outlined),
                            onTap: isSaving ? null : _pickDate,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _vehicleController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.deliveryVehicleNumber,
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String?>(
                            initialValue: _selectedDriverId,
                            decoration: const InputDecoration(
                              labelText: AppStrings.selectDriver,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(AppStrings.notSpecified),
                              ),
                              ...state.employees.map(
                                (employee) => DropdownMenuItem(
                                  value: employee.id,
                                  child: Text(employee.fullName),
                                ),
                              ),
                            ],
                            onChanged: isSaving
                                ? null
                                : (value) =>
                                    _onDriverSelected(value, state.employees),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _driverNameController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.driverName,
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _supervisorController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.loadingSupervisor,
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SettingsSection(
                    title: AppStrings.itemsToDeliver,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: _lineItems.map((fields) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fields.item.displayLabel,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: fields.quantityController,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${AppStrings.scheduledQuantity} (${fields.item.quantityUnit.label})',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Quantity is required';
                                    }
                                    final qty = double.tryParse(value.trim());
                                    if (qty == null || qty <= 0) {
                                      return 'Enter a valid quantity';
                                    }
                                    return null;
                                  },
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
                      child: TextFormField(
                        controller: _notesController,
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
                      onPressed: isSaving
                          ? null
                          : () {
                              final factoryId = readFactoryId(context);
                              if (factoryId == null) return;
                              _submit(context, factoryId);
                            },
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.saveDelivery),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LineItemFields {
  _LineItemFields({
    required this.item,
    required double initialQuantity,
  }) : quantityController =
            TextEditingController(text: initialQuantity.toString());

  final DeliveryLineItem item;
  final TextEditingController quantityController;

  void dispose() => quantityController.dispose();
}
