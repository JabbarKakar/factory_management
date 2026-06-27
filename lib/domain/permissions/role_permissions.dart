import '../enums/app_module_enums.dart';
import '../enums/factory_role_enums.dart';

class RolePermissions {
  const RolePermissions._();

  static bool can(
    FactoryRole role,
    AppModule module,
    PermissionAction action,
  ) {
    if (role == FactoryRole.owner) return true;

    if (action == PermissionAction.delete) {
      return false;
    }

    final grants = _grantsFor(role);
    if (!grants.contains(module)) return false;

    if (action == PermissionAction.view) {
      return true;
    }

    if (action == PermissionAction.export) {
      return _canExport(role, module);
    }

    return _canMutate(role, module, action);
  }

  static bool canView(FactoryRole role, AppModule module) =>
      can(role, module, PermissionAction.view);

  static bool canCreate(FactoryRole role, AppModule module) =>
      can(role, module, PermissionAction.create);

  static bool canEdit(FactoryRole role, AppModule module) =>
      can(role, module, PermissionAction.edit);

  static bool canDelete(FactoryRole role, AppModule module) =>
      can(role, module, PermissionAction.delete);

  static bool canExport(FactoryRole role, AppModule module) =>
      can(role, module, PermissionAction.export);

  static Set<AppModule> modulesFor(FactoryRole role) => _grantsFor(role);

  static Set<AppModule> _grantsFor(FactoryRole role) {
    return switch (role) {
      FactoryRole.factoryManager => {
          AppModule.dashboard,
          AppModule.jobWork,
          AppModule.customers,
          AppModule.sales,
          AppModule.suppliers,
          AppModule.rawMaterials,
          AppModule.production,
          AppModule.finishedGoods,
          AppModule.labour,
          AppModule.equipment,
          AppModule.qualityControl,
          AppModule.delivery,
          AppModule.notifications,
        },
      FactoryRole.accountant => {
          AppModule.dashboard,
          AppModule.customers,
          AppModule.sales,
          AppModule.jobWork,
          AppModule.expenses,
          AppModule.plReport,
          AppModule.suppliers,
          AppModule.notifications,
        },
      FactoryRole.salesStaff => {
          AppModule.dashboard,
          AppModule.customers,
          AppModule.sales,
          AppModule.delivery,
          AppModule.notifications,
        },
      FactoryRole.jobWorkClerk => {
          AppModule.dashboard,
          AppModule.jobWork,
          AppModule.customers,
          AppModule.qualityControl,
          AppModule.notifications,
        },
      FactoryRole.supervisor => {
          AppModule.dashboard,
          AppModule.jobWork,
          AppModule.customers,
          AppModule.sales,
          AppModule.production,
          AppModule.labour,
          AppModule.equipment,
          AppModule.qualityControl,
          AppModule.delivery,
          AppModule.notifications,
        },
      FactoryRole.storeKeeper => {
          AppModule.dashboard,
          AppModule.rawMaterials,
          AppModule.finishedGoods,
          AppModule.suppliers,
          AppModule.notifications,
        },
      FactoryRole.driver => {
          AppModule.delivery,
          AppModule.notifications,
        },
      FactoryRole.viewer => {
          AppModule.dashboard,
          AppModule.notifications,
        },
      FactoryRole.owner => AppModule.values.toSet(),
    };
  }

  static bool _canMutate(
    FactoryRole role,
    AppModule module,
    PermissionAction action,
  ) {
    return switch (role) {
      FactoryRole.factoryManager => switch (module) {
          AppModule.expenses || AppModule.plReport || AppModule.team => false,
          _ => true,
        },
      FactoryRole.accountant => switch (module) {
          AppModule.expenses ||
          AppModule.plReport ||
          AppModule.customers ||
          AppModule.sales ||
          AppModule.jobWork =>
            true,
          _ => false,
        },
      FactoryRole.salesStaff => switch (module) {
          AppModule.customers || AppModule.sales || AppModule.delivery => true,
          _ => false,
        },
      FactoryRole.jobWorkClerk => switch (module) {
          AppModule.jobWork ||
          AppModule.customers ||
          AppModule.qualityControl =>
            true,
          _ => false,
        },
      FactoryRole.supervisor => switch (module) {
          AppModule.production ||
          AppModule.jobWork ||
          AppModule.labour ||
          AppModule.qualityControl =>
            action == PermissionAction.create || action == PermissionAction.edit,
          _ => false,
        },
      FactoryRole.storeKeeper => switch (module) {
          AppModule.rawMaterials || AppModule.finishedGoods => true,
          _ => false,
        },
      FactoryRole.driver => module == AppModule.delivery &&
          action == PermissionAction.edit,
      FactoryRole.viewer => false,
      FactoryRole.owner => true,
    };
  }

  static bool _canExport(FactoryRole role, AppModule module) {
    return switch (role) {
      FactoryRole.accountant => switch (module) {
          AppModule.customers ||
          AppModule.sales ||
          AppModule.jobWork ||
          AppModule.plReport ||
          AppModule.expenses =>
            true,
          _ => false,
        },
      FactoryRole.factoryManager => switch (module) {
          AppModule.customers || AppModule.sales || AppModule.jobWork => true,
          _ => false,
        },
      FactoryRole.salesStaff => switch (module) {
          AppModule.customers || AppModule.sales => true,
          _ => false,
        },
      FactoryRole.jobWorkClerk => switch (module) {
          AppModule.customers || AppModule.jobWork => true,
          _ => false,
        },
      FactoryRole.supervisor ||
      FactoryRole.storeKeeper ||
      FactoryRole.driver ||
      FactoryRole.viewer =>
        false,
      FactoryRole.owner => true,
    };
  }
}
