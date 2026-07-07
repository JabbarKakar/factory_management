import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/app_user.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/enums/factory_role_enums.dart';
import '../../../domain/enums/user_enums.dart';
import '../../../domain/extensions/app_user_permissions.dart';
import '../forms/app_form_fields.dart';
import 'factory_role_badge.dart';

class TeamMemberTile extends StatelessWidget {
  const TeamMemberTile({
    required this.member,
    required this.employees,
    required this.isSelf,
    required this.enabled,
    required this.onRoleChanged,
    required this.onEmployeeLinkChanged,
    this.onStatusToggle,
    super.key,
  });

  final AppUser member;
  final List<Employee> employees;
  final bool isSelf;
  final bool enabled;
  final ValueChanged<FactoryRole> onRoleChanged;
  final ValueChanged<String?> onEmployeeLinkChanged;

  /// Owner-only toggle to disable/enable this member. Null for self.
  final VoidCallback? onStatusToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;
    final outline =
        theme.colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.45);
    final role = member.factoryRole;
    final isDisabled = member.status == UserAccountStatus.disabled;
    final accent =
        isDisabled ? theme.colorScheme.outline : factoryRoleAccent(role);
    final isDriver = role == FactoryRole.driver;
    const cardShape = BorderRadius.only(
      topRight: Radius.circular(14),
      bottomRight: Radius.circular(14),
    );
    final initial = member.name.isNotEmpty
        ? member.name[0].toUpperCase()
        : '?';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: cardShape,
            border: Border.all(color: outline),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accent),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: accent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          member.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                            height: 1.2,
                                          ),
                                        ),
                                      ),
                                      if (isDisabled)
                                        _StatusChip(
                                          label: AppStrings.disabledLabel,
                                          color: theme.colorScheme.error,
                                        ),
                                      if (isSelf)
                                        _StatusChip(
                                          label: 'You',
                                          color: theme.colorScheme.primary,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    member.email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: muted,
                                      fontSize: 11,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FactoryRoleBadge(role: role, compact: true),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<FactoryRole>(
                          key: ValueKey('${member.id}_${role.name}'),
                          initialValue: role,
                          isExpanded: true,
                          decoration: AppFormFields.decoration(
                            context,
                            label: AppStrings.role,
                          ),
                          style: AppFormFields.valueStyle(context),
                          items: FactoryRole.values
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      color: factoryRoleAccent(item),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: !enabled || isSelf
                              ? null
                              : (value) {
                                  if (value != null) onRoleChanged(value);
                                },
                        ),
                        if (isDriver) ...[
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String?>(
                            key: ValueKey(
                              '${member.id}_employee_${member.employeeId}',
                            ),
                            initialValue: member.employeeId,
                            isExpanded: true,
                            decoration: AppFormFields.decoration(
                              context,
                              label: AppStrings.linkedEmployee,
                            ),
                            style: AppFormFields.valueStyle(context),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(AppStrings.noEmployeeLinked),
                              ),
                              ...employees.map(
                                (employee) => DropdownMenuItem<String?>(
                                  value: employee.id,
                                  child: Text(employee.fullName),
                                ),
                              ),
                            ],
                            onChanged: !enabled || isSelf
                                ? null
                                : onEmployeeLinkChanged,
                          ),
                          if (member.employeeId == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                AppStrings.driverEmployeeLinkHint,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: muted,
                                  fontSize: 10,
                                  height: 1.3,
                                ),
                              ),
                            ),
                        ],
                        if (!isSelf && onStatusToggle != null) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: enabled ? onStatusToggle : null,
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                foregroundColor: isDisabled
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.error,
                              ),
                              icon: Icon(
                                isDisabled
                                    ? Icons.lock_open_outlined
                                    : Icons.block_outlined,
                                size: 16,
                              ),
                              label: Text(
                                isDisabled
                                    ? AppStrings.enableMember
                                    : AppStrings.disableMember,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
      ),
    );
  }
}
