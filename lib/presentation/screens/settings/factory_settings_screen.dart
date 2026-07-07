import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_bloc.dart';
import '../../../blocs/factory_profile/factory_profile_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../../widgets/dashboard/dashboard_surface.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class FactorySettingsScreen extends StatefulWidget {
  const FactorySettingsScreen({super.key});

  @override
  State<FactorySettingsScreen> createState() => _FactorySettingsScreenState();
}

class _FactorySettingsScreenState extends State<FactorySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _populated = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _populateForm(FactoryProfileState state) {
    final profile = state.profile;
    if (profile == null || _populated) return;
    _populated = true;
    _nameController.text = profile.name;
    _ownerNameController.text = profile.ownerName ?? '';
    _phoneController.text = profile.phone ?? '';
    _addressController.text = profile.address ?? '';
  }

  void _submit(BuildContext context, bool canEdit) {
    if (!canEdit) return;
    if (!_formKey.currentState!.validate()) return;

    context.read<FactoryProfileBloc>().add(
          FactoryProfileSaveRequested(
            name: _nameController.text,
            ownerName: _ownerNameController.text,
            phone: _phoneController.text,
            address: _addressController.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final canEdit = user?.canEditFactoryProfile ?? false;

    return BlocConsumer<FactoryProfileBloc, FactoryProfileState>(
      listenWhen: (prev, curr) =>
          prev.successMessage != curr.successMessage ||
          prev.errorMessage != curr.errorMessage,
      listener: (context, state) {
        final message = state.successMessage ?? state.errorMessage;
        if (message == null) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      },
      builder: (context, state) {
        if (state.status == FactoryProfileStatus.loading &&
            state.profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.factorySettings)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (state.status == FactoryProfileStatus.failure &&
            state.profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text(AppStrings.factorySettings)),
            body: EmptyStateView(
              icon: Icons.error_outline,
              title: AppStrings.factoryProfileLoadError,
              subtitle: state.errorMessage,
            ),
          );
        }

        _populateForm(state);
        final isSaving = state.status == FactoryProfileStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(AppStrings.factorySettings),
                Text(
                  AppStrings.factorySettingsSubtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: (Theme.of(context).appBarTheme.foregroundColor ??
                                Theme.of(context).colorScheme.onSurface)
                            .withValues(alpha: 0.78),
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            actions: [
              if (canEdit)
                TextButton(
                  onPressed: isSaving ? null : () => _submit(context, canEdit),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
            ],
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
              DashboardSurfaceCard(
                compact: true,
                borderRadius: 14,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Form(
                  key: _formKey,
                  child: JobWorkDetailSection(
                    title: 'Details',
                    icon: Icons.business_outlined,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          enabled: canEdit && !isSaving,
                          textInputAction: TextInputAction.next,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.factoryNameLabel,
                          ),
                          validator: (value) => Validators.requiredText(
                            value,
                            field: 'Factory name',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _ownerNameController,
                          enabled: canEdit && !isSaving,
                          textInputAction: TextInputAction.next,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.ownerNameLabel,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _phoneController,
                          enabled: canEdit && !isSaving,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.factoryPhone,
                          ),
                          validator: Validators.optionalPhone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          enabled: canEdit && !isSaving,
                          maxLines: 3,
                          textInputAction: TextInputAction.done,
                          style: AppFormFields.valueStyle(context),
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.factoryAddress,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
