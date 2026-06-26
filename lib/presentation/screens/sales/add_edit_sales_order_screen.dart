import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/sales/sales_order_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/marble_data.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/sales_order.dart';
import '../../../domain/enums/customer_enums.dart';
import '../../../domain/enums/sales_enums.dart';
import '../../widgets/settings_section.dart';

class AddEditSalesOrderScreen extends StatefulWidget {
  const AddEditSalesOrderScreen({this.salesOrderId, super.key});

  final String? salesOrderId;

  @override
  State<AddEditSalesOrderScreen> createState() =>
      _AddEditSalesOrderScreenState();
}

class _AddEditSalesOrderScreenState extends State<AddEditSalesOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _customerId;
  DateTime _orderDate = DateTime.now();
  DateTime? _expectedDelivery;
  SalesOrderSource _orderSource = SalesOrderSource.walkIn;
  PaymentTerms _paymentTerms = PaymentTerms.cash;

  final _deliveryAddressController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _orderDiscountController = TextEditingController(text: '0');
  final _taxController = TextEditingController(text: '0');
  final _advanceController = TextEditingController(text: '0');

  final List<_LineItemDraft> _lineItems = [_LineItemDraft()];

  bool _populated = false;
  SalesOrder? _baseOrder;
  List<Customer> _customers = const [];

  @override
  void dispose() {
    _deliveryAddressController.dispose();
    _specialInstructionsController.dispose();
    _orderDiscountController.dispose();
    _taxController.dispose();
    _advanceController.dispose();
    for (final item in _lineItems) {
      item.dispose();
    }
    super.dispose();
  }

  void _populate(SalesOrder order, List<Customer> customers) {
    if (_populated) return;
    _populated = true;
    _baseOrder = order;
    _customers = customers;
    _customerId = order.customerId.isEmpty ? null : order.customerId;
    _orderDate = order.orderDate;
    _expectedDelivery = order.expectedDeliveryDate;
    _orderSource = order.orderSource;
    _paymentTerms = order.paymentTerms;
    _deliveryAddressController.text = order.deliveryAddress ?? '';
    _specialInstructionsController.text = order.specialInstructions ?? '';
    _orderDiscountController.text = order.orderDiscount.toStringAsFixed(0);
    _taxController.text = order.tax.toStringAsFixed(0);
    _advanceController.text = order.advanceReceived.toStringAsFixed(0);

    _lineItems.clear();
    if (order.lineItems.isEmpty) {
      _lineItems.add(_LineItemDraft());
    } else {
      for (final item in order.lineItems) {
        _lineItems.add(_LineItemDraft.fromEntity(item));
      }
    }
  }

  double get _subtotal =>
      _lineItems.fold<double>(0, (sum, item) => sum + item.lineTotal);

  double get _orderDiscount =>
      double.tryParse(_orderDiscountController.text.trim()) ?? 0;

  double get _tax => double.tryParse(_taxController.text.trim()) ?? 0;

  double get _advance =>
      double.tryParse(_advanceController.text.trim()) ?? 0;

  double get _grandTotal => SalesOrder.computeGrandTotal(
        subtotal: _subtotal,
        orderDiscount: _orderDiscount,
        tax: _tax,
      );

  double get _balanceDue =>
      (_grandTotal - _advance).clamp(0, double.infinity).toDouble();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) return;

    final customer = _customers.firstWhere(
      (c) => c.id == _customerId,
      orElse: () => _customers.first,
    );

    final lineItems = _lineItems
        .where((item) => item.hasContent)
        .map((item) => item.toEntity())
        .toList();

    if (lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.salesLineItemRequired)),
      );
      return;
    }

    final base = _baseOrder;
    final order = SalesOrder(
      id: base?.id ?? '',
      orderNumber: base?.orderNumber ?? '',
      factoryId: base?.factoryId ?? customer.factoryId,
      customerId: customer.id,
      customerName: customer.name,
      status: base?.status ?? SalesOrderStatus.received,
      orderDate: _orderDate,
      orderSource: _orderSource,
      deliveryAddress: _deliveryAddressController.text.trim().isEmpty
          ? null
          : _deliveryAddressController.text.trim(),
      expectedDeliveryDate: _expectedDelivery,
      lineItems: lineItems,
      subtotal: _subtotal,
      orderDiscount: _orderDiscount,
      tax: _tax,
      grandTotal: _grandTotal,
      paymentTerms: _paymentTerms,
      advanceReceived: _advance,
      balanceDue: _balanceDue,
      paymentDueDate: base?.paymentDueDate,
      specialInstructions: _specialInstructionsController.text.trim().isEmpty
          ? null
          : _specialInstructionsController.text.trim(),
      invoiceId: base?.invoiceId,
      createdAt: base?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    context.read<SalesOrderFormBloc>().add(SalesOrderFormSubmitted(order));
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.salesOrderId != null;

    return BlocConsumer<SalesOrderFormBloc, SalesOrderFormState>(
      listener: (context, state) {
        if (state.status == SalesOrderFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isEditing
                    ? AppStrings.salesOrderUpdated
                    : AppStrings.salesOrderCreated,
              ),
            ),
          );
          context.pop(true);
        }
        if (state.status == SalesOrderFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == SalesOrderFormStatus.loading ||
            state.status == SalesOrderFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                isEditing ? AppStrings.editSalesOrder : AppStrings.newSalesOrder,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final order = state.order;
        if (order != null) {
          _populate(order, state.eligibleCustomers);
        }

        if (_customers.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                isEditing ? AppStrings.editSalesOrder : AppStrings.newSalesOrder,
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppStrings.noSalesCustomers,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final isSaving = state.status == SalesOrderFormStatus.saving;
        final canEdit = order == null || order.status == SalesOrderStatus.received;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isEditing ? AppStrings.editSalesOrder : AppStrings.newSalesOrder,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                SettingsSection(
                  title: AppStrings.customerAndDates,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _customerId,
                          decoration: const InputDecoration(
                            labelText: AppStrings.selectCustomer,
                            border: OutlineInputBorder(),
                          ),
                          items: _customers
                              .map(
                                (customer) => DropdownMenuItem(
                                  value: customer.id,
                                  child: Text(customer.name),
                                ),
                              )
                              .toList(),
                          onChanged: canEdit && !isSaving
                              ? (value) => setState(() => _customerId = value)
                              : null,
                          validator: (value) =>
                              value == null ? 'Select a customer' : null,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.orderDate),
                          subtitle: Text(DateFormat.yMMMd().format(_orderDate)),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: canEdit && !isSaving
                              ? () => _pickDate(
                                    initial: _orderDate,
                                    onPicked: (d) =>
                                        setState(() => _orderDate = d),
                                  )
                              : null,
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.expectedDelivery),
                          subtitle: Text(
                            _expectedDelivery == null
                                ? 'Not set'
                                : DateFormat.yMMMd()
                                    .format(_expectedDelivery!),
                          ),
                          trailing: const Icon(Icons.event_outlined),
                          onTap: canEdit && !isSaving
                              ? () => _pickDate(
                                    initial: _expectedDelivery ?? _orderDate,
                                    onPicked: (d) => setState(
                                      () => _expectedDelivery = d,
                                    ),
                                  )
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<SalesOrderSource>(
                          initialValue: _orderSource,
                          decoration: const InputDecoration(
                            labelText: AppStrings.orderSource,
                            border: OutlineInputBorder(),
                          ),
                          items: SalesOrderSource.values
                              .map(
                                (source) => DropdownMenuItem(
                                  value: source,
                                  child: Text(source.label),
                                ),
                              )
                              .toList(),
                          onChanged: canEdit && !isSaving
                              ? (value) {
                                  if (value != null) {
                                    setState(() => _orderSource = value);
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.lineItems,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        for (var i = 0; i < _lineItems.length; i++) ...[
                          _LineItemEditor(
                            draft: _lineItems[i],
                            enabled: canEdit && !isSaving,
                            onChanged: () => setState(() {}),
                            onRemove: _lineItems.length > 1 && canEdit
                                ? () => setState(() {
                                      _lineItems[i].dispose();
                                      _lineItems.removeAt(i);
                                    })
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (canEdit)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: isSaving
                                  ? null
                                  : () => setState(
                                        () => _lineItems.add(_LineItemDraft()),
                                      ),
                              icon: const Icon(Icons.add),
                              label: const Text(AppStrings.addLineItem),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.pricingAgreement,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SummaryRow(
                          AppStrings.subtotal,
                          Formatters.currencyPkr(_subtotal),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _orderDiscountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: AppStrings.orderDiscount,
                            border: OutlineInputBorder(),
                          ),
                          enabled: canEdit && !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _taxController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: AppStrings.taxAmount,
                            border: OutlineInputBorder(),
                          ),
                          enabled: canEdit && !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          AppStrings.grandTotal,
                          Formatters.currencyPkr(_grandTotal),
                          bold: true,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PaymentTerms>(
                          initialValue: _paymentTerms,
                          decoration: const InputDecoration(
                            labelText: AppStrings.paymentTerms,
                            border: OutlineInputBorder(),
                          ),
                          items: PaymentTerms.values
                              .map(
                                (terms) => DropdownMenuItem(
                                  value: terms,
                                  child: Text(terms.label),
                                ),
                              )
                              .toList(),
                          onChanged: canEdit && !isSaving
                              ? (value) {
                                  if (value != null) {
                                    setState(() => _paymentTerms = value);
                                  }
                                }
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _advanceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: AppStrings.advanceReceived,
                            border: OutlineInputBorder(),
                          ),
                          enabled: canEdit && !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          AppStrings.balanceDue,
                          Formatters.currencyPkr(_balanceDue),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.deliveryDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _deliveryAddressController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.deliveryAddress,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                          enabled: canEdit && !isSaving,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _specialInstructionsController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.specialInstructions,
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                          enabled: canEdit && !isSaving,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: canEdit
              ? SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: isSaving ? null : _submit,
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              isEditing
                                  ? AppStrings.saveChanges
                                  : AppStrings.saveSalesOrder,
                            ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w600),
        ),
      ],
    );
  }
}

