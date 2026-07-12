import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_output_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/job_work_block_progress.dart';
import '../../../core/utils/job_work_charges_calculator.dart';
import '../../../domain/entities/job_work_load.dart';
import '../../../domain/entities/job_work_output.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../../domain/enums/job_work_load_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/add_shift_log_dialog.dart';
import '../../widgets/job_work/job_work_block_progress_section.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/stock_output_form_controller.dart';
import '../../widgets/job_work/stock_output_recording_panel.dart';

class RecordJobWorkOutputScreen extends StatefulWidget {
  const RecordJobWorkOutputScreen({
    required this.jobWorkId,
    this.loadId,
    super.key,
  });

  final String jobWorkId;
  final String? loadId;

  @override
  State<RecordJobWorkOutputScreen> createState() =>
      _RecordJobWorkOutputScreenState();
}

class _RecordJobWorkOutputScreenState extends State<RecordJobWorkOutputScreen> {
  final _formKey = GlobalKey<FormState>();

  final _wasteController = TextEditingController();
  final _slurryController = TextEditingController();
  final _supervisorController = TextEditingController();
  final _notesController = TextEditingController();
  final _finalChargesController = TextEditingController();

  WasteUnit _wasteUnit = WasteUnit.tons;
  WasteDisposition _wasteDisposition = WasteDisposition.customerTakes;
  DateTime? _startDate;
  DateTime? _completionDate;
  bool _populated = false;
  bool _chargesManuallyEdited = false;
  List<JobWorkShiftLog> _shiftLogs = [];
  LoadStatus? _statusBeforeSubmit;
  StockOutputFormController? _stockController;
  String? _stockControllerLoadId;

  List<String> _smallSizesFor(JobWorkLoad load) =>
      [...load.smallSizes, ...load.legacySizes];

  @override
  void dispose() {
    _wasteController.dispose();
    _slurryController.dispose();
    _supervisorController.dispose();
    _notesController.dispose();
    _finalChargesController.dispose();
    _stockController?.dispose();
    super.dispose();
  }

  void _ensureStockController(JobWorkLoad load) {
    if (_stockControllerLoadId == load.id && _stockController != null) {
      return;
    }

    _stockController?.dispose();
    final output = load.output;
    _stockController = StockOutputFormController(
      smallSizes: _smallSizesFor(load),
      largeSizes: load.largeSizes,
      smallPricePerSqFt:
          JobWorkChargesCalculator.defaultSmallPricePerSqFtForLoad(load),
      largePricePerSqFt:
          JobWorkChargesCalculator.defaultLargePricePerSqFtForLoad(load),
      initialSmall: output?.smallStockOutputs ?? const [],
      initialLarge: output?.largeStockOutputs ?? const [],
    );
    _stockController!.addListener(_onStockChanged);
    _stockControllerLoadId = load.id;
  }

  void _onStockChanged() {
    if (mounted) {
      setState(() {
        _chargesManuallyEdited = false;
      });
    }
  }

  void _populate(JobWorkLoad load) {
    if (_populated) return;
    _populated = true;

    final output = load.output;
    if (output != null) {
      _wasteController.text = _formatNum(output.wasteAmount);
      _wasteUnit = output.wasteUnit;
      _wasteDisposition = output.wasteDisposition;
      _slurryController.text = output.slurryDust ?? '';
    }

    _shiftLogs = List<JobWorkShiftLog>.from(load.shiftLogs);

    final execution = load.execution;
    if (execution != null) {
      _startDate = execution.cuttingStartDate;
      _completionDate = execution.cuttingCompletionDate;
      _supervisorController.text = execution.supervisorName ?? '';
      _notesController.text = execution.progressNotes ?? '';
    }

    if (load.finalCuttingCharges > 0) {
      _finalChargesController.text =
          load.finalCuttingCharges.toStringAsFixed(0);
    }
  }

  void _syncCalculatedCharges(JobWorkLoad load, JobWorkOutput output) {
    if (_chargesManuallyEdited) return;
    final charges = JobWorkChargesCalculator.calculateForLoad(
      load: load,
      output: output,
      shiftLogs: _shiftLogs,
    );
    _finalChargesController.text =
        charges > 0 ? charges.toStringAsFixed(2) : '';
  }

  String _formatNum(double value) {
    if (value == 0) return '';
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }

  double _parse(String value) => double.tryParse(value.trim()) ?? 0;

  JobWorkOutput _buildDirectOutput() {
    final controller = _stockController!;
    return JobWorkChargesCalculator.outputFromStockRows(
      smallStockOutputs: controller.buildSmallOutputs(),
      largeStockOutputs: controller.buildLargeOutputs(),
      wasteAmount: _parse(_wasteController.text),
      wasteUnit: _wasteUnit,
      slurryDust: _slurryController.text.trim().isEmpty
          ? null
          : _slurryController.text.trim(),
      wasteDisposition: _wasteDisposition,
    );
  }

