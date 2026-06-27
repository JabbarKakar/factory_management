import '../../domain/entities/app_user.dart';
import '../../domain/enums/app_module_enums.dart';
import '../../domain/enums/factory_role_enums.dart';
import '../../domain/permissions/role_permissions.dart';

extension AppUserPermissions on AppUser {
  FactoryRole get factoryRole => FactoryRole.fromString(role);

  bool can(AppModule module, PermissionAction action) =>
      RolePermissions.can(factoryRole, module, action);

  bool canView(AppModule module) => can(module, PermissionAction.view);

  bool canCreate(AppModule module) => can(module, PermissionAction.create);

  bool canEdit(AppModule module) => can(module, PermissionAction.edit);

  bool canDelete(AppModule module) => can(module, PermissionAction.delete);

  bool canExport(AppModule module) => can(module, PermissionAction.export);

  bool get canManageTeam => factoryRole == FactoryRole.owner;
}
