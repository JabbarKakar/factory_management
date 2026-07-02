import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/job_work_shifts.dart';
import '../../../domain/entities/job_work_output.dart';
import '../dialogs/app_dialog.dart';
import '../forms/app_form_fields.dart';
import 'stock_output_form_controller.dart';
import 'stock_output_recording_panel.dart';

class AddShiftLogDialog extends StatefulWidget {
  const AddShiftLogDialog({
    required this.smallSizes,
    required this.largeSizes,
    required this.defaultSmallPrice,
    required this.defaultLargePrice,
    super.key,
  });

  final List<String> smallSizes;
  final List<String> largeSizes;
  final double defaultSmallPrice;
  final double defaultLargePrice;

  @override
  State<AddShiftLogDialog> createState() => _AddShiftLogDialogState();
}

class _AddShiftLogDialogState extends State<AddShiftLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  late final StockOutputFormController _stockController;

  DateTime _shiftDate = DateTime.now();
  String? _shiftName;

  @override
  void initState() {
    super.initState();
    _stockController = StockOutputFormController(
      smallSizes: widget.smallSizes,
      largeSizes: widget.largeSizes,
      defaultSmallPrice: widget.defaultSmallPrice,
      defaultLargePrice: widget.defaultLargePrice,
    );
    _stockController.addListener(_onStockChanged);
    if (JobWorkShifts.all.isNotEmpty) {
      _shiftName = JobWorkShifts.all.first;
    }
  }

  @override
  void dispose() {
    _stockController.removeListener(_onStockChanged);
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onStockChanged() {
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

    final shift = JobWorkShiftLog.create(
      shiftDate: _shiftDate,
      shiftName: _shiftName,
      smallStockOutputs: _stockController.buildSmallOutputs(),
      largeStockOutputs: _stockController.buildLargeOutputs(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    Navigator.of(context).pop(shift);
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return AppFormFields.decoration(context, label: label);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.addShiftLog,
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
            const SizedBox(height: 14),
            StockOutputRecordingPanel(
              controller: _stockController,
              onChanged: _onStockChanged,
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
          label: AppStrings.addShiftLog,
          onPressed: _submit,
        ),
      ],
    );
  }
}
