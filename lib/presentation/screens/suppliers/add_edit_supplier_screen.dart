import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/supplier/supplier_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/supplier.dart';
import '../../../domain/enums/customer_enums.dart';
import '../../../domain/enums/app_module_enums.dart';
import '../../../domain/enums/supplier_enums.dart';
import '../../utils/user_permissions_context.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/settings_section.dart';

class AddEditSupplierScreen extends StatefulWidget {
  const AddEditSupplierScreen({this.supplierId, super.key});

  final String? supplierId;

  @override
  State<AddEditSupplierScreen> createState() => _AddEditSupplierScreenState();
}

class _AddEditSupplierScreenState extends State<AddEditSupplierScreen> {
  final _formKey = GlobalKey<FormState>();

  SupplierType _supplierType = SupplierType.marbleBlockSlab;
  PaymentTerms _paymentTerms = PaymentTerms.cash;

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneSecondaryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _cnicNtnController = TextEditingController();
  final _materialsController = TextEditingController();
  final _notesController = TextEditingController();

  bool _populated = false;

  bool get _isEditing => widget.supplierId != null;

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _phoneSecondaryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _cnicNtnController.dispose();
    _materialsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateForm(Supplier supplier) {
    if (_populated) return;
    _populated = true;

    _supplierType = supplier.supplierType;
    _paymentTerms = supplier.paymentTerms;
    _nameController.text = supplier.name;
    _contactPersonController.text = supplier.contactPersonName ?? '';
    _phoneController.text = supplier.phone;
    _phoneSecondaryController.text = supplier.phoneSecondary ?? '';
    _cityController.text = supplier.city ?? '';
    _addressController.text = supplier.address ?? '';
    _cnicNtnController.text = supplier.cnicNtn ?? '';
    _materialsController.text = supplier.materialsSupplied ?? '';
    _notesController.text = supplier.notes ?? '';
  }

  Supplier? _buildSupplier(Supplier? existing) {
    if (existing == null) return null;

    return existing.copyWith(
      name: _nameController.text.trim(),
      supplierType: _supplierType,
      contactPersonName: _contactPersonController.text.trim().isEmpty
          ? null
          : _contactPersonController.text.trim(),
      phone: _phoneController.text.trim(),
      phoneSecondary: _phoneSecondaryController.text.trim().isEmpty
          ? null
          : _phoneSecondaryController.text.trim(),
      city: _cityController.text.trim().isEmpty
          ? null
          : _cityController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      cnicNtn: _cnicNtnController.text.trim().isEmpty
          ? null
          : _cnicNtnController.text.trim(),
      paymentTerms: _paymentTerms,
      materialsSupplied: _materialsController.text.trim().isEmpty
          ? null
          : _materialsController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );
  }

  void _submit(BuildContext context, Supplier? existing) {
    if (!_formKey.currentState!.validate()) return;

    final supplier = _buildSupplier(existing);
    if (supplier == null) return;

    context.read<SupplierFormBloc>().add(SupplierFormSubmitted(supplier));
  }

  Future<void> _confirmDelete(BuildContext context, String supplierId) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteSupplierTitle,
      message: AppStrings.deleteSupplierMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );
    if (confirmed == true && context.mounted) {
      context
          .read<SupplierFormBloc>()
          .add(SupplierFormDeleteRequested(supplierId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SupplierFormBloc, SupplierFormState>(
      listener: (context, state) {
        if (state.status == SupplierFormStatus.saved) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _isEditing
                    ? AppStrings.supplierUpdated
                    : AppStrings.supplierCreated,
              ),
            ),
          );
          context.pop(true);
        }
        if (state.status == SupplierFormStatus.deleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.supplierDeleted)),
          );
          context.pop(true);
        }
        if (state.status == SupplierFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == SupplierFormStatus.loading ||
            state.status == SupplierFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _isEditing ? AppStrings.editSupplier : AppStrings.addSupplier,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final supplier = state.supplier;
        if (supplier != null && _isEditing) {
          _populateForm(supplier);
        }

        final isSaving = state.status == SupplierFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _isEditing ? AppStrings.editSupplier : AppStrings.addSupplier,
            ),
            actions: [
              if (_isEditing &&
                  widget.supplierId != null &&
                  context.userCanDelete(AppModule.suppliers))
                IconButton(
                  onPressed: isSaving
                      ? null
                      : () => _confirmDelete(context, widget.supplierId!),
                  icon: const Icon(Icons.delete_outline),
                  tooltip: AppStrings.delete,
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                SettingsSection(
                  title: AppStrings.supplierInformation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.companyName,
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) => Validators.requiredText(
                            value,
                            field: 'Supplier name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<SupplierType>(
                          initialValue: _supplierType,
                          decoration: const InputDecoration(
                            labelText: AppStrings.supplierType,
                          ),
                          items: SupplierType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _supplierType = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.phone,
                          ),
                          keyboardType: TextInputType.phone,
                          validator: Validators.phone,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<PaymentTerms>(
                          initialValue: _paymentTerms,
                          decoration: const InputDecoration(
                            labelText: AppStrings.paymentTerms,
                          ),
                          items: PaymentTerms.values
                              .map(
                                (terms) => DropdownMenuItem(
                                  value: terms,
                                  child: Text(terms.label),
                                ),
                              )
                              .toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _paymentTerms = value);
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
                SettingsSection(
                  title: AppStrings.optionalDetails,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _contactPersonController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.contactPerson,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneSecondaryController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.secondaryPhone,
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.city,
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.address,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _cnicNtnController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.cnicNtn,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _materialsController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.materialsSupplied,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _notesController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.notes,
                          ),
                          maxLines: 3,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    onPressed:
                        isSaving ? null : () => _submit(context, supplier),
                    child: isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isEditing
                                ? AppStrings.saveSupplier
                                : AppStrings.addSupplier,
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
