import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import 'app_dialog.dart';

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    required this.title,
    required this.message,
    this.confirmLabel = AppStrings.confirm,
    this.cancelLabel = AppStrings.cancel,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = AppStrings.confirm,
    String cancelLabel = AppStrings.cancel,
    bool destructive = false,
  }) async {
    final result = await AppDialog.show<bool>(
      context,
      child: AppConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      message: message,
      icon: appDialogIconForDestructive(destructive),
      iconColor: appDialogIconColorForDestructive(context, destructive),
      includeContentSection: false,
      content: const SizedBox.shrink(),
      actions: [
        AppDialogActions.cancel(
          context,
          label: cancelLabel,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppDialogActions.confirm(
          context,
          label: confirmLabel,
          destructive: destructive,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
