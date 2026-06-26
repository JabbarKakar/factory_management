import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/theme/theme_cubit.dart';
import '../../core/constants/app_strings.dart';

class ThemeModeSelector extends StatelessWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.light,
            label: Text(AppStrings.themeLight),
            icon: Icon(Icons.light_mode_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            label: Text(AppStrings.themeDark),
            icon: Icon(Icons.dark_mode_outlined),
          ),
          ButtonSegment(
            value: ThemeMode.system,
            label: Text(AppStrings.themeSystem),
            icon: Icon(Icons.brightness_auto_outlined),
          ),
        ],
        selected: {themeMode},
        onSelectionChanged: (selection) {
          context.read<ThemeCubit>().setThemeMode(selection.first);
        },
      ),
    );
  }
}
