import 'package:flutter/material.dart';

import '../../../domain/entities/employee.dart';
import 'employee_status_badge.dart';

class EmployeeListTile extends StatelessWidget {
  const EmployeeListTile({
    required this.employee,
    required this.onTap,
    super.key,
  });

  final Employee employee;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      employee.fullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  EmployeeStatusBadge(status: employee.status, compact: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                employee.employeeNumber,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: muted,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                employee.phone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: muted,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                employee.workerCategory.label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: muted,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
