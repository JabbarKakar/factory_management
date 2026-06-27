import '../../domain/entities/app_user.dart';
import '../../domain/enums/app_module_enums.dart';
import '../../domain/extensions/app_user_permissions.dart';
import 'route_paths.dart';

class PermissionRouteGuard {
  const PermissionRouteGuard._();

  static bool canAccessLocation(AppUser user, String location) {
    if (location == RoutePaths.reportsHub) {
      return user.canView(AppModule.plReport) ||
          user.canExport(AppModule.customers);
    }

    if (location.startsWith('${RoutePaths.customers}/statement/')) {
      return user.canView(AppModule.customers);
    }

    final module = moduleForLocation(location);
    if (module == null) return true;

    if (!user.canView(module)) return false;

    if (_isCreateRoute(location) && !user.canCreate(module)) {
      return false;
    }

    if (_isEditRoute(location) && !user.canEdit(module)) {
      return false;
    }

    if (_isDeleteRoute(location) && !user.canDelete(module)) {
      return false;
    }

    return true;
  }

  static String homeLocationFor(AppUser user) {
    const candidates = [
      (RoutePaths.dashboard, AppModule.dashboard),
      (RoutePaths.deliveries, AppModule.delivery),
      (RoutePaths.jobWork, AppModule.jobWork),
      (RoutePaths.customers, AppModule.customers),
      (RoutePaths.sales, AppModule.sales),
      (RoutePaths.more, AppModule.dashboard),
    ];

    for (final (path, module) in candidates) {
      if (user.canView(module)) return path;
    }

    return RoutePaths.accessDenied;
  }

  static AppModule? moduleForLocation(String location) {
    if (location.startsWith(RoutePaths.dashboard)) {
      return AppModule.dashboard;
    }
    if (location.startsWith(RoutePaths.jobWork)) {
      return AppModule.jobWork;
    }
    if (location.startsWith(RoutePaths.customers)) {
      return AppModule.customers;
    }
    if (location.startsWith('${RoutePaths.customers}/statement/')) {
      return AppModule.customers;
    }
    if (location.startsWith(RoutePaths.sales)) {
      return AppModule.sales;
    }
    if (location.startsWith(RoutePaths.expenses)) {
      return AppModule.expenses;
    }
    if (location.startsWith(RoutePaths.plReport)) {
      return AppModule.plReport;
    }
    if (location.startsWith(RoutePaths.reportsHub)) {
      return AppModule.plReport;
    }
    if (location.startsWith(RoutePaths.suppliers)) {
      return AppModule.suppliers;
    }
    if (location.startsWith(RoutePaths.rawMaterials)) {
      return AppModule.rawMaterials;
    }
    if (location.startsWith(RoutePaths.production)) {
      return AppModule.production;
    }
    if (location.startsWith(RoutePaths.finishedGoods)) {
      return AppModule.finishedGoods;
    }
    if (location.startsWith(RoutePaths.employees) ||
        location.startsWith(RoutePaths.attendance)) {
      return AppModule.labour;
    }
    if (location.startsWith(RoutePaths.equipment)) {
      return AppModule.equipment;
    }
    if (location.startsWith(RoutePaths.qualityChecks)) {
      return AppModule.qualityControl;
    }
    if (location.startsWith(RoutePaths.deliveries)) {
      return AppModule.delivery;
    }
    if (location.startsWith(RoutePaths.notifications)) {
      return AppModule.notifications;
    }
    if (location.startsWith(RoutePaths.team)) {
      return AppModule.team;
    }
    if (location.startsWith(RoutePaths.accessDenied)) {
      return null;
    }
    if (location.startsWith(RoutePaths.more)) {
      return null;
    }
    return null;
  }

  static bool _isCreateRoute(String location) =>
      location.endsWith('/add') || location.contains('/record-');

  static bool _isEditRoute(String location) =>
      location.contains('/edit') ||
      location.contains('/payment') ||
      location.contains('/adjust') ||
      location.contains('/confirm');

  static bool _isDeleteRoute(String location) => false;
}
