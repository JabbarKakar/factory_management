import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/business_profile/business_profile_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/entities/bank_account.dart';
import '../../../domain/entities/factory_profile.dart';
import '../../../domain/enums/business_profile_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/forms/app_form_fields.dart';
import 'widgets/bank_account_dialog.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  // Form Keys for each section
  final _identityFormKey = GlobalKey<FormState>();
  final _contactFormKey = GlobalKey<FormState>();
  final _legalFormKey = GlobalKey<FormState>();
  final _invoiceFormKey = GlobalKey<FormState>();
  final _opFormKey = GlobalKey<FormState>();
  final _ownerFormKey = GlobalKey<FormState>();

  // Section 1: Core Identity
  late TextEditingController _businessNameController;
  late TextEditingController _legalNameController;
  late TextEditingController _taglineController;
  late TextEditingController _establishedYearController;
  String _businessType = 'Private Limited';

  // Section 2: Contact
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;
  late TextEditingController _phoneAltController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _googleMapsLinkController;
  String _province = 'Punjab';

  // Section 3: Tax & Legal
  late TextEditingController _ntnController;
  late TextEditingController _strnController;
  late TextEditingController _cnicController;
  late TextEditingController _businessRegNoController;
  FilerStatus _filerStatus = FilerStatus.filer;

  // Section 4: Bank & Payment
  List<String> _selectedPaymentMethods = [];

  // Section 5: Invoicing Rules
  late TextEditingController _prefixSalesController;
  late TextEditingController _prefixJobWorkController;
  late TextEditingController _startingNumberController;
  late TextEditingController _defaultPaymentTermsController;
  late TextEditingController _termsAndConditionsController;
  late TextEditingController _footerNoteController;
  String _currency = 'PKR';

  // Section 6: Operational
  late TextEditingController _workingHoursController;
  int _fiscalYearStartMonth = 7;
  String _timezone = 'Asia/Karachi';
  List<int> _workingDays = [1, 2, 3, 4, 5, 6];

  // Section 7: Ownership
  late TextEditingController _ownerNameController;
  late TextEditingController _ownerPhoneController;
  late TextEditingController _ownerEmailController;

  bool _initialized = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _provinces = const [
    'Punjab',
    'Sindh',
    'Khyber Pakhtunkhwa',
    'Balochistan',
    'Islamabad Capital Territory',
    'Gilgit-Baltistan',
    'Azad Jammu & Kashmir',
  ];

  final List<String> _businessTypes = const [
    'Sole Proprietorship',
    'Partnership',
    'Private Limited',
    'Single Member Company',
    'Public Limited',
    'Other',
  ];

  final Map<int, String> _months = const {
    1: 'January',
    2: 'February',
    3: 'March',
    4: 'April',
    5: 'May',
    6: 'June',
    7: 'July (Standard PK)',
    8: 'August',
    9: 'September',
    10: 'October',
    11: 'November',
    12: 'December',
  };

  final List<String> _paymentMethodOptions = const [
    'cash',
    'bank_transfer',
    'cheque',
    'easypaisa',
    'jazzcash',
  ];

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _legalNameController = TextEditingController();
    _taglineController = TextEditingController();
    _establishedYearController = TextEditingController();

    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _phoneController = TextEditingController();
    _phoneAltController = TextEditingController();
    _whatsappController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _googleMapsLinkController = TextEditingController();

    _ntnController = TextEditingController();
    _strnController = TextEditingController();
    _cnicController = TextEditingController();
    _businessRegNoController = TextEditingController();

    _prefixSalesController = TextEditingController();
    _prefixJobWorkController = TextEditingController();
    _startingNumberController = TextEditingController();
    _defaultPaymentTermsController = TextEditingController();
    _termsAndConditionsController = TextEditingController();
    _footerNoteController = TextEditingController();

    _workingHoursController = TextEditingController();

    _ownerNameController = TextEditingController();
    _ownerPhoneController = TextEditingController();
    _ownerEmailController = TextEditingController();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _legalNameController.dispose();
    _taglineController.dispose();
    _establishedYearController.dispose();

    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _phoneAltController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _googleMapsLinkController.dispose();

    _ntnController.dispose();
    _strnController.dispose();
    _cnicController.dispose();
    _businessRegNoController.dispose();

    _prefixSalesController.dispose();
    _prefixJobWorkController.dispose();
    _startingNumberController.dispose();
    _defaultPaymentTermsController.dispose();
    _termsAndConditionsController.dispose();
    _footerNoteController.dispose();

    _workingHoursController.dispose();

    _ownerNameController.dispose();
    _ownerPhoneController.dispose();
    _ownerEmailController.dispose();
    super.dispose();
  }

  void _populateData(FactoryProfile profile) {
    if (_initialized) return;
    _initialized = true;

    _businessNameController.text = profile.identity.businessName;
    _legalNameController.text = profile.identity.legalName ?? '';
    _taglineController.text = profile.identity.tagline ?? '';
    _establishedYearController.text =
        profile.identity.establishedYear?.toString() ?? '';
    if (profile.identity.businessType != null &&
        _businessTypes.contains(profile.identity.businessType)) {
      _businessType = profile.identity.businessType!;
    }

    _addressController.text = profile.contact.address;
    _cityController.text = profile.contact.city;
    _phoneController.text = profile.contact.phone;
    _phoneAltController.text = profile.contact.phoneAlt ?? '';
    _whatsappController.text = profile.contact.whatsapp ?? '';
    _emailController.text = profile.contact.email ?? '';
    _websiteController.text = profile.contact.website ?? '';
    _googleMapsLinkController.text = profile.contact.googleMapsLink ?? '';
    if (_provinces.contains(profile.contact.province)) {
      _province = profile.contact.province;
    }

    _ntnController.text = profile.legal.ntn ?? '';
    _strnController.text = profile.legal.strn ?? '';
    _cnicController.text = profile.legal.cnic ?? '';
    _businessRegNoController.text = profile.legal.businessRegNo ?? '';
    _filerStatus = profile.legal.filerStatus;

    _selectedPaymentMethods = List.from(profile.paymentMethodsAccepted);

    _prefixSalesController.text = profile.invoiceSettings.prefixSales;
    _prefixJobWorkController.text = profile.invoiceSettings.prefixJobWork;
    _startingNumberController.text =
        profile.invoiceSettings.startingNumber.toString();
    _defaultPaymentTermsController.text =
        profile.invoiceSettings.defaultPaymentTerms;
    _termsAndConditionsController.text =
        profile.invoiceSettings.termsAndConditions ?? '';
    _footerNoteController.text = profile.invoiceSettings.footerNote ?? '';
    _currency = profile.invoiceSettings.currency;

    _workingHoursController.text = profile.operational.workingHours ?? '';
    _fiscalYearStartMonth = profile.operational.fiscalYearStartMonth;
    _timezone = profile.operational.timezone;
    _workingDays = List.from(profile.operational.workingDays);

    _ownerNameController.text = profile.ownership.ownerName ?? '';
    _ownerPhoneController.text = profile.ownership.ownerPhone ?? '';
    _ownerEmailController.text = profile.ownership.ownerEmail ?? '';
  }

  Future<void> _pickAndUploadImage(
      BuildContext context, ImageType type) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // native platform image compression
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (file == null || !mounted) return;

      context.read<BusinessProfileBloc>().add(
            UploadProfileImage(
              imageFile: File(file.path),
              type: type,
            ),
          );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick image: $e')),
      );
    }
  }

  void _saveSection(
      BuildContext context, ProfileSection section, FactoryProfile current) {
    late FactoryProfile updated;

    switch (section) {
      case ProfileSection.identity:
        if (!_identityFormKey.currentState!.validate()) return;
        final year = int.tryParse(_establishedYearController.text.trim());
        updated = current.copyWith(
          identity: current.identity.copyWith(
            businessName: _businessNameController.text.trim(),
            legalName: _legalNameController.text.trim().isEmpty
                ? null
                : _legalNameController.text.trim(),
            tagline: _taglineController.text.trim().isEmpty
                ? null
                : _taglineController.text.trim(),
            businessType: _businessType,
            establishedYear: year,
          ),
        );
        break;

      case ProfileSection.contact:
        if (!_contactFormKey.currentState!.validate()) return;
        updated = current.copyWith(
          contact: current.contact.copyWith(
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            province: _province,
            phone: _phoneController.text.trim(),
            phoneAlt: _phoneAltController.text.trim().isEmpty
                ? null
                : _phoneAltController.text.trim(),
            whatsapp: _whatsappController.text.trim().isEmpty
                ? null
                : _whatsappController.text.trim(),
            email: _emailController.text.trim().isEmpty
                ? null
                : _emailController.text.trim(),
            website: _websiteController.text.trim().isEmpty
                ? null
                : _websiteController.text.trim(),
            googleMapsLink: _googleMapsLinkController.text.trim().isEmpty
                ? null
                : _googleMapsLinkController.text.trim(),
          ),
        );
        break;

      case ProfileSection.legal:
        if (!_legalFormKey.currentState!.validate()) return;
        updated = current.copyWith(
          legal: current.legal.copyWith(
            ntn: _ntnController.text.trim().isEmpty
                ? null
                : _ntnController.text.trim(),
            strn: _strnController.text.trim().isEmpty
                ? null
                : _strnController.text.trim(),
            cnic: _cnicController.text.trim().isEmpty
                ? null
                : _cnicController.text.trim(),
            businessRegNo: _businessRegNoController.text.trim().isEmpty
                ? null
                : _businessRegNoController.text.trim(),
            filerStatus: _filerStatus,
          ),
        );
        break;

      case ProfileSection.paymentMethods:
        updated = current.copyWith(
          paymentMethodsAccepted: _selectedPaymentMethods,
        );
        break;

      case ProfileSection.invoiceSettings:
        if (!_invoiceFormKey.currentState!.validate()) return;
        final startingNum =
            int.tryParse(_startingNumberController.text.trim()) ?? 1001;
        updated = current.copyWith(
          invoiceSettings: current.invoiceSettings.copyWith(
            prefixSales: _prefixSalesController.text.trim(),
            prefixJobWork: _prefixJobWorkController.text.trim(),
            startingNumber: startingNum,
            defaultPaymentTerms: _defaultPaymentTermsController.text.trim(),
            termsAndConditions:
                _termsAndConditionsController.text.trim().isEmpty
                    ? null
                    : _termsAndConditionsController.text.trim(),
            footerNote: _footerNoteController.text.trim().isEmpty
                ? null
                : _footerNoteController.text.trim(),
            currency: _currency,
          ),
        );
        break;

      case ProfileSection.operational:
        if (!_opFormKey.currentState!.validate()) return;
        updated = current.copyWith(
          operational: current.operational.copyWith(
            workingHours: _workingHoursController.text.trim().isEmpty
                ? null
                : _workingHoursController.text.trim(),
            fiscalYearStartMonth: _fiscalYearStartMonth,
            timezone: _timezone,
            workingDays: _workingDays,
          ),
        );
        break;

      case ProfileSection.ownership:
        if (!_ownerFormKey.currentState!.validate()) return;
        updated = current.copyWith(
          ownership: current.ownership.copyWith(
            ownerName: _ownerNameController.text.trim().isEmpty
                ? null
                : _ownerNameController.text.trim(),
            ownerPhone: _ownerPhoneController.text.trim().isEmpty
                ? null
                : _ownerPhoneController.text.trim(),
            ownerEmail: _ownerEmailController.text.trim().isEmpty
                ? null
                : _ownerEmailController.text.trim(),
          ),
        );
        break;

      case ProfileSection.bankAccounts:
        // Handled via separate Add/Edit/Delete Bank Account actions
        return;
    }

    context.read<BusinessProfileBloc>().add(
          UpdateBusinessProfileSection(
            profile: updated,
            section: section,
          ),
        );
  }

  void _openBankAccountModal(
      BuildContext context, BankAccount? account) async {
    final result = await showDialog<BankAccount>(
      context: context,
      builder: (_) => BankAccountDialog(account: account),
    );

    if (result != null && mounted) {
      if (account == null) {
        context.read<BusinessProfileBloc>().add(AddBankAccount(result));
      } else {
        context.read<BusinessProfileBloc>().add(UpdateBankAccount(result));
      }
    }
  }

  // Helper Soft Warning check for NTN format
  String? _validateNTNSoft(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final clean = val.trim();
    // NTN pattern: 7 digits or #####-#
    final ntnRegex = RegExp(r'^\d{7}(-\d)?$');
    if (!ntnRegex.hasMatch(clean)) {
      return 'Note: Standard PK NTN is usually 7 digits (e.g. 1234567-8).';
    }
    return null;
  }

  // Helper Soft Warning check for STRN format
  String? _validateSTRNSoft(String? val) {
    if (val == null || val.trim().isEmpty) return null;
    final clean = val.trim();
    // STRN pattern: 13 digits
    final strnRegex = RegExp(r'^\d{13}$');
    if (!strnRegex.hasMatch(clean)) {
      return 'Note: Standard PK STRN is 13 digits.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final canEdit = user?.canEditFactoryProfile ?? false;

    return BlocConsumer<BusinessProfileBloc, BusinessProfileState>(
      listener: (context, state) {
        if (state is BusinessProfileLoaded) {
          final message = state.successMessage ?? state.errorMessage;
          if (message != null) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: state.errorMessage != null
                      ? Colors.red
                      : Colors.green.shade700,
                ),
              );
          }
        }
      },
      builder: (context, state) {
        if (state is BusinessProfileLoading || state is BusinessProfileInitial) {
          return Scaffold(
            appBar: AppBar(title: const Text('Business Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state is BusinessProfileFailure) {
          return Scaffold(
            appBar: AppBar(title: const Text('Business Profile')),
            body: EmptyStateView(
              icon: Icons.error_outline,
              title: 'Unable to Load Profile',
              subtitle: state.errorMessage,
            ),
          );
        }

        final loaded = state as BusinessProfileLoaded;
        _populateData(loaded.profile);

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loaded.profile.name),
                Text(
                  'Manufacturing & Business Profile Settings',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ],
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              if (!canEdit)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DashboardSurfaceCard(
                    compact: true,
                    borderRadius: 14,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      AppStrings.readOnlyProfileNote,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            height: 1.35,
                          ),
                    ),
                  ),
                ),

              // -------------------------------------------------------------
              // SECTION 1: CORE IDENTITY & BRANDING
              // -------------------------------------------------------------
              _buildSectionTile(
                context: context,
                section: ProfileSection.identity,
                icon: Icons.business,
                isSaving: loaded.isSaving,
                canEdit: canEdit,
                onSave: () => _saveSection(
                    context, ProfileSection.identity, loaded.profile),
                child: Form(
                  key: _identityFormKey,
                  child: Column(
                    children: [
                      // Logo Uploader Card
                      _buildImageUploadCard(
                        context: context,
                        type: ImageType.logo,
                        imageUrl: loaded.profile.identity.logoUrl,
                        isUploading:
                            loaded.uploadingImageType == ImageType.logo,
                        canEdit: canEdit,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _businessNameController,
                        enabled: canEdit && !loaded.isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Business / Factory Name *',
                        ),
                        validator: (v) => Validators.requiredText(v,
                            field: 'Business Name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _legalNameController,
                        enabled: canEdit && !loaded.isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Legal Registered Name',
                          hint: 'e.g. Jabbar Mills (Pvt) Ltd',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _taglineController,
                        enabled: canEdit && !loaded.isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Business Tagline / Motto',
                          hint: 'e.g. Premium Quality Textile Manufacturing',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _businessType,
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Business Entity Type',
                              ),
                              items: _businessTypes
                                  .map((t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ))
                                  .toList(),
                              onChanged: canEdit
                                  ? (val) {
                                      if (val != null) {
                                        setState(() => _businessType = val);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _establishedYearController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.number,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Established Year',
                                hint: 'e.g. 2018',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // SECTION 2: CONTACT & LOCATION
              // -------------------------------------------------------------
              _buildSectionTile(
                context: context,
                section: ProfileSection.contact,
                icon: Icons.location_on_outlined,
                isSaving: loaded.isSaving,
                canEdit: canEdit,
                onSave: () =>
                    _saveSection(context, ProfileSection.contact, loaded.profile),
                child: Form(
                  key: _contactFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _addressController,
                        enabled: canEdit && !loaded.isSaving,
                        maxLines: 2,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Factory Physical Address *',
                          hint: 'Plot #, Industrial Area, Sector...',
                        ),
                        validator: (v) =>
                            Validators.requiredText(v, field: 'Address'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              enabled: canEdit && !loaded.isSaving,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'City',
                                hint: 'Faisalabad / Karachi / Lahore',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _province,
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Province',
                              ),
                              items: _provinces
                                  .map((p) => DropdownMenuItem(
                                        value: p,
                                        child: Text(p,
                                            overflow: TextOverflow.ellipsis),
                                      ))
                                  .toList(),
                              onChanged: canEdit
                                  ? (val) {
                                      if (val != null) {
                                        setState(() => _province = val);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.phone,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Primary Phone *',
                                hint: '+92 300 1234567',
                              ),
                              validator: Validators.phone,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneAltController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.phone,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Secondary / Landline',
                                hint: '041 8765432',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _whatsappController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.phone,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'WhatsApp Business Number',
                                hint: '+92 300 1234567',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.emailAddress,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Factory Email',
                                hint: 'info@factory.pk',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _websiteController,
                        enabled: canEdit && !loaded.isSaving,
                        keyboardType: TextInputType.url,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Website URL',
                          hint: 'https://www.factory.pk',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _googleMapsLinkController,
                        enabled: canEdit && !loaded.isSaving,
                        keyboardType: TextInputType.url,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Google Maps Link',
                          hint: 'https://maps.google.com/?q=...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // SECTION 3: TAX & LEGAL IDENTIFIERS
              // -------------------------------------------------------------
              _buildSectionTile(
                context: context,
                section: ProfileSection.legal,
                icon: Icons.gavel_outlined,
                isSaving: loaded.isSaving,
                canEdit: canEdit,
                onSave: () =>
                    _saveSection(context, ProfileSection.legal, loaded.profile),
                child: Form(
                  key: _legalFormKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ntnController,
                              enabled: canEdit && !loaded.isSaving,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'NTN (National Tax No.)',
                                hint: '1234567-8',
                              ),
                              validator: _validateNTNSoft,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _strnController,
                              enabled: canEdit && !loaded.isSaving,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'STRN (Sales Tax Reg No.)',
                                hint: '3277876123456',
                              ),
                              validator: _validateSTRNSoft,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cnicController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.number,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Owner / Representative CNIC',
                                hint: '35202-1234567-1',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _businessRegNoController,
                              enabled: canEdit && !loaded.isSaving,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Secp / Reg No.',
                                hint: 'CUIN / Reg #',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Filer Tax Status (FBR Active Taxpayer)',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: FilerStatus.values.map((status) {
                              final selected = _filerStatus == status;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(status.label),
                                  selected: selected,
                                  onSelected: canEdit
                                      ? (val) {
                                          if (val) {
                                            setState(() => _filerStatus = status);
                                          }
                                        }
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // SECTION 4: BANK ACCOUNTS & PAYMENT METHODS
              // -------------------------------------------------------------
              _buildSectionTile(
                context: context,
                section: ProfileSection.bankAccounts,
                icon: Icons.account_balance_outlined,
                isSaving: loaded.isSaving,
                canEdit: canEdit,
                showSaveButton: false, // Save happens directly on bank actions
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Company Bank Accounts',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (canEdit)
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Bank Account'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () =>
                                _openBankAccountModal(context, null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (loaded.profile.bankAccounts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No bank accounts added yet. Click above to add bank details for invoices.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      Column(
                        children: loaded.profile.bankAccounts.map((acc) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(
                                  Icons.account_balance,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              title: Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(
                                    acc.bankName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  if (acc.isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'DEFAULT',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                '${acc.accountName}\nAcc: ${acc.accountNumber}${acc.iban != null ? " • IBAN: ${acc.iban}" : ""}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              isThreeLine: true,
                              trailing: canEdit
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              size: 20),
                                          onPressed: () =>
                                              _openBankAccountModal(
                                                  context, acc),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.delete_outline,
                                              size: 20,
                                              color: Colors.red),
                                          onPressed: () {
                                            context
                                                .read<BusinessProfileBloc>()
                                                .add(DeleteBankAccount(acc.id));
                                          },
                                        ),
                                      ],
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),

                    const Divider(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Accepted Payment Methods',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (canEdit)
                          TextButton(
                            onPressed: () => _saveSection(
                              context,
                              ProfileSection.paymentMethods,
                              loaded.profile,
                            ),
                            child: const Text('Save Payments'),
                          ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: _paymentMethodOptions.map((pm) {
                        final selected = _selectedPaymentMethods.contains(pm);
                        return FilterChip(
                          label: Text(pm.replaceAll('_', ' ').toUpperCase()),
                          selected: selected,
                          onSelected: canEdit
                              ? (val) {
                                  setState(() {
                                    if (val) {
                                      _selectedPaymentMethods.add(pm);
                                    } else {
                                      _selectedPaymentMethods.remove(pm);
                                    }
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // SECTION 5: INVOICING & DOCUMENT RULES
              // -------------------------------------------------------------
              _buildSectionTile(
                context: context,
                section: ProfileSection.invoiceSettings,
                icon: Icons.receipt_long_outlined,
                isSaving: loaded.isSaving,
                canEdit: canEdit,
                onSave: () => _saveSection(
                    context, ProfileSection.invoiceSettings, loaded.profile),
                child: Form(
                  key: _invoiceFormKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _prefixSalesController,
                              enabled: canEdit && !loaded.isSaving,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Sales Invoice Prefix',
                                hint: 'INV',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _prefixJobWorkController,
                              enabled: canEdit && !loaded.isSaving,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Job-Work Prefix',
                                hint: 'JW-INV',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _startingNumberController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.number,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Start Number',
                                hint: '1001',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _defaultPaymentTermsController,
                              enabled: canEdit && !loaded.isSaving,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Default Payment Terms',
                                hint: 'Net 30 / On Receipt',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _currency,
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Base Currency',
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'PKR',
                                    child: Text('PKR - Pakistani Rupee')),
                                DropdownMenuItem(
                                    value: 'USD', child: Text('USD - US Dollar')),
                                DropdownMenuItem(
                                    value: 'EUR', child: Text('EUR - Euro')),
                                DropdownMenuItem(
                                    value: 'AED', child: Text('AED - Dirham')),
                              ],
                              onChanged: canEdit
                                  ? (val) {
                                      if (val != null) {
                                        setState(() => _currency = val);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _termsAndConditionsController,
                        enabled: canEdit && !loaded.isSaving,
                        maxLines: 3,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Terms & Conditions (Printed on Invoices)',
                          hint:
                              '1. Payment due within specified period...\n2. Goods once sold cannot be returned without prior inspection...',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _footerNoteController,
                        enabled: canEdit && !loaded.isSaving,
                        maxLines: 2,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Invoice Footer Note',
                          hint:
                              'Thank you for doing business with us! - Generated via Factory Management System',
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildImageUploadCard(
                        context: context,
                        type: ImageType.signature,
                        imageUrl:
                            loaded.profile.invoiceSettings.signatureImageUrl,
                        isUploading:
                            loaded.uploadingImageType == ImageType.signature,
                        canEdit: canEdit,
                      ),
                      const SizedBox(height: 12),
                      _buildImageUploadCard(
                        context: context,
                        type: ImageType.stamp,
                        imageUrl: loaded.profile.invoiceSettings.stampImageUrl,
                        isUploading:
                            loaded.uploadingImageType == ImageType.stamp,
                        canEdit: canEdit,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // SECTION 6: OPERATIONAL & FISCAL PREFERENCES
              // -------------------------------------------------------------
              _buildSectionTile(
                context: context,
                section: ProfileSection.operational,
                icon: Icons.access_time_outlined,
                isSaving: loaded.isSaving,
                canEdit: canEdit,
                onSave: () => _saveSection(
                    context, ProfileSection.operational, loaded.profile),
                child: Form(
                  key: _opFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: _fiscalYearStartMonth,
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Fiscal Year Start Month',
                              ),
                              items: _months.entries
                                  .map((entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Text(entry.value),
                                      ))
                                  .toList(),
                              onChanged: canEdit
                                  ? (val) {
                                      if (val != null) {
                                        setState(
                                            () => _fiscalYearStartMonth = val);
                                      }
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _workingHoursController,
                              enabled: canEdit && !loaded.isSaving,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Factory Operating Hours',
                                hint: '08:00 AM - 05:00 PM',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Working Days',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        children: List.generate(7, (index) {
                          final dayIndex = index + 1; // 1 = Mon ... 7 = Sun
                          final dayNames = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          final selected = _workingDays.contains(dayIndex);
                          return FilterChip(
                            label: Text(dayNames[index]),
                            selected: selected,
                            onSelected: canEdit
                                ? (val) {
                                    setState(() {
                                      if (val) {
                                        _workingDays.add(dayIndex);
                                      } else {
                                        _workingDays.remove(dayIndex);
                                      }
                                    });
                                  }
                                : null,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // -------------------------------------------------------------
              // SECTION 7: OWNERSHIP & AUTHORIZED SIGNATORIES
              // -------------------------------------------------------------
              _buildSectionTile(
                context: context,
                section: ProfileSection.ownership,
                icon: Icons.person_outline,
                isSaving: loaded.isSaving,
                canEdit: canEdit,
                onSave: () => _saveSection(
                    context, ProfileSection.ownership, loaded.profile),
                child: Form(
                  key: _ownerFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _ownerNameController,
                        enabled: canEdit && !loaded.isSaving,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: 'Owner / Chief Executive Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ownerPhoneController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.phone,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Owner Contact Phone',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _ownerEmailController,
                              enabled: canEdit && !loaded.isSaving,
                              keyboardType: TextInputType.emailAddress,
                              style: AppFormFields.valueStyle(context),
                              decoration: AppFormFields.decoration(
                                context,
                                label: 'Owner Email',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper to render unified Section Card Accordions
  Widget _buildSectionTile({
    required BuildContext context,
    required ProfileSection section,
    required IconData icon,
    required bool isSaving,
    required bool canEdit,
    required Widget child,
    VoidCallback? onSave,
    bool showSaveButton = true,
  }) {
    return DashboardSurfaceCard(
      compact: true,
      borderRadius: 14,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: PageStorageKey<String>('business_profile_section_${section.name}'),
          maintainState: true,
          initiallyExpanded: section == ProfileSection.identity ||
              section == ProfileSection.contact,
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            child,
            if (canEdit && showSaveButton && onSave != null) ...[
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check, size: 18),
                  label: Text('Save ${section.title}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper for Image Upload Widget Cards (Logo, Signature, Stamp)
  Widget _buildImageUploadCard({
    required BuildContext context,
    required ImageType type,
    required String? imageUrl,
    required bool isUploading,
    required bool canEdit,
  }) {
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: hasImage
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                    )
                  : Icon(
                      type == ImageType.logo
                          ? Icons.business
                          : type == ImageType.signature
                              ? Icons.draw
                              : Icons.approval,
                      color: Colors.grey,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    hasImage ? 'Uploaded' : 'No image uploaded',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasImage ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            if (canEdit)
              ElevatedButton(
                onPressed: isUploading
                    ? null
                    : () => _pickAndUploadImage(context, type),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: isUploading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(hasImage ? 'Change' : 'Upload'),
              ),
          ],
        ),
      ),
    );
  }
}
