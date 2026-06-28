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
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

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

  String _appBarSubtitle({required bool isEditing, SalesOrder? order}) {
    if (isEditing) {
      return _baseOrder?.orderNumber ?? order?.orderNumber ?? '';
    }
    if (_customerId == null) return AppStrings.newSalesOrder;
    for (final customer in _customers) {
      if (customer.id == _customerId) return customer.name;
    }
    return AppStrings.newSalesOrder;
  }

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
              title: AppFormAppBarTitle(
                title: isEditing
                    ? AppStrings.editSalesOrder
                    : AppStrings.newSalesOrder,
                subtitle: _appBarSubtitle(isEditing: isEditing),
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
              title: AppFormAppBarTitle(
                title: isEditing
                    ? AppStrings.editSalesOrder
                    : AppStrings.newSalesOrder,
                subtitle: _appBarSubtitle(
                  isEditing: isEditing,
                  order: order,
                ),
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
        final fieldsEnabled = canEdit && !isSaving;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: isEditing
                  ? AppStrings.editSalesOrder
                  : AppStrings.newSalesOrder,
              subtitle: _appBarSubtitle(isEditing: isEditing, order: order),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.customerAndDates,
                  icon: Icons.person_outline,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(_customerId),
                        initialValue: _customerId,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.selectCustomer,
                        ),
                        items: _customers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(
                                  customer.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: fieldsEnabled
                            ? (value) => setState(() => _customerId = value)
                            : null,
                        validator: (value) =>
                            value == null ? 'Select a customer' : null,
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.orderDate,
                        value: DateFormat.yMMMd().format(_orderDate),
                        onTap: fieldsEnabled
                            ? () => _pickDate(
                                  initial: _orderDate,
                                  onPicked: (d) =>
                                      setState(() => _orderDate = d),
                                )
                            : null,
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.expectedDelivery,
                        value: _expectedDelivery == null
                            ? 'Not set'
                            : DateFormat.yMMMd().format(_expectedDelivery!),
                        onTap: fieldsEnabled
                            ? () => _pickDate(
                                  initial: _expectedDelivery ?? _orderDate,
                                  onPicked: (d) => setState(
                                    () => _expectedDelivery = d,
                                  ),
                                )
                            : null,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<SalesOrderSource>(
                        key: ValueKey(_orderSource),
                        initialValue: _orderSource,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.orderSource,
                        ),
                        items: SalesOrderSource.values
                            .map(
                              (source) => DropdownMenuItem(
                                value: source,
                                child: Text(
                                  source.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: fieldsEnabled
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
                JobWorkDetailSection(
                  title: AppStrings.lineItems,
                  icon: Icons.list_alt_outlined,
                  child: AppFormSectionBody(
                    children: [
                      for (var i = 0; i < _lineItems.length; i++) ...[
                        _LineItemEditor(
                          draft: _lineItems[i],
                          enabled: fieldsEnabled,
                          onChanged: () => setState(() {}),
                          onRemove: _lineItems.length > 1 && canEdit
                              ? () => setState(() {
                                    _lineItems[i].dispose();
                                    _lineItems.removeAt(i);
                                  })
                              : null,
                        ),
                        if (i < _lineItems.length - 1) AppFormFields.gap,
                      ],
                      if (canEdit) ...[
                        AppFormFields.gap,
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
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.pricingAgreement,
                  icon: Icons.payments_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormSummaryRow(
                        label: AppStrings.subtotal,
                        value: Formatters.currencyPkr(_subtotal),
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _orderDiscountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.orderDiscount,
                        ),
                        enabled: fieldsEnabled,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _taxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.taxAmount,
                        ),
                        enabled: fieldsEnabled,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      AppFormSummaryRow(
                        label: AppStrings.grandTotal,
                        value: Formatters.currencyPkr(_grandTotal),
                        highlight: true,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<PaymentTerms>(
                        key: ValueKey(_paymentTerms),
                        initialValue: _paymentTerms,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.paymentTerms,
                        ),
                        items: PaymentTerms.values
                            .map(
                              (terms) => DropdownMenuItem(
                                value: terms,
                                child: Text(
                                  terms.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: fieldsEnabled
                            ? (value) {
                                if (value != null) {
                                  setState(() => _paymentTerms = value);
                                }
                              }
                            : null,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _advanceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.advanceReceived,
                        ),
                        enabled: fieldsEnabled,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      AppFormSummaryRow(
                        label: AppStrings.balanceDue,
                        value: Formatters.currencyPkr(_balanceDue),
                        highlight: true,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.deliveryDetails,
                  icon: Icons.local_shipping_outlined,
                  child: AppFormSectionBody(
                    children: [
                      TextFormField(
                        controller: _deliveryAddressController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.deliveryAddress,
                        ),
                        maxLines: 2,
                        enabled: fieldsEnabled,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _specialInstructionsController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.specialInstructions,
                        ),
                        maxLines: 3,
                        enabled: fieldsEnabled,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: canEdit
              ? AppFormBottomBar(
                  label: isEditing
                      ? AppStrings.saveChanges
                      : AppStrings.saveSalesOrder,
                  isLoading: isSaving,
                  onPressed: _submit,
                )
              : null,
        );
      },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.4);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppStrings.lineItem,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    onPressed: enabled ? onRemove : null,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<SalesProductType>(
              key: ValueKey(draft.productType),
              initialValue: draft.productType,
              style: AppFormFields.valueStyle(context),
              decoration: AppFormFields.decoration(
                context,
                label: AppStrings.productType,
              ),
              items: SalesProductType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(
                        type.label,
                        style: const TextStyle(fontSize: 13),
                      ),
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
            AppFormFields.gap,
            DropdownButtonFormField<String>(
              key: ValueKey(draft.marbleVariety),
              initialValue: _resolveMarbleVariety(draft.marbleVariety),
              style: AppFormFields.valueStyle(context),
              decoration: AppFormFields.decoration(
                context,
                label: AppStrings.marbleVariety,
              ),
              items: _marbleVarietyItems(draft.marbleVariety)
                  .map(
                    (variety) => DropdownMenuItem(
                      value: variety,
                      child: Text(
                        variety,
                        style: const TextStyle(fontSize: 13),
                      ),
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
            AppFormFields.gap,
            TextFormField(
              controller: draft.sizeController,
              style: AppFormFields.valueStyle(context),
              decoration: AppFormFields.decoration(
                context,
                label: AppStrings.sizeThickness,
              ),
              enabled: enabled,
              onChanged: (_) => onChanged(),
            ),
            AppFormFields.gap,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: AppStrings.quantity,
                    ),
                    enabled: enabled,
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<SalesQuantityUnit>(
                    key: ValueKey(draft.quantityUnit),
                    initialValue: draft.quantityUnit,
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: AppStrings.unit,
                    ),
                    items: SalesQuantityUnit.values
                        .map(
                          (unit) => DropdownMenuItem(
                            value: unit,
                            child: Text(
                              unit.label,
                              style: const TextStyle(fontSize: 13),
                            ),
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
            AppFormFields.gap,
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: draft.rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: AppStrings.unitRate,
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
                    style: AppFormFields.valueStyle(context),
                    decoration: AppFormFields.decoration(
                      context,
                      label: AppStrings.discountPercent,
                    ),
                    enabled: enabled,
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            AppFormFields.gap,
            AppFormSummaryRow(
              label: AppStrings.lineTotal,
              value: Formatters.currencyPkr(draft.lineTotal),
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