  JobWorkOutput _effectiveOutput() {
    if (_shiftLogs.isNotEmpty) {
      return JobWorkOutput.aggregateFromShifts(
        _shiftLogs,
        wasteDisposition: _wasteDisposition,
        slurryDust: _slurryController.text.trim().isEmpty
            ? null
            : _slurryController.text.trim(),
      ).copyWith(
        wasteAmount: _parse(_wasteController.text),
        wasteUnit: _wasteUnit,
      );
    }
    return _buildDirectOutput();
  }

  Future<void> _addShiftLog(JobWorkLoad load) async {
    final shift = await showDialog<JobWorkShiftLog>(
      context: context,
      builder: (_) => AddShiftLogDialog(
        smallSizes: _smallSizesFor(load),
        largeSizes: load.largeSizes,
        smallPricePerSqFt:
            JobWorkChargesCalculator.defaultSmallPricePerSqFtForLoad(load),
        largePricePerSqFt:
            JobWorkChargesCalculator.defaultLargePricePerSqFtForLoad(load),
        totalBlocks: load.blockCount,
        blocksAlreadyCut: JobWorkBlockProgress.totalBlocksCut(_shiftLogs),
      ),
    );
    if (shift == null) return;
    setState(() {
      _shiftLogs = [..._shiftLogs, shift];
      _chargesManuallyEdited = false;
    });
  }

  Future<void> _editShiftLog(JobWorkLoad load, JobWorkShiftLog shift) async {
    final updated = await showDialog<JobWorkShiftLog>(
      context: context,
      builder: (_) => AddShiftLogDialog(
        smallSizes: _smallSizesFor(load),
        largeSizes: load.largeSizes,
        smallPricePerSqFt:
            JobWorkChargesCalculator.defaultSmallPricePerSqFtForLoad(load),
        largePricePerSqFt:
            JobWorkChargesCalculator.defaultLargePricePerSqFtForLoad(load),
        totalBlocks: load.blockCount,
        blocksAlreadyCut: JobWorkBlockProgress.totalBlocksCut(
          _shiftLogs.where((log) => log.id != shift.id),
        ),
        existingShift: shift,
      ),
    );
    if (updated == null) return;
    setState(() {
      _shiftLogs = _shiftLogs
          .map((log) => log.id == updated.id ? updated : log)
          .toList();
      _chargesManuallyEdited = false;
    });
  }

