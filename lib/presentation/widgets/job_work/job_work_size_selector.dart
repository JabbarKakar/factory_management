import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/constants/job_work_sizes.dart';
import '../forms/app_form_fields.dart';

enum JobWorkSizeCategory { small, large, legacy }

/// Multi-select small/large size chips for job work cutting specification.
class JobWorkSizeSelector extends StatelessWidget {
  const JobWorkSizeSelector({
    required this.selectedSmall,
    required this.selectedLarge,
    required this.selectedLegacy,
    required this.onToggle,
    this.enabled = true,
    super.key,
  });

  final Set<String> selectedSmall;
  final Set<String> selectedLarge;
  final Set<String> selectedLegacy;
  final void Function(
    String option,
    bool isSelected,
    JobWorkSizeCategory category,
  ) onToggle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subsectionStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 11,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppStrings.sizes, style: AppFormFields.labelStyle(context)),
        const SizedBox(height: 10),
        Text(AppStrings.smallSize, style: subsectionStyle),
        const SizedBox(height: 8),
        ...JobWorkSizes.smallSizeRows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _SizeChipRow(
              options: row,
              selected: selectedSmall,
              enabled: enabled,
              onToggle: (option, value) =>
                  onToggle(option, value, JobWorkSizeCategory.small),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(AppStrings.largeSize, style: subsectionStyle),
        const SizedBox(height: 8),
        _SizeChipRow(
          options: JobWorkSizes.largeSizes,
          selected: selectedLarge,
          enabled: enabled,
          onToggle: (option, value) =>
              onToggle(option, value, JobWorkSizeCategory.large),
        ),
        if (selectedLegacy.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(AppStrings.legacySizes, style: subsectionStyle),
          const SizedBox(height: 8),
          _SizeChipRow(
            options: selectedLegacy.toList(),
            selected: selectedLegacy,
            enabled: enabled,
            onToggle: (option, value) =>
                onToggle(option, value, JobWorkSizeCategory.legacy),
          ),
        ],
      ],
    );
  }
}

class _SizeChipRow extends StatelessWidget {
  const _SizeChipRow({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.enabled,
  });

  final List<String> options;
  final Set<String> selected;
  final bool enabled;
  final void Function(String option, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: options.map((option) {
        final isSelected = selected.contains(option);
        return FilterChip(
          label: Text(
            option,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          selected: isSelected,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.45)
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
          onSelected: enabled ? (value) => onToggle(option, value) : null,
        );
      }).toList(),
    );
  }
}
