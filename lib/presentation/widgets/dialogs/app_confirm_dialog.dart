import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'app_dialog.dart';

class AppConfirmDialog extends StatefulWidget {
  const AppConfirmDialog({
    required this.title,
    required this.message,
    this.confirmLabel = AppStrings.confirm,
    this.cancelLabel = AppStrings.cancel,
    this.destructive = false,
    this.onConfirm,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;
  final Future<void> Function()? onConfirm;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    String cancelLabel = AppStrings.cancel,
    bool destructive = false,
    Future<void> Function()? onConfirm,
  }) async {
    final result = await AppDialog.show<bool>(
      context,
      barrierDismissible: false,
      child: AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
        onConfirm: onConfirm,
      ),
    );
    return result ?? false;
  }

  @override
  State<AppConfirmDialog> createState() => _AppConfirmDialogState();
}

class _AppConfirmDialogState extends State<AppConfirmDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleConfirm() async {
    if (widget.onConfirm == null) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirm!();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is Exception
              ? e.toString().replaceFirst('Exception: ', '')
              : 'An error occurred while performing action.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.title,
      message: _errorMessage ?? widget.message,
      icon: appDialogIconForDestructive(widget.destructive),
      iconColor: appDialogIconColorForDestructive(context, widget.destructive),
      includeContentSection: false,
      content: const SizedBox.shrink(),
      actions: [
        AppDialogActions.cancel(
          context,
          label: widget.cancelLabel,
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
        ),
        AppDialogActions.confirm(
          context,
          label: widget.confirmLabel,
          destructive: widget.destructive,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleConfirm,
        ),
      ],
    );
  }
}
