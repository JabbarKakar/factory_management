import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../forms/app_form_fields.dart';
import 'app_dialog.dart';

class AppInputDialog extends StatefulWidget {
  const AppInputDialog({
    required this.title,
    required this.fieldLabel,
    required this.confirmLabel,
    this.message,
    this.helperText,
    this.initialValue = '',
    this.keyboardType,
    this.icon,
    this.parse,
    super.key,
  });

  final String title;
  final String? message;
  final String fieldLabel;
  final String? helperText;
  final String confirmLabel;
  final String initialValue;
  final TextInputType? keyboardType;
  final IconData? icon;
  final Object? Function(String value)? parse;

  static Future<double?> showNumber(
    BuildContext context, {
    required String title,
    required String fieldLabel,
    String? message,
    String? helperText,
    String confirmLabel = AppStrings.saveChanges,
    double initialValue = 0,
    IconData icon = Icons.tune_outlined,
  }) {
    return AppDialog.show<double>(
      context,
      child: AppInputDialog(
        title: title,
        message: message,
        fieldLabel: fieldLabel,
        helperText: helperText,
        confirmLabel: confirmLabel,
        initialValue:
            initialValue > 0 ? initialValue.toStringAsFixed(0) : '',
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        icon: icon,
        parse: (value) => double.tryParse(value.trim()) ?? 0,
      ),
    );
  }

  @override
  State<AppInputDialog> createState() => _AppInputDialogState();
}

class _AppInputDialogState extends State<AppInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final parser = widget.parse;
    if (parser != null) {
      Navigator.of(context).pop(parser(_controller.text));
      return;
    }
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      message: widget.message,
      icon: widget.icon ?? Icons.edit_outlined,
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: widget.keyboardType,
        style: AppFormFields.valueStyle(context),
        decoration: AppFormFields.decoration(
          context,
          label: widget.fieldLabel,
          hint: widget.helperText,
        ).copyWith(helperText: widget.helperText),
      ),
      actions: [
        AppDialogActions.cancel(context),
        AppDialogActions.confirm(
          context,
          label: widget.confirmLabel,
          onPressed: _submit,
        ),
      ],
    );
  }
}
