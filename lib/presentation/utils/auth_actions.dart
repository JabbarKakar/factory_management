import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../core/constants/app_strings.dart';
import '../widgets/dialogs/app_confirm_dialog.dart';

abstract final class AuthActions {
  static Future<void> confirmLogout(BuildContext context) async {
    final confirmed = await AppConfirmDialog.show(
      context,
      title: AppStrings.logoutTitle,
      message: AppStrings.logoutMessage,
      confirmLabel: AppStrings.logout,
      cancelLabel: AppStrings.cancel,
      destructive: true,
    );

    if (!context.mounted || !confirmed) return;

    context.read<AuthBloc>().add(const AuthLogoutRequested());
  }
}
