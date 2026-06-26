import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/marble_data.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/customer_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/settings_section.dart';

class AddEditJobWorkScreen extends StatefulWidget {
  const AddEditJobWorkScreen({this.jobWorkId, super.key});

  final String? jobWorkId;

  @override
  State<AddEditJobWorkScreen> createState() => _AddEditJobWorkScreenState();
}

class _AddEditJobWorkScreenState extends State<AddEditJobWorkScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _customerId;
  DateTime _receivedDate = DateTime.now();
  DateTime? _expectedCompletion;
  DateTime? _paymentDueDate;

  String _marbleVariety = MarbleData.varieties.first;
  CuttingStrategy _cuttingStrategy = CuttingStrategy.gangSaw;
  TargetProduct _targetProduct = TargetProduct.slabs;
  final Set<String> _selectedSizes = {};
  String _thickness = MarbleData.thicknesses[2];
  FinishType _finish = FinishType.unpolished;
  PricingModel _pricingModel = PricingModel.perTon;
  PaymentTerms _paymentTerms = PaymentTerms.cash;

  final _blockCountController = TextEditingController(text: '1');
  final _totalTonsController = TextEditingController();
  final _totalVolumeController = TextEditingController();
  final _blockDimensionsController = TextEditingController();
  final _conditionNotesController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _expectedOutputController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _agreedRateController = TextEditingController();
  final _negotiatedAmountController = TextEditingController();
  final _advanceController = TextEditingController(text: '0');

  bool _populated = false;
  JobWorkOrder? _baseOrder;
  List<Customer> _customers = const [];

  @override
  void dispose() {
    _blockCountController.dispose();
    _totalTonsController.dispose();
    _totalVolumeController.dispose();
    _blockDimensionsController.dispose();
    _conditionNotesController.dispose();
    _vehicleController.dispose();
    _expectedOutputController.dispose();
    _specialInstructionsController.dispose();
    _agreedRateController.dispose();
    _negotiatedAmountController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _populate(JobWorkOrder order, List<Customer> customers) {
    if (_populated) return;
    _populated = true;
    _baseOrder = order;
    _customers = customers;

    final customerId = order.customerId.trim();
    if (customerId.isNotEmpty &&
        customers.any((customer) => customer.id == customerId)) {
      _customerId = customerId;
    } else if (customers.length == 1) {
      _customerId = customers.first.id;
    } else {
      _customerId = null;
    }

    _receivedDate = order.receivedDate;
    _expectedCompletion = order.expectedCompletionDate;
    _paymentDueDate = order.paymentDueDate;
    _marbleVariety = MarbleData.varieties.contains(order.marbleVariety)
        ? order.marbleVariety
        : MarbleData.varieties.first;
    _cuttingStrategy = order.cuttingStrategy;
    _targetProduct = order.targetProduct;
    _selectedSizes.addAll(order.sizes);
    _thickness = MarbleData.thicknesses.contains(order.thickness)
        ? order.thickness
        : MarbleData.thicknesses[2];
    _finish = order.finish;
    _pricingModel = order.pricingModel;
    _paymentTerms = order.paymentTerms;

    _blockCountController.text = order.blockCount.toString();
    _totalTonsController.text = order.totalTons.toString();
    _totalVolumeController.text = order.totalVolumeM3?.toString() ?? '';
    _blockDimensionsController.text = order.blockDimensions ?? '';
    _conditionNotesController.text = order.conditionNotes ?? '';
    _vehicleController.text = order.vehicleNumber ?? '';
    _expectedOutputController.text = order.expectedOutputSqFt?.toString() ?? '';
    _specialInstructionsController.text = order.specialInstructions ?? '';
    _agreedRateController.text = order.agreedRate.toStringAsFixed(0);
    _negotiatedAmountController.text =
        order.negotiatedFinalAmount.toStringAsFixed(0);
    _advanceController.text = order.advanceReceived.toStringAsFixed(0);
  }

  double _parse(String value) => double.tryParse(value.trim()) ?? 0;

  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

  double get _estimatedTotal => JobWorkOrder.calculateEstimatedTotal(
        model: _pricingModel,
        agreedRate: _parse(_agreedRateController.text),
        totalTons: _parse(_totalTonsController.text),
        blockCount: _parseInt(_blockCountController.text),
        expectedOutputSqFt: _parse(_expectedOutputController.text),
      );

  double get _balanceDue =>
      _parse(_negotiatedAmountController.text) - _parse(_advanceController.text);

  Customer? get _selectedCustomer {
    if (_customerId == null) return null;
    for (final customer in _customers) {
      if (customer.id == _customerId) return customer;
    }
    return null;
  }

  String? _customerDropdownValue(List<Customer> customers) {
    if (_customerId == null || _customerId!.isEmpty) return null;
    return customers.any((customer) => customer.id == _customerId)
        ? _customerId
        : null;
  }

  Future<void> _pickDate({
    required ValueChanged<DateTime> onPicked,
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  JobWorkOrder? _buildOrder() {
    final base = _baseOrder;
    if (base == null || _customerId == null) return null;

    final customer = _selectedCustomer;
    if (customer == null) return null;

    final negotiated = _parse(_negotiatedAmountController.text);
    final advance = _parse(_advanceController.text);

    return base.copyWith(
      customerId: customer.id,
      customerName: customer.name,
      receivedDate: _receivedDate,
      expectedCompletionDate: _expectedCompletion,
      marbleVariety: _marbleVariety,
      blockCount: _parseInt(_blockCountController.text),
      totalTons: _parse(_totalTonsController.text),
      totalVolumeM3: _totalVolumeController.text.trim().isEmpty
          ? null
          : _parse(_totalVolumeController.text),
      blockDimensions: _blockDimensionsController.text.trim().isEmpty
          ? null
          : _blockDimensionsController.text.trim(),
      conditionNotes: _conditionNotesController.text.trim().isEmpty
          ? null
          : _conditionNotesController.text.trim(),
      vehicleNumber: _vehicleController.text.trim().isEmpty
          ? null
          : _vehicleController.text.trim(),
      cuttingStrategy: _cuttingStrategy,
      targetProduct: _targetProduct,
      sizes: _selectedSizes.toList(),
      thickness: _thickness,
      finish: _finish,
      expectedOutputSqFt: _expectedOutputController.text.trim().isEmpty
          ? null
          : _parse(_expectedOutputController.text),
      specialInstructions: _specialInstructionsController.text.trim().isEmpty
          ? null
          : _specialInstructionsController.text.trim(),
      pricingModel: _pricingModel,
      agreedRate: _parse(_agreedRateController.text),
      estimatedTotal: _estimatedTotal,
      negotiatedFinalAmount: negotiated,
      advanceReceived: advance,
      balanceDue: negotiated - advance,
      paymentTerms: _paymentTerms,
      paymentDueDate: _paymentDueDate,
      status: JobWorkStatus.agreed,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectCustomer)),
      );
      return;
    }
    if (_selectedSizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one tile/slab size')),
      );
      return;
    }

    final order = _buildOrder();
    if (order == null) return;

    context.read<JobWorkFormBloc>().add(JobWorkFormSubmitted(order));
  }

  Future<void> _confirmCancel() async {
    final id = widget.jobWorkId;
    if (id == null) return;

    final formBloc = context.read<JobWorkFormBloc>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.cancelJobWorkTitle,
      message: AppStrings.cancelJobWorkMessage,
      confirmLabel: AppStrings.cancelOrder,
      destructive: true,
    );
    if (!confirmed) return;
    formBloc.add(JobWorkFormCancelRequested(id));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.jobWorkId != null;

    return BlocConsumer<JobWorkFormBloc, JobWorkFormState>(
      listener: (context, state) {
        if (state.status == JobWorkFormStatus.ready && state.order != null) {
          setState(() {
            _populate(state.order!, state.eligibleCustomers);
          });
        }
        if (state.status == JobWorkFormStatus.saved) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? AppStrings.jobWorkUpdated
                      : AppStrings.jobWorkCreated,
                ),
              ),
            );
          context.pop();
        }
        if (state.status == JobWorkFormStatus.cancelled) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(AppStrings.jobWorkCancelled)),
            );
          context.pop();
          if (context.canPop()) context.pop();
        }
        if (state.status == JobWorkFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkFormStatus.loading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                isEditing
                    ? AppStrings.editJobWorkOrder
                    : AppStrings.newJobWorkOrder,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (!isEditing &&
            state.eligibleCustomers.isEmpty &&
            state.status == JobWorkFormStatus.ready) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.newJobWorkOrder)),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppStrings.noJobWorkCustomers,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final isSaving = state.status == JobWorkFormStatus.saving;
        final customerDropdownValue =
            _customerDropdownValue(state.eligibleCustomers);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isEditing
                  ? AppStrings.editJobWorkOrder
                  : AppStrings.newJobWorkOrder,
            ),
            actions: [
              if (isEditing &&
                  state.order?.status.isActive == true)
                IconButton(
                  onPressed: isSaving ? null : _confirmCancel,
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: AppStrings.cancelOrder,
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: AppStrings.customerAndDates,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(customerDropdownValue),
                          initialValue: customerDropdownValue,
                          decoration: const InputDecoration(
                            labelText: AppStrings.selectCustomer,
                          ),
                          items: state.eligibleCustomers
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) =>
                                  setState(() => _customerId = value),
                          validator: (value) =>
                              value == null ? 'Select a customer' : null,
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.receivedDate),
                          subtitle:
                              Text(DateFormat.yMMMd().format(_receivedDate)),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: isSaving
                              ? null
                              : () => _pickDate(
                                    initial: _receivedDate,
                                    onPicked: (d) =>
                                        setState(() => _receivedDate = d),
                                  ),
                        ),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.expectedCompletion),
                          subtitle: Text(
                            _expectedCompletion == null
                                ? 'Not set'
                                : DateFormat.yMMMd()
                                    .format(_expectedCompletion!),
                          ),
                          trailing: const Icon(Icons.event),
                          onTap: isSaving
                              ? null
                              : () => _pickDate(
                                    initial:
                                        _expectedCompletion ?? _receivedDate,
                                    onPicked: (d) => setState(
                                      () => _expectedCompletion = d,
                                    ),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.inputMaterial,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(_marbleVariety),
                          initialValue: _marbleVariety,
                          decoration: const InputDecoration(
                            labelText: AppStrings.marbleVariety,
                          ),
                          items: MarbleData.varieties
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(v),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (v) => setState(() => _marbleVariety = v!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _blockCountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.blockCount,
                          ),
                          validator: (v) {
                            if (_parseInt(v ?? '') < 1) {
                              return 'Enter at least 1 block';
                            }
                            return null;
                          },
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _totalTonsController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: AppStrings.totalTons,
                          ),
                          validator: (v) {
                            if (_parse(v ?? '') <= 0) {
                              return 'Enter total tons';
                            }
                            return null;
                          },
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _totalVolumeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: AppStrings.totalVolume,
                          ),
                          enabled: !isSaving,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _blockDimensionsController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.blockDimensions,
                          ),
                          enabled: !isSaving,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _conditionNotesController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: AppStrings.conditionNotes,
                          ),
                          enabled: !isSaving,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _vehicleController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.vehicleNumber,
                          ),
                          enabled: !isSaving,
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.cuttingSpecification,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<CuttingStrategy>(
                          key: ValueKey(_cuttingStrategy),
                          initialValue: _cuttingStrategy,
                          decoration: const InputDecoration(
                            labelText: AppStrings.cuttingStrategy,
                          ),
                          items: CuttingStrategy.values
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (v) =>
                                  setState(() => _cuttingStrategy = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<TargetProduct>(
                          key: ValueKey(_targetProduct),
                          initialValue: _targetProduct,
                          decoration: const InputDecoration(
                            labelText: AppStrings.targetProduct,
                          ),
                          items: TargetProduct.values
                              .map(
                                (p) => DropdownMenuItem(
                                  value: p,
                                  child: Text(p.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (v) => setState(() => _targetProduct = v!),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppStrings.tileSlabSizes,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: MarbleData.commonSizes.map((size) {
                            final selected = _selectedSizes.contains(size);
                            return FilterChip(
                              label: Text(size),
                              selected: selected,
                              onSelected: isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        if (value) {
                                          _selectedSizes.add(size);
                                        } else {
                                          _selectedSizes.remove(size);
                                        }
                                      });
                                    },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_thickness),
                          initialValue: _thickness,
                          decoration: const InputDecoration(
                            labelText: AppStrings.thickness,
                          ),
                          items: MarbleData.thicknesses
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (v) => setState(() => _thickness = v!),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<FinishType>(
                          key: ValueKey(_finish),
                          initialValue: _finish,
                          decoration: const InputDecoration(
                            labelText: AppStrings.finishRequired,
                          ),
                          items: FinishType.values
                              .map(
                                (f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (v) => setState(() => _finish = v!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _expectedOutputController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: AppStrings.expectedOutput,
                          ),
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _specialInstructionsController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: AppStrings.specialInstructions,
                          ),
                          enabled: !isSaving,
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
                        DropdownButtonFormField<PricingModel>(
                          key: ValueKey(_pricingModel),
                          initialValue: _pricingModel,
                          decoration: const InputDecoration(
                            labelText: AppStrings.pricingModel,
                          ),
                          items: PricingModel.values
                              .map(
                                (m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (v) => setState(() => _pricingModel = v!),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _agreedRateController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.agreedRate,
                          ),
                          validator: (v) {
                            if (_parse(v ?? '') <= 0) {
                              return 'Enter agreed rate';
                            }
                            return null;
                          },
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: AppStrings.estimatedTotal,
                          value: '₨ ${_estimatedTotal.toStringAsFixed(0)}',
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _negotiatedAmountController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.negotiatedAmount,
                          ),
                          validator: (v) {
                            if (_parse(v ?? '') <= 0) {
                              return 'Enter final agreed amount';
                            }
                            return null;
                          },
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _advanceController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: AppStrings.advanceReceived,
                          ),
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _SummaryRow(
                          label: AppStrings.balanceDue,
                          value: '₨ ${_balanceDue.toStringAsFixed(0)}',
                          emphasized: true,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PaymentTerms>(
                          key: ValueKey(_paymentTerms),
                          initialValue: _paymentTerms,
                          decoration: const InputDecoration(
                            labelText: AppStrings.paymentTerms,
                          ),
                          items: PaymentTerms.values
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (v) => setState(() => _paymentTerms = v!),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text(AppStrings.paymentDueDate),
                          subtitle: Text(
                            _paymentDueDate == null
                                ? 'Not set'
                                : DateFormat.yMMMd().format(_paymentDueDate!),
                          ),
                          trailing: const Icon(Icons.event),
                          onTap: isSaving
                              ? null
                              : () => _pickDate(
                                    initial: _paymentDueDate ?? _receivedDate,
                                    onPicked: (d) =>
                                        setState(() => _paymentDueDate = d),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: ElevatedButton(
                    onPressed: isSaving ? null : _submit,
                    child: isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isEditing
                                ? AppStrings.saveChanges
                                : AppStrings.saveJobWorkOrder,
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: emphasized
              ? Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
