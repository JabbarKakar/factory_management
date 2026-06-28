import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/delivery/delivery_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/services/delivery_quantity_helper.dart';
import '../../../domain/entities/delivery.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/delivery_enums.dart';
import '../../utils/auth_context.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

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
  String? _syncSignature;
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

  void _syncFromRemaining(SalesOrder order, List<DeliveryRemainingLine> lines) {
    for (final item in _lineItems) {
      item.dispose();
    }
    _lineItems.clear();

    _selectedOrderId = order.id;
    _addressController.text = order.deliveryAddress ?? '';
    _scheduledDate = order.expectedDeliveryDate ?? DateTime.now();

    for (final line in lines) {
      if (line.remainingQuantity <= 0) continue;
      _lineItems.add(
        _LineItemFields(
          item: line.lineItem.copyWith(quantity: line.remainingQuantity),
          initialQuantity: line.remainingQuantity,
          maxRemaining: line.remainingQuantity,
          orderedQuantity: line.orderedQuantity,
        ),
      );
    }
  }

  void _maybeSyncFromState(DeliveryFormState state) {
    final order = state.selectedOrder;
    if (order == null) return;

    final signature =
        '${order.id}:${state.remainingLines.map((line) => line.remainingQuantity).join(',')}';
    if (_syncSignature == signature) return;
    _syncSignature = signature;
    _syncFromRemaining(order, state.remainingLines);
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

  String _appBarSubtitle(DeliveryFormState state) {
    final order = state.selectedOrder;
    if (order != null) {
      return '${order.orderNumber} · ${order.customerName}';
    }
    return AppStrings.scheduleDelivery;
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
            state.selectedOrder != null) {
          _maybeSyncFromState(state);
          setState(() {});
        }
      },
      builder: (context, state) {
        if (state.status == DeliveryFormStatus.loading ||
            state.status == DeliveryFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.scheduleDelivery,
                subtitle: AppStrings.scheduleDelivery,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == DeliveryFormStatus.failure &&
            state.eligibleOrders.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: AppFormAppBarTitle(
                title: AppStrings.scheduleDelivery,
                subtitle: AppStrings.scheduleDelivery,
              ),
            ),
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
        final hasRemaining = state.hasRemainingQuantity;

        if (widget.salesOrderId != null &&
            state.selectedOrder != null &&
            _syncSignature == null) {
          _maybeSyncFromState(state);
        }

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: AppStrings.scheduleDelivery,
              subtitle: _appBarSubtitle(state),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.linkedSalesOrder,
                  icon: Icons.receipt_long_outlined,
                  child: AppFormSectionBody(
                    children: [
                      if (state.eligibleOrders.isEmpty)
                        Text(
                          AppStrings.noDeliveryEligibleOrders,
                          style: AppFormFields.valueStyle(context),
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: _selectedOrderId,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.selectSalesOrder,
                          ),
                          items: state.eligibleOrders
                              .map(
                                (order) => DropdownMenuItem(
                                  value: order.id,
                                  child: Text(
                                    '${order.orderNumber} · ${order.customerName}',
                                    style: const TextStyle(fontSize: 13),
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
                if (_selectedOrderId != null) ...[
                  JobWorkDetailSection(
                    title: AppStrings.deliveryDetails,
                    icon: Icons.local_shipping_outlined,
                    child: AppFormSectionBody(
                      children: [
                        TextFormField(
                          controller: _addressController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.deliveryAddress,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 2,
                          enabled: !isSaving,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Delivery address is required';
                            }
                            return null;
                          },
                        ),
                        AppFormFields.gap,
                        AppFormDateField(
                          label: AppStrings.scheduledDeliveryDate,
                          value: DateFormat.yMMMd().format(_scheduledDate),
                          onTap: isSaving ? null : _pickDate,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _vehicleController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.deliveryVehicleNumber,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        DropdownButtonFormField<String?>(
                          initialValue: _selectedDriverId,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.selectDriver,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                AppStrings.notSpecified,
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                            ...state.employees.map(
                              (employee) => DropdownMenuItem(
                                value: employee.id,
                                child: Text(
                                  employee.fullName,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) =>
                                  _onDriverSelected(value, state.employees),
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _driverNameController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.driverName,
                          ),
                          textCapitalization: TextCapitalization.words,
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _supervisorController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.loadingSupervisor,
                          ),
                          textCapitalization: TextCapitalization.words,
                          enabled: !isSaving,
                        ),
                      ],
                    ),
                  ),
                  JobWorkDetailSection(
                    title: AppStrings.itemsToDeliver,
                    icon: Icons.inventory_2_outlined,
                    child: AppFormSectionBody(
                      children: [
                        if (!hasRemaining)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              AppStrings.noRemainingQuantity,
                              style: AppFormFields.valueStyle(context).copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ..._lineItems.map((fields) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fields.item.displayLabel,
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
                                  '${fields.maxRemaining.toStringAsFixed(1)} of '
                                  '${fields.orderedQuantity.toStringAsFixed(1)} '
                                  '${fields.item.quantityUnit.label} '
                                  '${AppStrings.remainingQuantityHint}',
                                  style: AppFormFields.labelStyle(context),
                                ),
                                AppFormFields.gap,
                                TextFormField(
                                  controller: fields.quantityController,
                                  style: AppFormFields.valueStyle(context),
                                  decoration: AppFormFields.decoration(
                                    context,
                                    label:
                                        '${AppStrings.scheduledQuantity} (${fields.item.quantityUnit.label})',
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  enabled: !isSaving,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Quantity is required';
                                    }
                                    final qty =
                                        double.tryParse(value.trim());
                                    if (qty == null || qty <= 0) {
                                      return 'Enter a valid quantity';
                                    }
                                    if (qty > fields.maxRemaining) {
                                      return 'Cannot exceed '
                                          '${fields.maxRemaining.toStringAsFixed(1)} '
                                          '${fields.item.quantityUnit.label}';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  if (hasRemaining)
                    JobWorkDetailSection(
                      title: AppStrings.notes,
                      icon: Icons.notes_outlined,
                      child: AppFormSectionBody(
                        children: [
                          TextFormField(
                            controller: _notesController,
                            style: AppFormFields.valueStyle(context),
                            decoration: AppFormFields.decoration(
                              context,
                              label: AppStrings.notes,
                            ),
                            maxLines: 3,
                            enabled: !isSaving,
                          ),
                        ],
                      ),
                    ),
                  if (hasRemaining)
                    AppFormSubmitBar(
                      label: AppStrings.saveDelivery,
                      isLoading: isSaving,
                      onPressed: isSaving
                          ? null
                          : () {
                              final factoryId = readFactoryId(context);
                              if (factoryId == null) return;
                              _submit(context, factoryId);
                            },
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
    required this.maxRemaining,
    required this.orderedQuantity,
  }) : quantityController =
            TextEditingController(text: initialQuantity.toString());

  final DeliveryLineItem item;
  final double maxRemaining;
  final double orderedQuantity;
  final TextEditingController quantityController;

  void dispose() => quantityController.dispose();
}
