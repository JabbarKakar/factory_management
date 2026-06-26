import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/theme_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._repository) : super(ThemeMode.system) {
    _loadSavedTheme();
  }

  final ThemeRepository _repository;

  Future<void> _loadSavedTheme() async {
    final saved = await _repository.getThemeMode();
    emit(saved);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == state) return;
    await _repository.saveThemeMode(mode);
    emit(mode);
  }
}
