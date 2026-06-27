import 'package:factory_management/domain/entities/app_user.dart';
import 'package:factory_management/domain/enums/app_module_enums.dart';
import 'package:factory_management/domain/enums/factory_role_enums.dart';
import 'package:factory_management/domain/extensions/app_user_permissions.dart';
import 'package:factory_management/domain/permissions/role_permissions.dart';
import 'package:factory_management/presentation/routes/permission_route_guard.dart';
import 'package:factory_management/presentation/routes/route_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const owner = AppUser(
    id: 'owner-1',
    email: 'owner@test.com',
    name: 'Owner',
    role: 'owner',
    factoryId: 'factory-1',
  );

  const viewer = AppUser(
    id: 'viewer-1',
    email: 'viewer@test.com',
    name: 'Viewer',
    role: 'viewer',
    factoryId: 'factory-1',
  );

  const driver = AppUser(
    id: 'driver-1',
    email: 'driver@test.com',
    name: 'Driver',
    role: 'driver',
    factoryId: 'factory-1',
    employeeId: 'emp-1',
  );

  const accountant = AppUser(
    id: 'acct-1',
    email: 'acct@test.com',
    name: 'Accountant',
    role: 'accountant',
    factoryId: 'factory-1',
  );

  group('RolePermissions', () {
    test('owner can delete any module', () {
      expect(
        RolePermissions.canDelete(FactoryRole.owner, AppModule.customers),
        isTrue,
      );
    });

    test('viewer cannot mutate modules', () {
      expect(
        RolePermissions.canCreate(FactoryRole.viewer, AppModule.dashboard),
        isFalse,
      );
      expect(
        RolePermissions.canEdit(FactoryRole.viewer, AppModule.dashboard),
        isFalse,
      );
      expect(
        RolePermissions.canDelete(FactoryRole.viewer, AppModule.customers),
        isFalse,
      );
    });

    test('accountant can edit expenses but not production', () {
      expect(
        RolePermissions.canEdit(FactoryRole.accountant, AppModule.expenses),
        isTrue,
      );
      expect(
        RolePermissions.canCreate(FactoryRole.accountant, AppModule.production),
        isFalse,
      );
    });

    test('driver can edit delivery but not create', () {
      expect(
        RolePermissions.canEdit(FactoryRole.driver, AppModule.delivery),
        isTrue,
      );
      expect(
        RolePermissions.canCreate(FactoryRole.driver, AppModule.delivery),
        isFalse,
      );
      expect(
        RolePermissions.canView(FactoryRole.driver, AppModule.dashboard),
        isFalse,
      );
    });

    test('factory manager cannot access P&L', () {
      expect(
        RolePermissions.canView(FactoryRole.factoryManager, AppModule.plReport),
        isFalse,
      );
    });

    test('accountant can export P&L and customer statements', () {
      expect(
        RolePermissions.canExport(FactoryRole.accountant, AppModule.plReport),
        isTrue,
      );
      expect(
        RolePermissions.canExport(FactoryRole.accountant, AppModule.customers),
        isTrue,
      );
    });

    test('viewer cannot export reports', () {
      expect(
        RolePermissions.canExport(FactoryRole.viewer, AppModule.plReport),
        isFalse,
      );
      expect(
        RolePermissions.canExport(FactoryRole.viewer, AppModule.customers),
        isFalse,
      );
    });

    test('sales staff can export sales invoices but not P&L', () {
      expect(
        RolePermissions.canExport(FactoryRole.salesStaff, AppModule.sales),
        isTrue,
      );
      expect(
        RolePermissions.canExport(FactoryRole.salesStaff, AppModule.plReport),
        isFalse,
      );
    });
  });

  group('AppUserPermissions', () {
    test('parses factory role and employee link', () {
      expect(driver.factoryRole, FactoryRole.driver);
      expect(driver.employeeId, 'emp-1');
      expect(owner.canManageTeam, isTrue);
      expect(viewer.canManageTeam, isFalse);
    });
  });

  group('PermissionRouteGuard', () {
    test('viewer cannot open production add route', () {
      expect(
        PermissionRouteGuard.canAccessLocation(viewer, RoutePaths.productionAdd),
        isFalse,
      );
    });

    test('driver home is deliveries', () {
      expect(
        PermissionRouteGuard.homeLocationFor(driver),
        RoutePaths.deliveries,
      );
    });

    test('owner can open team settings', () {
      expect(
        PermissionRouteGuard.canAccessLocation(owner, RoutePaths.team),
        isTrue,
      );
    });

    test('viewer cannot open team settings', () {
      expect(
        PermissionRouteGuard.canAccessLocation(viewer, RoutePaths.team),
        isFalse,
      );
    });

    test('accountant cannot open production list', () {
      expect(
        PermissionRouteGuard.canAccessLocation(accountant, RoutePaths.production),
        isFalse,
      );
    });

    test('driver cannot schedule new delivery', () {
      expect(
        PermissionRouteGuard.canAccessLocation(driver, RoutePaths.deliveriesAdd),
        isFalse,
      );
    });
  });
}