class _LineItemEditor extends StatelessWidget {
  const _LineItemEditor({
    required this.draft,
    required this.enabled,
    required this.onChanged,
    this.onRemove,
  });

  final _LineItemDraft draft;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.lineItem,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: enabled ? onRemove : null,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            DropdownButtonFormField<SalesProductType>(
              initialValue: draft.productType,
              decoration: const InputDecoration(
                labelText: AppStrings.productType,
                border: OutlineInputBorder(),
              ),
              items: SalesProductType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    ),
                  )
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        draft.productType = value;
                        onChanged();
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _resolveMarbleVariety(draft.marbleVariety),
              decoration: const InputDecoration(
                labelText: AppStrings.marbleVariety,
                border: OutlineInputBorder(),
              ),
              items: _marbleVarietyItems(draft.marbleVariety)
                  .map(
                    (variety) => DropdownMenuItem(
                      value: variety,
                      child: Text(variety),
                    ),
                  )
                  .toList(),
              onChanged: enabled
                  ? (value) {
                      if (value != null) {
                        draft.marbleVariety = value;
                        onChanged();
                      }
                    }
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: draft.sizeController,
              decoration: const InputDecoration(
                labelText: AppStrings.sizeThickness,
                border: OutlineInputBorder(),
              ),
              enabled: enabled,
              onChanged: (_) => onChanged(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.quantity,
                      border: OutlineInputBorder(),
                    ),
                    enabled: enabled,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<SalesQuantityUnit>(
                    initialValue: draft.quantityUnit,
                    decoration: const InputDecoration(
                      labelText: AppStrings.unit,
                      border: OutlineInputBorder(),
                    ),
                    items: SalesQuantityUnit.values
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(unit.label),
                          ),
                        )
                        .toList(),
                    onChanged: enabled
                        ? (value) {
                            if (value != null) {
                              draft.quantityUnit = value;
                              onChanged();
                            }
                          }
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.unitRate,
                      border: OutlineInputBorder(),
                    ),
                    enabled: enabled,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: draft.discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: AppStrings.discountPercent,
                      border: OutlineInputBorder(),
                    ),
                    enabled: enabled,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${AppStrings.lineTotal}: ${Formatters.currencyPkr(draft.lineTotal)}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LineItemDraft {
  _LineItemDraft();

  factory _LineItemDraft.fromEntity(SalesOrderLineItem item) {
    final draft = _LineItemDraft();
    draft.productType = item.productType;
    draft.marbleVariety = _resolveMarbleVariety(item.marbleVariety);
    draft.sizeController.text = item.sizeThickness;
    draft.quantityController.text = item.quantity.toString();
    draft.quantityUnit = item.quantityUnit;
    draft.rateController.text = item.unitRate.toString();
    draft.discountController.text = item.discountPercent.toString();
    return draft;
  }

  SalesProductType productType = SalesProductType.tile;
  String marbleVariety = MarbleData.varieties.first;
  SalesQuantityUnit quantityUnit = SalesQuantityUnit.sqFt;
  final sizeController = TextEditingController();
  final quantityController = TextEditingController();
  final rateController = TextEditingController();
  final discountController = TextEditingController(text: '0');

  bool get hasContent =>
      (double.tryParse(quantityController.text.trim()) ?? 0) > 0 &&
      (double.tryParse(rateController.text.trim()) ?? 0) > 0;

  double get lineTotal {
    final quantity = double.tryParse(quantityController.text.trim()) ?? 0;
    final rate = double.tryParse(rateController.text.trim()) ?? 0;
    final discount = double.tryParse(discountController.text.trim()) ?? 0;
    final gross = quantity * rate;
    return gross - (gross * discount / 100);
  }

  SalesOrderLineItem toEntity() {
    return SalesOrderLineItem(
      productType: productType,
      marbleVariety: marbleVariety,
      sizeThickness: sizeController.text.trim(),
      quantity: double.tryParse(quantityController.text.trim()) ?? 0,
      quantityUnit: quantityUnit,
      unitRate: double.tryParse(rateController.text.trim()) ?? 0,
      discountPercent: double.tryParse(discountController.text.trim()) ?? 0,
    );
  }

  void dispose() {
    sizeController.dispose();
    quantityController.dispose();
    rateController.dispose();
    discountController.dispose();
  }
}

String _resolveMarbleVariety(String value) {
  if (value.isNotEmpty) return value;
  return MarbleData.varieties.first;
}

List<String> _marbleVarietyItems(String selected) {
  final options = List<String>.from(MarbleData.varieties);
  final resolved = _resolveMarbleVariety(selected);
  if (!options.contains(resolved)) {
    options.insert(0, resolved);
  }
  return options;
}
