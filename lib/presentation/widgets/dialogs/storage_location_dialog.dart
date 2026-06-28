import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/inventory_data.dart';
import '../forms/app_form_fields.dart';
import 'app_dialog.dart';

class StorageLocationDialog extends StatefulWidget {
  const StorageLocationDialog({
    this.currentLocation,
    super.key,
  });

  final String? currentLocation;

  static Future<String?> show(
    BuildContext context, {
    String? currentLocation,
  }) {
    return AppDialog.show<String?>(
      context,
      child: StorageLocationDialog(currentLocation: currentLocation),
    );
  }

  @override
  State<StorageLocationDialog> createState() => _StorageLocationDialogState();
}

class _StorageLocationDialogState extends State<StorageLocationDialog> {
  late String? _selected;
  late final TextEditingController _customController;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentLocation;
    if (_selected != null &&
        !InventoryData.storageLocations.contains(_selected)) {
      _selected = 'Other';
    }
    _customController = TextEditingController(
      text: _selected == 'Other' ? (widget.currentLocation ?? '') : '',
    );
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_selected == 'Other') {
      final custom = _customController.text.trim();
      Navigator.of(context).pop(custom.isEmpty ? null : custom);
      return;
    }
    Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: AppStrings.setStorageLocation,
      message: AppStrings.storageLocation,
      icon: Icons.location_on_outlined,
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String?>(
            key: ValueKey(_selected),
            initialValue: _selected,
            isExpanded: true,
            decoration: AppFormFields.decoration(
              context,
              label: AppStrings.storageLocation,
            ),
            style: AppFormFields.valueStyle(context),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text(AppStrings.notSpecified),
              ),
              ...InventoryData.storageLocations.map(
                (location) => DropdownMenuItem(
                  value: location,
                  child: Text(location),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selected = value),
          ),
          if (_selected == 'Other') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customController,
              textCapitalization: TextCapitalization.words,
              style: AppFormFields.valueStyle(context),
              decoration: AppFormFields.decoration(
                context,
                label: AppStrings.storageLocation,
              ),
            ),
          ],
        ],
      ),
      actions: [
        AppDialogActions.cancel(context),
        AppDialogActions.confirm(
          context,
          label: AppStrings.saveChanges,
          onPressed: _submit,
        ),
      ],
    );
  }
}
