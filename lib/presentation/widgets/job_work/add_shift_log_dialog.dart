import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/job_work_output.dart';
import '../../../domain/enums/job_work_enums.dart';
import '../dialogs/app_dialog.dart';
import '../forms/app_form_fields.dart';

class AddShiftLogDialog extends StatefulWidget {
  const AddShiftLogDialog({super.key});

  @override
  State<AddShiftLogDialog> createState() => _AddShiftLogDialogState();
}

class _AddShiftLogDialogState extends State<AddShiftLogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _gradeAController = TextEditingController();
  final _gradeBController = TextEditingController();
  final _gradeCController = TextEditingController();
  final _rejectController = TextEditingController();
  final _wasteController = TextEditingController();
  final _shiftNameController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _shiftDate = DateTime.now();
  WasteUnit _wasteUnit = WasteUnit.tons;

  @override
  void dispose() {
    _gradeAController.dispose();
    _gradeBController.dispose();
    _gradeCController.dispose();
    _rejectController.dispose();
    _wasteController.dispose();
    _shiftNameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double _parse(String value) => double.tryParse(value.trim()) ?? 0;

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

    final shift = JobWorkShiftLog.create(
      shiftDate: _shiftDate,
      shiftName: _shiftNameController.text.trim().isEmpty
          ? null
          : _shiftNameController.text.trim(),
      gradeASqFt: _parse(_gradeAController.text),
      gradeBSqFt: _parse(_gradeBController.text),
      gradeCSqFt: _parse(_gradeCController.text),
      rejectSqFt: _parse(_rejectController.text),
      wasteAmount: _parse(_wasteController.text),
      wasteUnit: _wasteUnit,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!shift.hasOutput) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.outputGradeRequired)),
      );
      return;
    }

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
      maxWidth: 440,
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
            TextFormField(
              controller: _shiftNameController,
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.shiftName),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _gradeAController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.gradeA),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _gradeBController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.gradeB),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _gradeCController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.gradeC),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _rejectController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.reject),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _wasteController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.wasteGenerated),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<WasteUnit>(
              key: ValueKey(_wasteUnit),
              initialValue: _wasteUnit,
              style: AppFormFields.valueStyle(context),
              decoration: _fieldDecoration(context, AppStrings.wasteUnit),
              items: WasteUnit.values
                  .map(
                    (unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _wasteUnit = value);
              },
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
