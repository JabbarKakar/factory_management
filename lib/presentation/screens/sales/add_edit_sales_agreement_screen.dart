import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../blocs/sales/sales_agreement_form_bloc.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/customer.dart';
import '../../../domain/entities/sales_agreement.dart';
import '../../routes/route_paths.dart';
import '../../widgets/forms/app_form_fields.dart';
import '../../widgets/job_work/job_work_detail_section.dart';

class AddEditSalesAgreementScreen extends StatefulWidget {
  const AddEditSalesAgreementScreen({this.agreementId, super.key});

  final String? agreementId;

  @override
  State<AddEditSalesAgreementScreen> createState() =>
      _AddEditSalesAgreementScreenState();
}

class _AddEditSalesAgreementScreenState
    extends State<AddEditSalesAgreementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String? _customerId;
  bool _populated = false;
  SalesAgreement? _baseAgreement;
  List<Customer> _customers = const [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _populate(SalesAgreement agreement, List<Customer> customers) {
    if (_populated) return;
    _populated = true;
    _baseAgreement = agreement;
    _customers = customers;
    _customerId =
        agreement.customerId.isEmpty ? null : agreement.customerId;
    _notesController.text = agreement.notes ?? '';
  }

  void _submit(SalesAgreementFormState state) {
    if (!_formKey.currentState!.validate()) return;
    if (_customerId == null) return;

    final customer = _customers.firstWhere(
      (c) => c.id == _customerId,
      orElse: () => _customers.first,
    );
    final base = _baseAgreement ?? state.agreement;
    if (base == null) return;

    final agreement = base.copyWith(
      customerId: customer.id,
      customerName: customer.name,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    context
        .read<SalesAgreementFormBloc>()
        .add(SalesAgreementFormSubmitted(agreement));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.agreementId != null;

    return BlocConsumer<SalesAgreementFormBloc, SalesAgreementFormState>(
      listener: (context, state) {
        if (state.status == SalesAgreementFormStatus.saved &&
            state.agreement != null) {
          if (!isEditing) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.salesAgreementCreated),
              ),
            );
            context.go(RoutePaths.salesDetail(state.agreement!.id));
          } else {
            context.pop(true);
          }
        }
        if (state.status == SalesAgreementFormStatus.failure &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        if (state.status == SalesAgreementFormStatus.loading ||
            state.status == SalesAgreementFormStatus.initial) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                isEditing
                    ? AppStrings.editSalesAgreement
                    : AppStrings.newSalesAgreement,
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final agreement = state.agreement;
        if (agreement != null) {
          _populate(agreement, state.eligibleCustomers);
        }

        if (_customers.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                isEditing
                    ? AppStrings.editSalesAgreement
                    : AppStrings.newSalesAgreement,
              ),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppStrings.noSalesCustomers,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final isSaving = state.status == SalesAgreementFormStatus.saving;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              isEditing
                  ? AppStrings.editSalesAgreement
                  : AppStrings.newSalesAgreement,
            ),
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              children: [
                JobWorkDetailSection(
                  title: AppStrings.customerAndDates,
                  icon: Icons.person_outline,
                  child: AppFormSectionBody(
                    children: [
                      DropdownButtonFormField<String>(
                        key: ValueKey(_customerId),
                        initialValue: _customerId,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.selectCustomer,
                        ),
                        items: _customers
                            .map(
                              (customer) => DropdownMenuItem(
                                value: customer.id,
                                child: Text(
                                  customer.name,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (value) => setState(() => _customerId = value),
                        validator: (value) =>
                            value == null ? 'Select a customer' : null,
                      ),
                      AppFormFields.gap,
                      TextFormField(
                        controller: _notesController,
                        enabled: !isSaving,
                        maxLines: 3,
                        style: AppFormFields.valueStyle(context),
                        decoration: AppFormFields.decoration(
                          context,
                          label: AppStrings.notes,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: FilledButton(
                    onPressed: isSaving ? null : () => _submit(state),
                    child: isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(AppStrings.saveSalesAgreement),
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
