import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/job_work_shifts.dart';
import '../../../core/utils/job_work_block_progress.dart';
import '../../../domain/entities/job_work_output.dart';
import '../dialogs/app_dialog.dart';
import '../forms/app_form_fields.dart';
import 'stock_output_form_controller.dart';
import 'stock_output_recording_panel.dart';

class AddShiftLogDialog extends StatefulWidget {
  const AddShiftLogDialog({
    required this.smallSizes,
    required this.largeSizes,
    required this.smallPricePerSqFt,
    required this.largePricePerSqFt,
    required this.totalBlocks,
    this.blocksAlreadyCut = 0,
    this.existingShift,
    super.key,
  });

  final List<String> smallSizes;
  final List<String> largeSizes;
  final double smallPricePerSqFt;
  final double largePricePerSqFt;
  final int totalBlocks;
  final int blocksAlreadyCut;
  final JobWorkShiftLog? existingShift;

  @override
  State<AddShiftLogDialog> createState() => _AddShiftLogDialogState();
}

class _AddShiftLogDialogState extends State<AddShiftLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _blocksCutController = TextEditingController();
  late final StockOutputFormController _stockController;

  DateTime _shiftDate = DateTime.now();
  String? _shiftName;

  int get _maxBlocksAllowed =>
      (widget.totalBlocks - widget.blocksAlreadyCut).clamp(0, widget.totalBlocks);

  int get _blocksCutThisShift {
    final parsed = int.tryParse(_blocksCutController.text.trim());
    return parsed ?? 0;
  }

  int get _remainingAfterThisShift => JobWorkBlockProgress.remainingAfterShift(
        totalBlocks: widget.totalBlocks,
        blocksAlreadyCut: widget.blocksAlreadyCut,
        blocksCutThisShift: _blocksCutThisShift,
      );

  bool get _isEditing => widget.existingShift != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingShift;
    _stockController = StockOutputFormController(
      smallSizes: widget.smallSizes,
      largeSizes: widget.largeSizes,
      smallPricePerSqFt: widget.smallPricePerSqFt,
      largePricePerSqFt: widget.largePricePerSqFt,
      initialSmall: existing?.smallStockOutputs ?? const [],
      initialLarge: existing?.largeStockOutputs ?? const [],
    );
    _stockController.addListener(_onFormChanged);
    _blocksCutController.addListener(_onFormChanged);
    if (existing != null) {
      _shiftDate = existing.shiftDate;
      _shiftName = existing.shiftName;
      if (existing.blocksCut > 0) {
        _blocksCutController.text = existing.blocksCut.toString();
      }
      _notesController.text = existing.notes ?? '';
    } else if (JobWorkShifts.all.isNotEmpty) {
      _shiftName = JobWorkShifts.all.first;
    }
  }

  @override
  void dispose() {
    _stockController.removeListener(_onFormChanged);
    _blocksCutController.removeListener(_onFormChanged);
    _stockController.dispose();
    _blocksCutController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _shiftDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _shiftDate = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_shiftName == null || _shiftName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.selectShift)),
      );
      return;
    }

    if (!_stockController.hasProduction) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.outputProductionRequired)),
      );
      return;
    }

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();
    final smallStockOutputs = _stockController.buildSmallOutputs();
    final largeStockOutputs = _stockController.buildLargeOutputs();

    final shift = _isEditing
        ? JobWorkShiftLog(
            id: widget.existingShift!.id,
            shiftDate: _shiftDate,
            shiftName: _shiftName,
            blocksCut: _blocksCutThisShift,
            smallStockOutputs: smallStockOutputs,
            largeStockOutputs: largeStockOutputs,
            notes: notes,
            recordedAt: widget.existingShift!.recordedAt,
          )
        : JobWorkShiftLog.create(
            shiftDate: _shiftDate,
            shiftName: _shiftName,
            blocksCut: _blocksCutThisShift,
            smallStockOutputs: smallStockOutputs,
            largeStockOutputs: largeStockOutputs,
            notes: notes,
          );

    Navigator.of(context).pop(shift);
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return AppFormFields.decoration(context, label: label);
  }

  String? _validateBlocksCut(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.blocksCutRequired;
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return AppStrings.blocksCutRequired;
    }
    if (parsed < 0) {
      return AppStrings.blocksCutCannotBeNegative;
    }
    if (parsed > _maxBlocksAllowed) {
      return AppStrings.blocksCutExceedsRemaining(_maxBlocksAllowed);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: _isEditing ? AppStrings.editShiftLog : AppStrings.addShiftLog,
      icon: Icons.fact_check_outlined,
      scrollable: true,
      maxWidth: 720,
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFormDateField(
              label: AppStrings.shiftDate,
              value: DateFormat.yMMMd().format(_shiftDate),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              key: ValueKey(_shiftName),
              initialValue: _shiftName,
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.shiftName),
              items: JobWorkShifts.all
                  .map(
                    (shift) => DropdownMenuItem(
                      value: shift,
                      child: Text(shift),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _shiftName = value),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return AppStrings.selectShift;
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _blocksCutController,
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.blocksCut),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateBlocksCut,
            ),
            const SizedBox(height: 10),
            InputDecorator(
              decoration: _fieldDecoration(context, AppStrings.remainingBlocks),
              child: Text(
                '$_remainingAfterThisShift',
                style: AppFormFields.valueStyle(context),
              ),
            ),
            const SizedBox(height: 14),
            StockOutputRecordingPanel(
              controller: _stockController,
              onChanged: _onFormChanged,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _notesController,
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.shiftNotes),
              maxLines: 2,
            ),
          ],
        ),
      ),
      actions: [
        AppDialogActions.cancel(context),
        AppDialogActions.confirm(
          context,
          label: _isEditing ? AppStrings.saveChanges : AppStrings.addShiftLog,
          onPressed: _submit,
        ),
      ],
    );
  }
}
