import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/validators.dart';
import '../../../../domain/entities/bank_account.dart';
import '../../../widgets/forms/app_form_fields.dart';

class BankAccountDialog extends StatefulWidget {
  const BankAccountDialog({
    super.key,
    this.account,
  });

  final BankAccount? account;

  @override
  State<BankAccountDialog> createState() => _BankAccountDialogState();
}

class _BankAccountDialogState extends State<BankAccountDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _accountNameController;
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _branchController;
  late TextEditingController _ibanController;
  late TextEditingController _swiftCodeController;
  late String _accountType;
  late bool _isDefault;
  late bool _isActive;

  final List<String> _accountTypes = const [
    'Current',
    'Savings',
    'Corporate',
    'Islamic',
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.account;
    _accountNameController = TextEditingController(text: acc?.accountName ?? '');
    _accountNumberController =
        TextEditingController(text: acc?.accountNumber ?? '');
    _bankNameController = TextEditingController(text: acc?.bankName ?? '');
    _branchController = TextEditingController(text: acc?.branch ?? '');
    _ibanController = TextEditingController(text: acc?.iban ?? '');
    _swiftCodeController = TextEditingController(text: acc?.swiftCode ?? '');
    _accountType = acc?.accountType ?? 'Current';
    _isDefault = acc?.isDefault ?? false;
    _isActive = acc?.isActive ?? true;
  }

  @override
  void dispose() {
    _accountNameController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _ibanController.dispose();
    _swiftCodeController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final account = BankAccount(
      id: widget.account?.id ?? const Uuid().v4(),
      accountName: _accountNameController.text.trim(),
      accountNumber: _accountNumberController.text.trim(),
      bankName: _bankNameController.text.trim(),
      branch: _branchController.text.trim().isEmpty
          ? null
          : _branchController.text.trim(),
      iban: _ibanController.text.trim().isEmpty
          ? null
          : _ibanController.text.trim().toUpperCase(),
      swiftCode: _swiftCodeController.text.trim().isEmpty
          ? null
          : _swiftCodeController.text.trim().toUpperCase(),
      accountType: _accountType,
      isDefault: _isDefault,
      isActive: _isActive,
    );

    Navigator.of(context).pop(account);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.account != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Bank Account' : 'Add Bank Account'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _accountNameController,
                style: AppFormFields.valueStyle(context),
                decoration: AppFormFields.decoration(
                  context,
                  label: 'Account Title / Name',
                  hint: 'e.g. Jabbar Industries Pvt Ltd',
                ),
                validator: (v) =>
                    Validators.requiredText(v, field: 'Account Title'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bankNameController,
                style: AppFormFields.valueStyle(context),
                decoration: AppFormFields.decoration(
                  context,
                  label: 'Bank Name',
                  hint: 'e.g. Meezan Bank / HBL / UBL',
                ),
                validator: (v) =>
                    Validators.requiredText(v, field: 'Bank Name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountNumberController,
                style: AppFormFields.valueStyle(context),
                keyboardType: TextInputType.number,
                decoration: AppFormFields.decoration(
                  context,
                  label: 'Account Number',
                  hint: 'e.g. 01010102938481',
                ),
                validator: (v) =>
                    Validators.requiredText(v, field: 'Account Number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ibanController,
                style: AppFormFields.valueStyle(context),
                textCapitalization: TextCapitalization.characters,
                decoration: AppFormFields.decoration(
                  context,
                  label: 'IBAN (Optional)',
                  hint: 'PK36MEZN0001010102938481',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _branchController,
                      style: AppFormFields.valueStyle(context),
                      decoration: AppFormFields.decoration(
                        context,
                        label: 'Branch Name / Code',
                        hint: 'e.g. Main Market Branch',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _accountType,
                      decoration: AppFormFields.decoration(
                        context,
                        label: 'Account Type',
                      ),
                      items: _accountTypes
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _accountType = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _swiftCodeController,
                style: AppFormFields.valueStyle(context),
                textCapitalization: TextCapitalization.characters,
                decoration: AppFormFields.decoration(
                  context,
                  label: 'SWIFT / BIC Code (Optional)',
                  hint: 'MEZNPKKA',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Set as Default Bank Account'),
                subtitle: const Text('Used as primary account on invoices'),
                value: _isDefault,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active Account'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(isEdit ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
