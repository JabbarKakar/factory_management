import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/enums/app_module_enums.dart';
import '../../domain/enums/factory_role_enums.dart';
import '../../domain/extensions/app_user_permissions.dart';

AppUser? readCurrentUser(BuildContext context) {
  final state = context.read<AuthBloc>().state;
  return state is AuthAuthenticated ? state.user : null;
}

AppUser? watchCurrentUser(BuildContext context) {
  final state = context.watch<AuthBloc>().state;
  return state is AuthAuthenticated ? state.user : null;
}

extension UserPermissionContext on BuildContext {
  AppUser? get currentUser => readCurrentUser(this);

  bool userCanView(AppModule module) => currentUser?.canView(module) ?? false;

  bool userCanCreate(AppModule module) => currentUser?.canCreate(module) ?? false;

  bool userCanEdit(AppModule module) => currentUser?.canEdit(module) ?? false;

  bool userCanDelete(AppModule module) => currentUser?.canDelete(module) ?? false;

  bool userCanExport(AppModule module) => currentUser?.canExport(module) ?? false;
}

String? readDriverEmployeeId(BuildContext context) {
  final user = readCurrentUser(context);
  if (user == null || user.factoryRole != FactoryRole.driver) {
    return null;
  }
  return user.employeeId;
}
