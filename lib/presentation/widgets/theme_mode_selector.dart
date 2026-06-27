import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/theme/theme_cubit.dart';
import '../../core/constants/app_strings.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  static const double _iconOnlyBreakpoint = 340;

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final iconOnly = constraints.maxWidth < _iconOnlyBreakpoint;

        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.symmetric(
                horizontal: iconOnly ? 10 : 6,
                vertical: 10,
              ),
              textStyle: theme.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            segments: [
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_outlined, size: 18),
                label: iconOnly
                    ? null
                    : const Text(
                        AppStrings.themeLight,
                        maxLines: 1,
                        softWrap: false,
                      ),
                tooltip: AppStrings.themeLight,
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_outlined, size: 18),
                label: iconOnly
                    ? null
                    : const Text(
                        AppStrings.themeDark,
                        maxLines: 1,
                        softWrap: false,
                      ),
                tooltip: AppStrings.themeDark,
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_outlined, size: 18),
                label: iconOnly
                    ? null
                    : const Text(
                        AppStrings.themeSystem,
                        maxLines: 1,
                        softWrap: false,
                      ),
                tooltip: AppStrings.themeSystem,
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selection) {
              context.read<ThemeCubit>().setThemeMode(selection.first);
            },
          ),
        );
      },
    );
  }
}
