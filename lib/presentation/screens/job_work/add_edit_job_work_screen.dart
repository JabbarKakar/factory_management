import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/marble_data.dart';
import '../../../core/constants/mine_locations.dart';
import '../../../core/constants/mine_owners.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/enums/customer_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/job_work_size_selector.dart';

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

  String? _mineLocation;
  String? _mineOwner;

  String _marbleVariety = MarbleData.varieties.first;
  CuttingStrategy _cuttingStrategy = CuttingStrategy.gangSaw;
  TargetProduct _targetProduct = TargetProduct.slabs;
  final Set<String> _selectedSmallSizes = {};
  final Set<String> _selectedLargeSizes = {};
  final Set<String> _selectedLegacySizes = {};
  String _thickness = MarbleData.jobWorkThicknesses.first;
  FinishType _finish = FinishType.unpolished;
  PricingModel _pricingModel = PricingModel.perTon;
  PaymentTerms _paymentTerms = PaymentTerms.cash;

  final _blockCountController = TextEditingController(text: '1');
  final _totalTonsController = TextEditingController();
  final _totalVolumeController = TextEditingController();
  final _blockDimensionsController = TextEditingController();
  final _conditionNotesController = TextEditingController();
  final _vehicleController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _agreedRateController = TextEditingController();
  final _smallStockPriceController = TextEditingController();
  final _largeStockPriceController = TextEditingController();
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
    _specialInstructionsController.dispose();
    _agreedRateController.dispose();
    _smallStockPriceController.dispose();
    _largeStockPriceController.dispose();
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
    if (MineLocations.contains(order.mineLocation)) {
      _mineLocation = order.mineLocation;
      _mineOwner = MineOwners.normalizeOwnerForLocation(
        _mineLocation,
        order.mineOwner,
      );
    } else {
      _mineLocation = null;
      _mineOwner = null;
    }
    _marbleVariety = MarbleData.varieties.contains(order.marbleVariety)
        ? order.marbleVariety
        : MarbleData.varieties.first;
    _cuttingStrategy = order.cuttingStrategy;
    _targetProduct = order.targetProduct;
    _selectedSmallSizes.addAll(order.smallSizes);
    _selectedLargeSizes.addAll(order.largeSizes);
    _selectedLegacySizes.addAll(order.legacySizes);
    _thickness = order.thickness.isNotEmpty
        ? order.thickness
        : MarbleData.jobWorkThicknesses.first;
    _finish = order.finish;
    _pricingModel = order.pricingModel;
    _paymentTerms = order.paymentTerms;

    _blockCountController.text = order.blockCount.toString();
    _totalTonsController.text = order.totalTons.toString();
    _totalVolumeController.text = order.totalVolumeM3?.toString() ?? '';
    _blockDimensionsController.text = order.blockDimensions ?? '';
    _conditionNotesController.text = order.conditionNotes ?? '';
    _vehicleController.text = order.vehicleNumber ?? '';
    _specialInstructionsController.text = order.specialInstructions ?? '';
    if (order.agreedRate > 0) {
      _agreedRateController.text = order.agreedRate.toStringAsFixed(0);
    }
    if (order.smallStockPrice > 0) {
      _smallStockPriceController.text = order.smallStockPrice.toStringAsFixed(0);
    } else if (order.agreedRate > 0 && order.smallSizes.isNotEmpty) {
      _smallStockPriceController.text = order.agreedRate.toStringAsFixed(0);
    }
    if (order.largeStockPrice > 0) {
      _largeStockPriceController.text = order.largeStockPrice.toStringAsFixed(0);
    } else if (order.agreedRate > 0 && order.largeSizes.isNotEmpty) {
      _largeStockPriceController.text = order.agreedRate.toStringAsFixed(0);
    }
    _advanceController.text = order.advanceReceived.toStringAsFixed(0);
  }

  double _parse(String value) => double.tryParse(value.trim()) ?? 0;

  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

  bool get _hasSizeSelection =>
      _selectedSmallSizes.isNotEmpty ||
      _selectedLargeSizes.isNotEmpty ||
      _selectedLegacySizes.isNotEmpty;

  String _agreedRateLabel() => switch (_pricingModel) {
        PricingModel.perTon => AppStrings.ratePerTon,
        PricingModel.perSqFt => AppStrings.ratePerSqFt,
        PricingModel.perBlock => AppStrings.ratePerBlock,
        PricingModel.lumpSum => AppStrings.lumpSumRate,
      };

  List<String> get _mineOwnerOptions => MineOwners.forLocation(_mineLocation);

  List<String> _thicknessItems(String selected) {
    final options = List<String>.from(MarbleData.jobWorkThicknesses);
    if (selected.isNotEmpty && !options.contains(selected)) {
      options.insert(0, selected);
    }
    return options;
  }

  void _onMineLocationChanged(String? location) {
    setState(() {
      _mineLocation = location;
      if (_mineOwner != null &&
          !MineOwners.forLocation(location).contains(_mineOwner)) {
        _mineOwner = null;
      }
    });
  }

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

    final advance = _parse(_advanceController.text);

    return base.copyWith(
      customerId: customer.id,
      customerName: customer.name,
      receivedDate: _receivedDate,
      expectedCompletionDate: _expectedCompletion,
      mineLocation: _mineLocation,
      mineOwner: _mineOwner,
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
      smallSizes: _selectedSmallSizes.toList(),
      largeSizes: _selectedLargeSizes.toList(),
      legacySizes: _selectedLegacySizes.toList(),
      thickness: _thickness,
      finish: _finish,
      specialInstructions: _specialInstructionsController.text.trim().isEmpty
          ? null
          : _specialInstructionsController.text.trim(),
      pricingModel: _pricingModel,
      agreedRate: _parse(_agreedRateController.text),
      smallStockPrice: _parse(_smallStockPriceController.text),
      largeStockPrice: _parse(_largeStockPriceController.text),
      finalCuttingCharges: base.finalCuttingCharges,
      advanceReceived: advance,
      balanceDue: base.finalCuttingCharges > 0
          ? base.finalCuttingCharges - advance
          : 0,
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
    if (_selectedSmallSizes.isEmpty &&
        _selectedLargeSizes.isEmpty &&
        _selectedLegacySizes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectAtLeastOneSize)),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing
                      ? AppStrings.editJobWorkOrder
                      : AppStrings.newJobWorkOrder,
                ),
                Text(
                  isEditing
                      ? (state.order?.jobWorkNumber ?? '')
                      : (_selectedCustomer?.name ?? AppStrings.newJobWorkOrder),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
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
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.customerAndDates,
                  icon: Icons.person_outline,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(customerDropdownValue),
                        initialValue: customerDropdownValue,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.selectCustomer,
                        ),
                        items: state.eligibleCustomers
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(
                                  c.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) => setState(() => _customerId = value),
                        validator: (value) =>
                            value == null ? 'Select a customer' : null,
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.receivedDate,
                        value: DateFormat.yMMMd().format(_receivedDate),
                        onTap: isSaving
                            ? null
                            : () => _pickDate(
                                  initial: _receivedDate,
                                  onPicked: (d) =>
                                      setState(() => _receivedDate = d),
                                ),
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.expectedCompletion,
                        value: _expectedCompletion == null
                            ? 'Not set'
                            : DateFormat.yMMMd().format(_expectedCompletion!),
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
                JobWorkDetailSection(
                  title: AppStrings.inputMaterial,
                  icon: Icons.inventory_2_outlined,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(_mineLocation),
                        initialValue: _mineLocation,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.mineLocation,
                        ),
                        items: MineLocations.all
                            .map(
                              (location) => DropdownMenuItem(
                                value: location,
                                child: Text(
                                  location,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving ? null : _onMineLocationChanged,
                        validator: (value) => value == null
                            ? AppStrings.mineLocationRequired
                            : null,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<String>(
                        key: ValueKey('$_mineLocation-$_mineOwner'),
                        initialValue: _mineOwnerOptions.contains(_mineOwner)
                            ? _mineOwner
                            : null,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.mineOwner,
                        ),
                        items: _mineOwnerOptions
                            .map(
                              (owner) => DropdownMenuItem(
                                value: owner,
                                child: Text(
                                  owner,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: _mineLocation == null || isSaving
                            ? null
                            : (value) => setState(() => _mineOwner = value),
                        validator: (value) {
                          if (_mineLocation == null) {
                            return AppStrings.mineLocationRequired;
                          }
                          if (value == null) {
                            return AppStrings.mineOwnerRequired;
                          }
                          if (!MineOwners.isValidCombination(
                            _mineLocation,
                            value,
                          )) {
                            return AppStrings.mineOwnerRequired;
                          }
                          return null;
                        },
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<String>(
                        key: ValueKey(_marbleVariety),
                        initialValue: _marbleVariety,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.marbleVariety,
                        ),
                        items: MarbleData.varieties
                            .map(
                              (v) => DropdownMenuItem(
                                value: v,
                                child: Text(v, style: const TextStyle(fontSize: 13)),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) => setState(() => _marbleVariety = v!),
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _blockCountController,
                        keyboardType: TextInputType.number,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.blockCount,
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
                      AppFormFields.gap,
                      TextFormField(
                        controller: _totalTonsController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.totalTons,
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
                      AppFormFields.gap,
                      TextFormField(
                        controller: _totalVolumeController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.totalVolume,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _blockDimensionsController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.blockDimensions,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _conditionNotesController,
                        maxLines: 2,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.conditionNotes,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _vehicleController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.vehicleNumber,
                        ),
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.cuttingSpecification,
                  icon: Icons.content_cut_outlined,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<CuttingStrategy>(
                        key: ValueKey(_cuttingStrategy),
                        initialValue: _cuttingStrategy,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.cuttingStrategy,
                        ),
                        items: CuttingStrategy.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) => setState(() => _cuttingStrategy = v!),
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<TargetProduct>(
                        key: ValueKey(_targetProduct),
                        initialValue: _targetProduct,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.targetProduct,
                        ),
                        items: TargetProduct.values
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) => setState(() => _targetProduct = v!),
                      ),
                      AppFormFields.gap,
                      JobWorkSizeSelector(
                        selectedSmall: _selectedSmallSizes,
                        selectedLarge: _selectedLargeSizes,
                        selectedLegacy: _selectedLegacySizes,
                        enabled: !isSaving,
                        onToggle: (size, value, category) {
                          setState(() {
                            final target = switch (category) {
                              JobWorkSizeCategory.small => _selectedSmallSizes,
                              JobWorkSizeCategory.large => _selectedLargeSizes,
                              JobWorkSizeCategory.legacy => _selectedLegacySizes,
                            };
                            if (value) {
                              target.add(size);
                            } else {
                              target.remove(size);
                            }
                          });
                        },
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<String>(
                        key: ValueKey(_thickness),
                        initialValue: _thickness,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.thickness,
                        ),
                        items: _thicknessItems(_thickness)
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t, style: const TextStyle(fontSize: 13)),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) => setState(() => _thickness = v!),
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<FinishType>(
                        key: ValueKey(_finish),
                        initialValue: _finish,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.finishRequired,
                        ),
                        items: FinishType.values
                            .map(
                              (f) => DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) => setState(() => _finish = v!),
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _specialInstructionsController,
                        maxLines: 3,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.specialInstructions,
                        ),
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.pricingAgreement,
                  icon: Icons.payments_outlined,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<PricingModel>(
                        key: ValueKey(_pricingModel),
                        initialValue: _pricingModel,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.pricingModel,
                        ),
                        items: PricingModel.values
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  m.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) => setState(() => _pricingModel = v!),
                      ),
                      if (!_hasSizeSelection ||
                          _pricingModel == PricingModel.perTon ||
                          _pricingModel == PricingModel.perBlock ||
                          _pricingModel == PricingModel.lumpSum) ...[
                        AppFormFields.gap,
                        TextFormField(
                          controller: _agreedRateController,
                          keyboardType: TextInputType.number,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: _agreedRateLabel(),
                          ),
                          validator: (v) {
                            if (!_hasSizeSelection && _parse(v ?? '') <= 0) {
                              return AppStrings.agreedRateRequired;
                            }
                            if (_hasSizeSelection &&
                                _pricingModel != PricingModel.perSqFt &&
                                _parse(_smallStockPriceController.text) <= 0 &&
                                _parse(_largeStockPriceController.text) <= 0 &&
                                _parse(v ?? '') <= 0) {
                              return AppStrings.agreedRateRequired;
                            }
                            return null;
                          },
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      if (_pricingModel == PricingModel.perSqFt) ...[
                        AppFormFields.gap,
                        TextFormField(
                          controller: _agreedRateController,
                          keyboardType: TextInputType.number,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.ratePerSqFt,
                          ),
                          validator: (v) {
                            if (_parse(_smallStockPriceController.text) <= 0 &&
                                _parse(_largeStockPriceController.text) <= 0 &&
                                _parse(v ?? '') <= 0) {
                              return AppStrings.agreedRateRequired;
                            }
                            return null;
                          },
                          enabled: !isSaving,
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                      if (_hasSizeSelection) ...[
                        AppFormFields.gap,
                        TextFormField(
                        controller: _smallStockPriceController,
                        keyboardType: TextInputType.number,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.smallStockPrice,
                        ),
                        validator: (v) {
                          if (_selectedSmallSizes.isNotEmpty ||
                              _selectedLegacySizes.isNotEmpty) {
                            if (_parse(v ?? '') <= 0) {
                              return AppStrings.smallStockPriceRequired;
                            }
                          }
                          return null;
                        },
                        enabled: !isSaving,
                        onChanged: (_) => setState(() {}),
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _largeStockPriceController,
                        keyboardType: TextInputType.number,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.largeStockPrice,
                        ),
                        validator: (v) {
                          if (_selectedLargeSizes.isNotEmpty) {
                            if (_parse(v ?? '') <= 0) {
                              return AppStrings.largeStockPriceRequired;
                            }
                          }
                          return null;
                        },
                        enabled: !isSaving,
                        onChanged: (_) => setState(() {}),
                      ),
                      ],
                      AppFormFields.gap,
                      Text(
                        AppStrings.chargesFinalizedOnOutput,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              height: 1.35,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _advanceController,
                        keyboardType: TextInputType.number,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.advanceReceived,
                        ),
                        enabled: !isSaving,
                        onChanged: (_) => setState(() {}),
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
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(
                                  t.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (v) => setState(() => _paymentTerms = v!),
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.paymentDueDate,
                        value: _paymentDueDate == null
                            ? 'Not set'
                            : DateFormat.yMMMd().format(_paymentDueDate!),
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
                AppFormSubmitBar(
                  label: isEditing
                      ? AppStrings.saveChanges
                      : AppStrings.saveJobWorkOrder,
                  isLoading: isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
