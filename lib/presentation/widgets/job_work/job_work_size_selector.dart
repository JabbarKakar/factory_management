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

  static const double _rowGap = 4;
  static const double _chipGap = 6;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subsectionStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: 11,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(AppStrings.sizes, style: AppFormFields.labelStyle(context)),
        const SizedBox(height: 10),
        Text(AppStrings.smallSize, style: subsectionStyle),
        const SizedBox(height: 8),
        ...JobWorkSizes.smallSizeRows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: _rowGap),
            child: _SizeChipRow(
              options: row,
              selected: selectedSmall,
              enabled: enabled,
              gap: _chipGap,
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
          gap: _chipGap,
          onToggle: (option, value) =>
              onToggle(option, value, JobWorkSizeCategory.large),
        ),
        if (selectedLegacy.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(AppStrings.legacySizes, style: subsectionStyle),
          const SizedBox(height: 8),
          _SizeChipWrap(
            options: selectedLegacy.toList(),
            selected: selectedLegacy,
            enabled: enabled,
            gap: _chipGap,
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
    required this.gap,
    required this.enabled,
  });

  final List<String> options;
  final Set<String> selected;
  final bool enabled;
  final double gap;
  final void Function(String option, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(width: gap),
          Expanded(
            child: _SizeChip(
              label: options[i],
              isSelected: selected.contains(options[i]),
              enabled: enabled,
              onChanged: (value) => onToggle(options[i], value),
            ),
          ),
        ],
      ],
    );
  }
}

class _SizeChipWrap extends StatelessWidget {
  const _SizeChipWrap({
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.gap,
    required this.enabled,
  });

  final List<String> options;
  final Set<String> selected;
  final bool enabled;
  final double gap;
  final void Function(String option, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 360 ? 4 : 3;
        final itemWidth =
            (constraints.maxWidth - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: options.map((option) {
            return SizedBox(
              width: itemWidth,
              child: _SizeChip(
                label: option,
                isSelected: selected.contains(option),
                enabled: enabled,
                onChanged: (value) => onToggle(option, value),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.5)
        : theme.colorScheme.outline.withValues(alpha: 0.32);
    final fillColor = isSelected
        ? theme.colorScheme.primary.withValues(alpha: 0.1)
        : theme.colorScheme.surface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => onChanged(!isSelected) : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          width: double.infinity,
          decoration: BoxDecoration(
            color: fillColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 10.5,
                  height: 1.15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
