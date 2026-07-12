import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_load_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/marble_data.dart';
import '../../../core/constants/mine_locations.dart';
import '../../../core/constants/mine_owners.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/enums/customer_enums.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/job_work_size_selector.dart';

class AddJobWorkLoadScreen extends StatefulWidget {
  const AddJobWorkLoadScreen({
    required this.jobWorkId,
    this.loadId,
    super.key,
  });

  final String jobWorkId;
  final String? loadId;

  @override
  State<AddJobWorkLoadScreen> createState() => _AddJobWorkLoadScreenState();
}

class _AddJobWorkLoadScreenState extends State<AddJobWorkLoadScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _receivedDate = DateTime.now();
  DateTime? _expectedCompletion;
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
  final _vehicleController = TextEditingController();
  final _conditionNotesController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _agreedRateController = TextEditingController();
  final _smallStockPriceController = TextEditingController();
  final _largeStockPriceController = TextEditingController();
  final _advanceController = TextEditingController(text: '0');

  bool _populated = false;

  @override
  void dispose() {
    _blockCountController.dispose();
    _totalTonsController.dispose();
    _vehicleController.dispose();
    _conditionNotesController.dispose();
    _specialInstructionsController.dispose();
    _agreedRateController.dispose();
    _smallStockPriceController.dispose();
    _largeStockPriceController.dispose();
    _advanceController.dispose();
    super.dispose();
  }

  void _populate(JobWorkLoad draft) {
    if (_populated) return;
    _populated = true;
    _receivedDate = draft.receivedDate;
    _expectedCompletion = draft.expectedCompletionDate;
    _mineLocation = draft.mineLocation;
    _mineOwner = draft.mineOwner;
    _marbleVariety = draft.marbleVariety.isNotEmpty
        ? draft.marbleVariety
        : MarbleData.varieties.first;
    _cuttingStrategy = draft.cuttingStrategy;
    _targetProduct = draft.targetProduct;
    _selectedSmallSizes
      ..clear()
      ..addAll(draft.smallSizes);
    _selectedLargeSizes
      ..clear()
      ..addAll(draft.largeSizes);
    _selectedLegacySizes
      ..clear()
      ..addAll(draft.legacySizes);
    _thickness = draft.thickness.isNotEmpty
        ? draft.thickness
        : MarbleData.jobWorkThicknesses.first;
    _finish = draft.finish;
    _pricingModel = draft.pricingModel;
    _paymentTerms = draft.paymentTerms;
    _blockCountController.text = '${draft.blockCount}';
    _totalTonsController.text =
        draft.totalTons > 0 ? draft.totalTons.toString() : '';
    _vehicleController.text = draft.vehicleNumber ?? '';
    _conditionNotesController.text = draft.conditionNotes ?? '';
    _specialInstructionsController.text = draft.specialInstructions ?? '';
    _agreedRateController.text =
        draft.agreedRate > 0 ? draft.agreedRate.toString() : '';
    _smallStockPriceController.text =
        draft.smallStockPrice > 0 ? draft.smallStockPrice.toString() : '';
    _largeStockPriceController.text =
        draft.largeStockPrice > 0 ? draft.largeStockPrice.toString() : '';
  }

  Future<void> _pickDate({
    required DateTime initial,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) onPicked(picked);
  }

  double _parse(String value) => double.tryParse(value.trim()) ?? 0;
  int _parseInt(String value) => int.tryParse(value.trim()) ?? 0;

  void _submit(JobWorkLoad draft) {
    if (!_formKey.currentState!.validate()) return;

    final isEditing = context.read<JobWorkLoadFormBloc>().state.isEditing;
    final load = draft.copyWith(
      receivedDate: _receivedDate,
      expectedCompletionDate: _expectedCompletion,
      mineLocation: _mineLocation,
      mineOwner: _mineOwner,
      marbleVariety: _marbleVariety,
      blockCount: _parseInt(_blockCountController.text),
      totalTons: _parse(_totalTonsController.text),
      vehicleNumber: _vehicleController.text.trim().isEmpty
          ? null
          : _vehicleController.text.trim(),
      conditionNotes: _conditionNotesController.text.trim().isEmpty
          ? null
          : _conditionNotesController.text.trim(),
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
      advanceReceived: _parse(_advanceController.text),
      balanceDue: isEditing ? draft.balanceDue : 0,
      paymentTerms: _paymentTerms,
      status: isEditing ? draft.status : JobWorkStatus.agreed,
    );

    context.read<JobWorkLoadFormBloc>().add(JobWorkLoadFormSubmitted(load));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkLoadFormBloc, JobWorkLoadFormState>(
      listener: (context, state) {
        if (state.status == JobWorkLoadFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.isEditing
                    ? AppStrings.loadUpdated
                    : AppStrings.loadCreated,
              ),
            ),
          );
          context.pop(true);
        } else if (state.status == JobWorkLoadFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        final draft = state.draft;
        final parent = state.parentOrder;
        if (draft != null) _populate(draft);

        final isLoading = state.status == JobWorkLoadFormStatus.loading ||
            state.status == JobWorkLoadFormStatus.initial;
        final isSaving = state.status == JobWorkLoadFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              parent == null
                  ? (state.isEditing ? AppStrings.editLoad : AppStrings.addLoad)
                  : state.isEditing
                      ? '${AppStrings.editLoad} · ${parent.jobWorkNumber}'
                      : '${AppStrings.addLoad} · ${parent.jobWorkNumber}',
            ),
          ),
          body: isLoading || draft == null
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 12, bottom: 100),
                    children: [
                      if (parent != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            parent.customerName,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                      JobWorkDetailSection(
                        title: AppStrings.customerAndDates,
                        icon: Icons.event_outlined,
                        child: AppFormSectionBody(
                          children: [
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
                                  : DateFormat.yMMMd()
                                      .format(_expectedCompletion!),
                              onTap: isSaving
                                  ? null
                                  : () => _pickDate(
                                        initial: _expectedCompletion ??
                                            _receivedDate,
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
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _mineLocation = value;
                                        final owners =
                                            MineOwners.forLocation(value);
                                        if (_mineOwner == null ||
                                            !owners.contains(_mineOwner)) {
                                          _mineOwner = owners.isEmpty
                                              ? null
                                              : owners.first;
                                        }
                                      });
                                    },
                              validator: (value) => value == null
                                  ? AppStrings.mineLocationRequired
                                  : null,
                            ),
                            AppFormFields.gap,
                            DropdownButtonFormField<String>(
                              key: ValueKey('$_mineLocation|$_mineOwner'),
                              initialValue: _mineOwner,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: AppStrings.mineOwner,
                              ),
                              items: MineOwners.forLocation(_mineLocation)
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) =>
                                      setState(() => _mineOwner = value),
                              validator: (value) => value == null
                                  ? AppStrings.mineOwnerRequired
                                  : null,
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
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _marbleVariety = value);
                                      }
                                    },
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
                              enabled: !isSaving,
                              validator: (value) {
                                if (_parseInt(value ?? '') < 1) {
                                  return 'Enter at least 1 block';
                                }
                                return null;
                              },
                            ),
                            AppFormFields.gap,
                            TextFormField(
                              controller: _totalTonsController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: AppStrings.totalTons,
                              ),
                              enabled: !isSaving,
                              validator: (value) {
                                if (_parse(value ?? '') <= 0) {
                                  return 'Enter total tons';
                                }
                                return null;
                              },
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
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(
                                          () => _cuttingStrategy = value,
                                        );
                                      }
                                    },
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
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _targetProduct = value);
                                      }
                                    },
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
                                    JobWorkSizeCategory.small =>
                                      _selectedSmallSizes,
                                    JobWorkSizeCategory.large =>
                                      _selectedLargeSizes,
                                    JobWorkSizeCategory.legacy =>
                                      _selectedLegacySizes,
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
                              items: MarbleData.jobWorkThicknesses
                                  .map(
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _thickness = value);
                                      }
                                    },
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
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _finish = value);
                                      }
                                    },
                            ),
                            AppFormFields.gap,
                            TextFormField(
                              controller: _specialInstructionsController,
                              maxLines: 2,
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
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _pricingModel = value);
                                      }
                                    },
                            ),
                            AppFormFields.gap,
                            TextFormField(
                              controller: _agreedRateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: AppStrings.agreedRate,
                              ),
                              enabled: !isSaving,
                            ),
                            AppFormFields.gap,
                            TextFormField(
                              controller: _smallStockPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: AppStrings.smallStockPrice,
                              ),
                              enabled: !isSaving,
                            ),
                            AppFormFields.gap,
                            TextFormField(
                              controller: _largeStockPriceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: AppStrings.largeStockPrice,
                              ),
                              enabled: !isSaving,
                            ),
                            AppFormFields.gap,
                            TextFormField(
                              controller: _advanceController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: AppStrings.advanceReceived,
                              ),
                              enabled: !isSaving,
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
                                    (item) => DropdownMenuItem(
                                      value: item,
                                      child: Text(
                                        item.label,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value != null) {
                                        setState(() => _paymentTerms = value);
                                      }
                                    },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          bottomNavigationBar: draft == null
              ? null
              : SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: FilledButton(
                      onPressed: isSaving ? null : () => _submit(draft),
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.saveLoad),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
