import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/job_work_output.dart';
import '../../../domain/enums/job_work_enums.dart';

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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.addShiftLog),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(AppStrings.shiftDate),
                subtitle: Text(DateFormat.yMMMd().format(_shiftDate)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: _pickDate,
              ),
              TextFormField(
                controller: _shiftNameController,
                decoration: const InputDecoration(
                  labelText: AppStrings.shiftName,
                  hintText: 'Morning, Evening, Night...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _gradeAController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: AppStrings.gradeA,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gradeBController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: AppStrings.gradeB,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _gradeCController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: AppStrings.gradeC,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _rejectController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: AppStrings.reject,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _wasteController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: AppStrings.wasteGenerated,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<WasteUnit>(
                initialValue: _wasteUnit,
                decoration: const InputDecoration(
                  labelText: AppStrings.wasteUnit,
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: AppStrings.shiftNotes,
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text(AppStrings.addShiftLog),
        ),
      ],
    );
  }
}