  Future<void> _removeShiftLog(JobWorkShiftLog shift) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteShiftLog,
      message: AppStrings.deleteShiftLogMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (!confirmed) return;
    setState(() {
      _shiftLogs = _shiftLogs.where((log) => log.id != shift.id).toList();
      _chargesManuallyEdited = false;
    });
  }

  String _shiftSubtitle(JobWorkShiftLog shift) {
    final parts = <String>[];
    if (shift.blocksCut > 0) {
      parts.add('${shift.blocksCut} blk');
    }
    if (shift.hasStockOutputs) {
      parts.addAll([
        '${shift.totalPieces} pcs',
        '${shift.totalUsableSqFt.toStringAsFixed(2)} sq. ft',
        Formatters.currencyPkr(shift.grandCuttingTotal),
      ]);
    } else {
      parts.addAll([
        'A ${shift.gradeASqFt.toStringAsFixed(0)}',
        'B ${shift.gradeBSqFt.toStringAsFixed(0)}',
        'C ${shift.gradeCSqFt.toStringAsFixed(0)}',
        'Reject ${shift.rejectSqFt.toStringAsFixed(0)} sq. ft',
      ]);
    }
    return parts.join(' · ');
  }

  JobWorkExecution _buildExecution() {
    return JobWorkExecution(
      cuttingStartDate: _startDate,
      cuttingCompletionDate: _completionDate,
      supervisorName: _supervisorController.text.trim().isEmpty
          ? null
          : _supervisorController.text.trim(),
      progressNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  Future<void> _pickDate({
    required ValueChanged<DateTime> onPicked,
    DateTime? initial,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) onPicked(picked);
  }

  void _submit(JobWorkLoad baseLoad) {
    if (!_formKey.currentState!.validate()) return;

    final output = _effectiveOutput().copyWith(recordedAt: DateTime.now());
    final hasProduction = output.hasStockOutputs || output.totalOutputSqFt > 0;
    if (!hasProduction && output.wasteAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.outputProductionRequired)),
      );
      return;
    }

    if (_shiftLogs.isNotEmpty &&
        JobWorkBlockProgress.totalBlocksCut(_shiftLogs) > baseLoad.blockCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.blocksCutTotalExceeded)),
      );
      return;
    }

    final charges = _shiftLogs.isNotEmpty
        ? JobWorkChargesCalculator.calculateForLoad(
            load: baseLoad,
            output: output,
            shiftLogs: _shiftLogs,
          )
        : JobWorkChargesCalculator.resolveFinalCuttingChargesForLoad(
            load: baseLoad,
            output: output,
            manualOverride: _chargesManuallyEdited
                ? _parse(_finalChargesController.text)
                : null,
          );
    if (charges <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.finalCuttingChargesRequired)),
      );
      return;
    }

    _statusBeforeSubmit = baseLoad.status;

    final updated = baseLoad.copyWith(
      output: output,
      shiftLogs: _shiftLogs,
      execution: _buildExecution(),
      finalCuttingCharges: charges,
      balanceDue: charges - baseLoad.advanceReceived,
    );

    context.read<JobWorkOutputBloc>().add(JobWorkOutputSubmitted(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkOutputBloc, JobWorkOutputState>(
      listener: (context, state) {
        if (state.status == JobWorkOutputStatus.ready && state.load != null) {
          _populate(state.load!);
        }
        if (state.status == JobWorkOutputStatus.saved) {
          final saved = state.load;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                saved != null &&
                        _statusBeforeSubmit != null &&
                        saved.status != _statusBeforeSubmit
                    ? AppStrings.statusAutoAdvanced
                    : AppStrings.outputSaved,
              ),
            ),
          );
          context.pop(true);
        }
        if (state.status == JobWorkOutputStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == JobWorkOutputStatus.loading ||
            state.status == JobWorkOutputStatus.initial) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.recordOutput)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final load = state.load;
        if (load == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.recordOutput)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.outputSaveError),
            ),
          );
        }

        _populate(load);
        _ensureStockController(load);

        final previewOutput = _effectiveOutput();
        _syncCalculatedCharges(load, previewOutput);
        final chargeLines = JobWorkChargesCalculator.breakdownForLoad(
          load: load,
          output: previewOutput,
        );
        final balanceDue =
            _parse(_finalChargesController.text) - load.advanceReceived;
        final wastePct = previewOutput.wastePercent(load.totalTons);
        final isSaving = state.status == JobWorkOutputStatus.saving;
        final isEditing = load.output?.isRecorded == true;
        final usesShiftLogs = _shiftLogs.isNotEmpty;
        final hasSizes = load.hasAnySize;

        final subtitleParts = <String>[
          load.loadNumber,
          load.jobWorkNumber,
          if (load.mineLocation != null) load.mineLocation!,
          if (load.mineOwner != null) load.mineOwner!,
        ];

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: isEditing ? AppStrings.editOutput : AppStrings.recordOutput,
              subtitle: subtitleParts.join(' · '),
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              children: [
                if (load.blockCount > 0)
                  JobWorkBlockProgressSection(
                    blockCount: load.blockCount,
                    shiftLogs: _shiftLogs,
                  ),
                JobWorkDetailSection(
                  title: AppStrings.shiftLogs,
                  icon: Icons.schedule_outlined,
                  child: AppFormSectionBody(
                    children: [
                      Text(
                        AppStrings.shiftLogsHint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              height: 1.35,
                            ),
                      ),
                      AppFormFields.gap,
                      if (_shiftLogs.isEmpty)
                        Text(
                          AppStrings.noShiftLogsYet,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        ..._shiftLogs.map(
                          (shift) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                [
                                  DateFormat.yMMMd().format(shift.shiftDate),
                                  if (shift.shiftName != null) shift.shiftName,
                                ].join(' · '),
                              ),
                              subtitle: Text(_shiftSubtitle(shift)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: AppStrings.editShiftLog,
                                    onPressed: isSaving
                                        ? null
                                        : () => _editShiftLog(load, shift),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    tooltip: AppStrings.delete,
                                    onPressed: isSaving
                                        ? null
                                        : () => _removeShiftLog(shift),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      AppFormFields.gap,
                      OutlinedButton.icon(
                        onPressed: isSaving || !hasSizes
                            ? null
                            : () => _addShiftLog(load),
                        icon: const Icon(Icons.add),
                        label: const Text(AppStrings.addShiftLog),
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.stockProduction,
                  icon: Icons.grid_on_outlined,
                  child: AppFormSectionBody(
                    children: [
                      if (!hasSizes)
                        Text(
                          AppStrings.noStockProductionYet,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else if (usesShiftLogs) ...[
                        Text(
                          AppStrings.productionLockedFromShifts,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        AppFormFields.gap,
                        StockOutputReadOnlyPanel(
                          smallOutputs: previewOutput.smallStockOutputs,
                          largeOutputs: previewOutput.largeStockOutputs,
                        ),
                      ] else
                        StockOutputRecordingPanel(
                          controller: _stockController!,
                          enabled: !isSaving,
                          onChanged: _onStockChanged,
                        ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.wasteAndYield,
                  icon: Icons.recycling_outlined,
                  child: AppFormSectionBody(
                    children: [
                      _numberField(
                        _wasteController,
                        AppStrings.wasteGenerated,
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<WasteUnit>(
                        key: ValueKey(_wasteUnit),
                        initialValue: _wasteUnit,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.wasteUnit,
                        ),
                        items: WasteUnit.values
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
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _wasteUnit = value);
                              },
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<WasteDisposition>(
                        key: ValueKey(_wasteDisposition),
                        initialValue: _wasteDisposition,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.wasteDisposition,
                        ),
                        items: WasteDisposition.values
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
                                if (value == null) return;
                                setState(() => _wasteDisposition = value);
                              },
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _slurryController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.slurryDust,
                        ),
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.cuttingExecution,
                  icon: Icons.content_cut_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormDateField(
                        label: AppStrings.cuttingStartDate,
                        value: _startDate == null
                            ? 'Not set'
                            : DateFormat.yMMMd().format(_startDate!),
                        onTap: isSaving
                            ? null
                            : () => _pickDate(
                                  initial: _startDate,
                                  onPicked: (date) =>
                                      setState(() => _startDate = date),
                                ),
                      ),
                      AppFormFields.gap,
                      AppFormDateField(
                        label: AppStrings.cuttingCompletionDate,
                        value: _completionDate == null
                            ? 'Not set'
                            : DateFormat.yMMMd().format(_completionDate!),
                        onTap: isSaving
                            ? null
                            : () => _pickDate(
                                  initial: _completionDate,
                                  onPicked: (date) =>
                                      setState(() => _completionDate = date),
                                ),
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _supervisorController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.supervisorName,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _notesController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.progressNotes,
                        ),
                        maxLines: 3,
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
                      if (chargeLines.isNotEmpty) ...[
                        Text(
                          AppStrings.cuttingChargesBreakdown,
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        ...chargeLines.map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AppFormSummaryRow(
                              label: '${line.label} (${line.detail})',
                              value: Formatters.currencyPkr(line.amount),
                            ),
                          ),
                        ),
                        AppFormFields.gap,
                      ],
                      TextFormField(
                        controller: _finalChargesController,
                        keyboardType: TextInputType.number,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.finalCuttingCharges,
                        ),
                        validator: (v) {
                          if (_parse(v ?? '') <= 0) {
                            return AppStrings.finalCuttingChargesRequired;
                          }
                          return null;
                        },
                        enabled: !isSaving,
                        onChanged: (_) {
                          setState(() => _chargesManuallyEdited = true);
                        },
                      ),
                      if (load.advanceReceived > 0) ...[
                        AppFormFields.gap,
                        AppFormSummaryRow(
                          label: AppStrings.advanceReceived,
                          value: Formatters.currencyPkr(load.advanceReceived),
                        ),
                      ],
                      AppFormFields.gap,
                      AppFormSummaryRow(
                        label: AppStrings.balanceDue,
                        value: Formatters.currencyPkr(balanceDue),
                        highlight: true,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.outputRecording,
                  icon: Icons.analytics_outlined,
                  child: AppFormSectionBody(
                    children: [
                      AppFormSummaryRow(
                        label: AppStrings.totalPieces,
                        value: previewOutput.totalPieces.toString(),
                      ),
                      AppFormFields.gap,
                      AppFormSummaryRow(
                        label: AppStrings.totalUsableOutput,
                        value:
                            '${previewOutput.totalUsableSqFt.toStringAsFixed(2)} sq. ft',
                        highlight: true,
                      ),
                      AppFormFields.gap,
                      AppFormSummaryRow(
                        label: AppStrings.grandCuttingTotal,
                        value: Formatters.currencyPkr(previewOutput.grandCuttingTotal),
                        highlight: true,
                      ),
                      if (wastePct > 0) ...[
                        AppFormFields.gap,
                        AppFormSummaryRow(
                          label: AppStrings.wastePercent,
                          value: '${wastePct.toStringAsFixed(1)}%',
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: AppFormBottomBar(
            label: AppStrings.saveOutput,
            isLoading: isSaving,
            onPressed: () => _submit(load),
          ),
        );
      },
    );
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: AppFormFields.valueStyle(context),
      decoration: AppFormFields.decoration(context, label: label),
      onChanged: (_) => setState(() {
        _chargesManuallyEdited = false;
      }),
    );
  }
}
