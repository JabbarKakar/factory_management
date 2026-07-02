import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../blocs/job_work/job_work_output_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/job_work_block_progress.dart';
import '../../../core/utils/job_work_charges_calculator.dart';
import '../../../domain/entities/job_work_order.dart';
import '../../../domain/entities/job_work_output.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/add_shift_log_dialog.dart';
import '../../widgets/job_work/job_work_block_progress_section.dart';
import '../../widgets/job_work/job_work_detail_section.dart';
import '../../widgets/job_work/stock_output_form_controller.dart';
import '../../widgets/job_work/stock_output_recording_panel.dart';

class RecordJobWorkOutputScreen extends StatefulWidget {
  const RecordJobWorkOutputScreen({required this.jobWorkId, super.key});

  final String jobWorkId;

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
  JobWorkStatus? _statusBeforeSubmit;
  StockOutputFormController? _stockController;
  String? _stockControllerOrderId;

  List<String> _smallSizesFor(JobWorkOrder order) =>
      [...order.smallSizes, ...order.legacySizes];

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

  void _ensureStockController(JobWorkOrder order) {
    if (_stockControllerOrderId == order.id && _stockController != null) {
      return;
    }

    _stockController?.dispose();
    final output = order.output;
    _stockController = StockOutputFormController(
      smallSizes: _smallSizesFor(order),
      largeSizes: order.largeSizes,
      smallPricePerSqFt:
          JobWorkChargesCalculator.defaultSmallPricePerSqFt(order),
      largePricePerSqFt:
          JobWorkChargesCalculator.defaultLargePricePerSqFt(order),
      initialSmall: output?.smallStockOutputs ?? const [],
      initialLarge: output?.largeStockOutputs ?? const [],
    );
    _stockController!.addListener(_onStockChanged);
    _stockControllerOrderId = order.id;
  }

  void _onStockChanged() {
    if (mounted) {
      setState(() {
        _chargesManuallyEdited = false;
      });
    }
  }

  void _populate(JobWorkOrder order) {
    if (_populated) return;
    _populated = true;

    final output = order.output;
    if (output != null) {
      _wasteController.text = _formatNum(output.wasteAmount);
      _wasteUnit = output.wasteUnit;
      _wasteDisposition = output.wasteDisposition;
      _slurryController.text = output.slurryDust ?? '';
    }

    _shiftLogs = List<JobWorkShiftLog>.from(order.shiftLogs);

    final execution = order.execution;
    if (execution != null) {
      _startDate = execution.cuttingStartDate;
      _completionDate = execution.cuttingCompletionDate;
      _supervisorController.text = execution.supervisorName ?? '';
      _notesController.text = execution.progressNotes ?? '';
    }

    if (order.finalCuttingCharges > 0) {
      _finalChargesController.text =
          order.finalCuttingCharges.toStringAsFixed(0);
    }
  }

  void _syncCalculatedCharges(JobWorkOrder order, JobWorkOutput output) {
    if (_chargesManuallyEdited) return;
    final charges = JobWorkChargesCalculator.calculate(
      order: order,
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

  Future<void> _addShiftLog(JobWorkOrder order) async {
    final shift = await showDialog<JobWorkShiftLog>(
      context: context,
      builder: (_) => AddShiftLogDialog(
        smallSizes: _smallSizesFor(order),
        largeSizes: order.largeSizes,
        smallPricePerSqFt:
            JobWorkChargesCalculator.defaultSmallPricePerSqFt(order),
        largePricePerSqFt:
            JobWorkChargesCalculator.defaultLargePricePerSqFt(order),
        totalBlocks: order.blockCount,
        blocksAlreadyCut: JobWorkBlockProgress.totalBlocksCut(_shiftLogs),
      ),
    );
    if (shift == null) return;
    setState(() {
      _shiftLogs = [..._shiftLogs, shift];
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

  void _submit(JobWorkOrder baseOrder) {
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
        JobWorkBlockProgress.totalBlocksCut(_shiftLogs) > baseOrder.blockCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.blocksCutTotalExceeded)),
      );
      return;
    }

    final charges = _shiftLogs.isNotEmpty
        ? JobWorkChargesCalculator.calculate(
            order: baseOrder,
            output: output,
            shiftLogs: _shiftLogs,
          )
        : JobWorkChargesCalculator.resolveFinalCuttingCharges(
            order: baseOrder,
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

    _statusBeforeSubmit = baseOrder.status;

    final updated = baseOrder.copyWith(
      output: output,
      shiftLogs: _shiftLogs,
      execution: _buildExecution(),
      finalCuttingCharges: charges,
      balanceDue: charges - baseOrder.advanceReceived,
    );

    context.read<JobWorkOutputBloc>().add(JobWorkOutputSubmitted(updated));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JobWorkOutputBloc, JobWorkOutputState>(
      listener: (context, state) {
        if (state.status == JobWorkOutputStatus.ready && state.order != null) {
          _populate(state.order!);
        }
        if (state.status == JobWorkOutputStatus.saved) {
          final saved = state.order;
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

        final order = state.order;
        if (order == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.recordOutput)),
            body: Center(
              child: Text(state.errorMessage ?? AppStrings.outputSaveError),
            ),
          );
        }

        _populate(order);
        _ensureStockController(order);

        final previewOutput = _effectiveOutput();
        _syncCalculatedCharges(order, previewOutput);
        final chargeLines = JobWorkChargesCalculator.breakdown(
          order: order,
          output: previewOutput,
        );
        final balanceDue =
            _parse(_finalChargesController.text) - order.advanceReceived;
        final wastePct = previewOutput.wastePercent(order.totalTons);
        final isSaving = state.status == JobWorkOutputStatus.saving;
        final isEditing = order.output?.isRecorded == true;
        final usesShiftLogs = _shiftLogs.isNotEmpty;
        final hasSizes = order.hasAnySize;

        final subtitleParts = <String>[
          order.jobWorkNumber,
          if (order.mineLocation != null) order.mineLocation!,
          if (order.mineOwner != null) order.mineOwner!,
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
                if (order.blockCount > 0)
                  JobWorkBlockProgressSection(
                    order: order.copyWith(shiftLogs: _shiftLogs),
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
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline),
                                onPressed: isSaving
                                    ? null
                                    : () => _removeShiftLog(shift),
                              ),
                            ),
                          ),
                        ),
                      AppFormFields.gap,
                      OutlinedButton.icon(
                        onPressed: isSaving || !hasSizes
                            ? null
                            : () => _addShiftLog(order),
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
                      if (order.advanceReceived > 0) ...[
                        AppFormFields.gap,
                        AppFormSummaryRow(
                          label: AppStrings.advanceReceived,
                          value: Formatters.currencyPkr(order.advanceReceived),
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
            onPressed: () => _submit(order),
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
