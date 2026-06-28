import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/customer/customer_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/enums/customer_enums.dart';
import '../../widgets/customers/customer_service_type_selector.dart';
import '../../widgets/dialogs/app_confirm_dialog.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class AddEditCustomerScreen extends StatefulWidget {
  const AddEditCustomerScreen({this.customerId, super.key});

  final String? customerId;

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();

  CustomerType _customerType = CustomerType.individual;
  CustomerServiceType _serviceType = CustomerServiceType.buyer;
  CustomerCategory _category = CustomerCategory.retail;
  PaymentTerms _paymentTerms = PaymentTerms.cash;
  bool _useSameShippingAddress = true;

  final _nameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phoneSecondaryController = TextEditingController();
  final _whatsAppController = TextEditingController();
  final _emailController = TextEditingController();
  final _billingStreetController = TextEditingController();
  final _billingCityController = TextEditingController();
  final _billingProvinceController = TextEditingController();
  final _shippingStreetController = TextEditingController();
  final _shippingCityController = TextEditingController();
  final _shippingProvinceController = TextEditingController();
  final _cnicNtnController = TextEditingController();
  final _otherServiceController = TextEditingController();
  final _creditLimitController = TextEditingController(text: '0');
  final _openingBalanceController = TextEditingController(text: '0');
  final _referredByController = TextEditingController();
  final _notesController = TextEditingController();

  bool _populated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactPersonController.dispose();
    _phoneController.dispose();
    _phoneSecondaryController.dispose();
    _whatsAppController.dispose();
    _emailController.dispose();
    _billingStreetController.dispose();
    _billingCityController.dispose();
    _billingProvinceController.dispose();
    _shippingStreetController.dispose();
    _shippingCityController.dispose();
    _shippingProvinceController.dispose();
    _cnicNtnController.dispose();
    _otherServiceController.dispose();
    _creditLimitController.dispose();
    _openingBalanceController.dispose();
    _referredByController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateForm(Customer customer) {
    if (_populated) return;
    _populated = true;

    _customerType = customer.customerType;
    _serviceType = customer.serviceType;
    _category = customer.category;
    _paymentTerms = customer.paymentTerms;
    _useSameShippingAddress = customer.useSameShippingAddress;

    _nameController.text = customer.name;
    _contactPersonController.text = customer.contactPersonName ?? '';
    _phoneController.text = customer.phone;
    _phoneSecondaryController.text = customer.phoneSecondary ?? '';
    _whatsAppController.text = customer.whatsApp ?? '';
    _emailController.text = customer.email ?? '';
    _billingStreetController.text = customer.billingStreet ?? '';
    _billingCityController.text = customer.billingCity ?? '';
    _billingProvinceController.text = customer.billingProvince ?? '';
    _shippingStreetController.text = customer.shippingStreet ?? '';
    _shippingCityController.text = customer.shippingCity ?? '';
    _shippingProvinceController.text = customer.shippingProvince ?? '';
    _cnicNtnController.text = customer.cnicNtn ?? '';
    _otherServiceController.text = customer.otherServiceDescription ?? '';
    _creditLimitController.text = customer.creditLimit.toStringAsFixed(0);
    _openingBalanceController.text = customer.openingBalance.toStringAsFixed(0);
    _referredByController.text = customer.referredBy ?? '';
    _notesController.text = customer.notes ?? '';
  }

  double _parseAmount(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  String _subtitle(Customer? customer) {
    if (widget.customerId != null) {
      final name = _nameController.text.trim();
      if (name.isNotEmpty) return name;
      return customer?.name ?? '';
    }
    return AppStrings.addCustomer;
  }

  Customer? _buildCustomer(Customer? existing) {
    if (existing == null) return null;

    return existing.copyWith(
      customerType: _customerType,
      name: _nameController.text.trim(),
      contactPersonName: _contactPersonController.text.trim().isEmpty
          ? null
          : _contactPersonController.text.trim(),
      phone: _phoneController.text.trim(),
      phoneSecondary: _phoneSecondaryController.text.trim().isEmpty
          ? null
          : _phoneSecondaryController.text.trim(),
      whatsApp: _whatsAppController.text.trim().isEmpty
          ? null
          : _whatsAppController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      billingStreet: _billingStreetController.text.trim().isEmpty
          ? null
          : _billingStreetController.text.trim(),
      billingCity: _billingCityController.text.trim().isEmpty
          ? null
          : _billingCityController.text.trim(),
      billingProvince: _billingProvinceController.text.trim().isEmpty
          ? null
          : _billingProvinceController.text.trim(),
      shippingStreet: _useSameShippingAddress
          ? null
          : (_shippingStreetController.text.trim().isEmpty
              ? null
              : _shippingStreetController.text.trim()),
      shippingCity: _useSameShippingAddress
          ? null
          : (_shippingCityController.text.trim().isEmpty
              ? null
              : _shippingCityController.text.trim()),
      shippingProvince: _useSameShippingAddress
          ? null
          : (_shippingProvinceController.text.trim().isEmpty
              ? null
              : _shippingProvinceController.text.trim()),
      useSameShippingAddress: _useSameShippingAddress,
      cnicNtn: _cnicNtnController.text.trim().isEmpty
          ? null
          : _cnicNtnController.text.trim(),
      category: _category,
      serviceType: _serviceType,
      otherServiceDescription: _serviceType == CustomerServiceType.other
          ? _otherServiceController.text.trim()
          : null,
      creditLimit: _parseAmount(_creditLimitController.text),
      paymentTerms: _paymentTerms,
      referredBy: _referredByController.text.trim().isEmpty
          ? null
          : _referredByController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      openingBalance: existing.id.isEmpty
          ? _parseAmount(_openingBalanceController.text)
          : existing.openingBalance,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final blocState = context.read<CustomerFormBloc>().state;
    final customer = _buildCustomer(blocState.customer);
    if (customer == null) return;

    context.read<CustomerFormBloc>().add(CustomerFormSubmitted(customer));
  }

  Future<void> _confirmDelete() async {
    final customerId = widget.customerId;
    if (customerId == null) return;

    final formBloc = context.read<CustomerFormBloc>();
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.deleteCustomerTitle,
      message: AppStrings.deleteCustomerMessage,
      confirmLabel: AppStrings.delete,
      destructive: true,
    );

    if (!confirmed) return;

    formBloc.add(CustomerFormDeleteRequested(customerId));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.customerId != null;

    return BlocConsumer<CustomerFormBloc, CustomerFormState>(
      listener: (context, state) {
        if (state.status == CustomerFormStatus.ready && state.customer != null) {
          _populateForm(state.customer!);
        }

        if (state.status == CustomerFormStatus.saved) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                  isEditing
                      ? AppStrings.customerUpdated
                      : AppStrings.customerCreated,
                ),
              ),
            );
          context.pop();
        }

        if (state.status == CustomerFormStatus.deleted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text(AppStrings.customerDeleted)),
            );
          context.pop();
          if (context.canPop()) context.pop();
        }

        if (state.status == CustomerFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        if (state.status == CustomerFormStatus.loading) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                isEditing ? AppStrings.editCustomer : AppStrings.addCustomer,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == CustomerFormStatus.failure &&
            state.customer == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.editCustomer)),
            body: Center(child: Text(state.errorMessage ?? 'Error')),
          );
        }

        final isSaving = state.status == CustomerFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: AppFormAppBarTitle(
              title: isEditing
                  ? AppStrings.editCustomer
                  : AppStrings.addCustomer,
              subtitle: _subtitle(state.customer),
            ),
            actions: [
              if (isEditing)
                IconButton(
                  onPressed: isSaving ? null : _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: AppStrings.delete,
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.serviceTypeRequired,
                  icon: Icons.category_outlined,
                  child: AppFormSectionBody(
                    children: [
                      CustomerServiceTypeSelector(
                        selected: _serviceType,
                        onChanged: isSaving
                            ? (_) {}
                            : (value) => setState(() => _serviceType = value),
                      ),
                      if (_serviceType == CustomerServiceType.other) ...[
                        AppFormFields.gap,
                        TextFormField(
                          controller: _otherServiceController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.otherServiceDescription,
                          ),
                          validator: (value) => Validators.serviceDescription(
                            value,
                            required: true,
                          ),
                          enabled: !isSaving,
                        ),
                      ],
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.basicInformation,
                  icon: Icons.person_outline,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<CustomerType>(
                        key: ValueKey(_customerType),
                        initialValue: _customerType,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.customerType,
                        ),
                        items: CustomerType.values
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(
                                  type.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _customerType = value);
                              },
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _nameController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: _customerType == CustomerType.business
                              ? AppStrings.companyName
                              : AppStrings.fullName,
                        ),
                        validator: (value) => Validators.requiredText(
                          value,
                          field: AppStrings.name,
                        ),
                        enabled: !isSaving,
                      ),
                      if (_customerType == CustomerType.business) ...[
                        AppFormFields.gap,
                        TextFormField(
                          controller: _contactPersonController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.contactPerson,
                          ),
                          enabled: !isSaving,
                        ),
                      ],
                      AppFormFields.gap,
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.phone,
                        ),
                        validator: Validators.phone,
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _phoneSecondaryController,
                        keyboardType: TextInputType.phone,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.secondaryPhone,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _whatsAppController,
                        keyboardType: TextInputType.phone,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.whatsApp,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.email,
                        ),
                        validator: Validators.optionalEmail,
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.address,
                  icon: Icons.location_on_outlined,
                  child: AppFormSectionBody(
                    children: [
                      TextFormField(
                        controller: _billingStreetController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.street,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _billingCityController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.city,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _billingProvinceController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.province,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        dense: true,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        title: Text(
                          AppStrings.sameShippingAddress,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        value: _useSameShippingAddress,
                        onChanged: isSaving
                            ? null
                            : (value) => setState(
                                  () => _useSameShippingAddress = value,
                                ),
                      ),
                      if (!_useSameShippingAddress) ...[
                        AppFormFields.gap,
                        TextFormField(
                          controller: _shippingStreetController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.shippingStreet,
                          ),
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _shippingCityController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.shippingCity,
                          ),
                          enabled: !isSaving,
                        ),
                        AppFormFields.gap,
                        TextFormField(
                          controller: _shippingProvinceController,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.shippingProvince,
                          ),
                          enabled: !isSaving,
                        ),
                      ],
                    ],
                  ),
                ),
                JobWorkDetailSection(
                  title: AppStrings.businessDetails,
                  icon: Icons.business_outlined,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<CustomerCategory>(
                        key: ValueKey(_category),
                        initialValue: _category,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.customerCategory,
                        ),
                        items: CustomerCategory.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _category = value);
                              },
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _cnicNtnController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.cnicNtn,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      DropdownButtonFormField<PaymentTerms>(
                        key: ValueKey(_paymentTerms),
                        initialValue: _paymentTerms,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.paymentTerms,
                        ),
                        items: PaymentTerms.values
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(
                                  item.label,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setState(() => _paymentTerms = value);
                              },
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _creditLimitController,
                        keyboardType: TextInputType.number,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.creditLimit,
                        ),
                        enabled: !isSaving,
                      ),
                      if (!isEditing) ...[
                        AppFormFields.gap,
                        TextFormField(
                          controller: _openingBalanceController,
                          keyboardType: TextInputType.number,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.openingBalance,
                          ),
                          enabled: !isSaving,
                        ),
                      ],
                      AppFormFields.gap,
                      TextFormField(
                        controller: _referredByController,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.referredBy,
                        ),
                        enabled: !isSaving,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.notes,
                        ),
                        enabled: !isSaving,
                      ),
                    ],
                  ),
                ),
                AppFormSubmitBar(
                  label: isEditing
                      ? AppStrings.saveChanges
                      : AppStrings.saveCustomer,
                  isLoading: isSaving,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
