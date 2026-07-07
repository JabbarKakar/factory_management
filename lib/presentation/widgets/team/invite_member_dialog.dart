import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../domain/enums/factory_role_enums.dart';
import '../forms/app_form_fields.dart';
import 'factory_role_badge.dart';

/// Result returned by [InviteMemberDialog] when the owner confirms.
typedef InviteMemberRequest = ({String email, FactoryRole role});

/// Owner-facing dialog to create a team invite (email + role).
class InviteMemberDialog extends StatefulWidget {
  const InviteMemberDialog({super.key});

  static Future<InviteMemberRequest?> show(BuildContext context) {
    return showDialog<InviteMemberRequest>(
      context: context,
      builder: (_) => const InviteMemberDialog(),
    );
  }

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  static final List<FactoryRole> _assignableRoles = FactoryRole.values
      .where((role) => role != FactoryRole.owner)
      .toList();

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  FactoryRole _role = FactoryRole.factoryManager;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      (email: _emailController.text.trim().toLowerCase(), role: _role),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text(AppStrings.inviteMember),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.inviteMemberSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              style: AppFormFields.valueStyle(context),
              decoration: AppFormFields.decoration(
                context,
                label: AppStrings.memberEmail,
              ),
              validator: Validators.email,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FactoryRole>(
              initialValue: _role,
              isExpanded: true,
              decoration: AppFormFields.decoration(
                context,
                label: AppStrings.role,
              ),
              style: AppFormFields.valueStyle(context),
              items: _assignableRoles
                  .map(
                    (role) => DropdownMenuItem(
                      value: role,
                      child: Text(
                        role.label,
                        style: TextStyle(
                          color: factoryRoleAccent(role),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _role = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text(AppStrings.sendInvite),
        ),
      ],
    );
  }
}
