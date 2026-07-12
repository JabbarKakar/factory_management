import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/job_work/job_work_collection_form_bloc.dart';
import '../../blocs/job_work/job_work_form_bloc.dart';
import '../../blocs/job_work/job_work_invoice_bloc.dart';
import '../../blocs/job_work/job_work_list_bloc.dart';
import '../../blocs/job_work/job_work_load_detail_bloc.dart';
import '../../blocs/job_work/job_work_load_form_bloc.dart';
import '../../blocs/job_work/job_work_output_bloc.dart';
import '../../blocs/customer/customer_form_bloc.dart';
import '../../blocs/customer/customer_list_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/expense/expense_form_bloc.dart';
import '../../blocs/expense/expense_list_bloc.dart';
import '../../blocs/pl/pl_report_bloc.dart';
import '../../blocs/finished_goods/finished_goods_detail_bloc.dart';
import '../../blocs/finished_goods/finished_goods_list_bloc.dart';
import '../../blocs/finished_goods/inventory_adjustment_bloc.dart';
import '../../blocs/delivery/delivery_confirm_bloc.dart';
import '../../blocs/delivery/delivery_detail_bloc.dart';
import '../../blocs/delivery/delivery_form_bloc.dart';
import '../../blocs/delivery/delivery_list_bloc.dart';
import '../../blocs/equipment/equipment_detail_bloc.dart';
import '../../blocs/equipment/equipment_form_bloc.dart';
import '../../blocs/equipment/equipment_list_bloc.dart';
import '../../blocs/equipment/maintenance_form_bloc.dart';
import '../../blocs/quality/qc_detail_bloc.dart';
import '../../blocs/quality/qc_form_bloc.dart';
import '../../blocs/quality/qc_list_bloc.dart';
import '../../blocs/labour/daily_attendance_bloc.dart';
import '../../blocs/labour/employee_detail_bloc.dart';
import '../../blocs/labour/employee_form_bloc.dart';
import '../../blocs/labour/employee_list_bloc.dart';
import '../../blocs/production/production_detail_bloc.dart';
import '../../blocs/production/production_form_bloc.dart';
import '../../blocs/production/production_list_bloc.dart';
import '../../blocs/raw_material/raw_material_adjustment_bloc.dart';
import '../../blocs/raw_material/raw_material_detail_bloc.dart';
import '../../blocs/raw_material/raw_material_list_bloc.dart';
import '../../blocs/raw_material/stock_movement_bloc.dart';
import '../../blocs/factory_profile/factory_profile_bloc.dart';
import '../../blocs/team/team_bloc.dart';
import '../../blocs/supplier/supplier_form_bloc.dart';
import '../../blocs/supplier/supplier_list_bloc.dart';
import '../../blocs/sales/sales_invoice_bloc.dart';
import '../../blocs/sales/sales_order_form_bloc.dart';
import '../../blocs/sales/sales_order_list_bloc.dart';
import '../../core/di/injection.dart';
import '../../domain/extensions/app_user_tenancy.dart';
import '../../domain/enums/delivery_enums.dart';
import '../../domain/enums/equipment_enums.dart';
import '../../domain/enums/quality_enums.dart';
import '../../domain/enums/inventory_enums.dart';
import '../../domain/enums/production_enums.dart';
import '../../domain/enums/raw_material_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/notification_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/accept_invite_screen.dart';
import '../screens/customers/customer_statement_screen.dart';
import '../screens/customers/add_edit_customer_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/job_work/add_edit_job_work_screen.dart';
import '../screens/job_work/add_job_work_load_screen.dart';
import '../screens/job_work/collect_material_screen.dart';
import '../screens/job_work/job_work_collection_slip_screen.dart';
import '../screens/job_work/job_work_detail_screen.dart';
import '../screens/job_work/job_work_invoice_screen.dart';
import '../screens/job_work/job_work_list_screen.dart';
import '../screens/job_work/job_work_load_detail_screen.dart';
import '../screens/job_work/record_job_work_output_screen.dart';
import '../screens/job_work/record_payment_screen.dart';
import '../screens/job_work/edit_job_work_invoice_screen.dart';
import '../screens/sales/edit_sales_invoice_screen.dart';
import '../screens/sales/record_sales_payment_screen.dart';
import '../screens/raw_materials/record_raw_material_adjustment_screen.dart';
import '../screens/raw_materials/record_raw_material_correction_screen.dart';
import '../screens/finished_goods/record_inventory_correction_screen.dart';
import '../screens/sales/add_edit_sales_order_screen.dart';
import '../screens/sales/sales_invoice_screen.dart';
import '../screens/sales/sales_order_detail_screen.dart';
import '../screens/sales/sales_order_list_screen.dart';
import '../screens/expenses/add_edit_expense_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/reports/pl_report_screen.dart';
import '../screens/reports/expense_summary_screen.dart';
import '../screens/reports/reports_hub_screen.dart';
import '../screens/raw_materials/raw_material_detail_screen.dart';
import '../screens/raw_materials/raw_materials_screen.dart';
import '../screens/raw_materials/record_stock_movement_screen.dart';
import '../screens/finished_goods/finished_good_detail_screen.dart';
import '../screens/finished_goods/finished_goods_screen.dart';
import '../screens/finished_goods/record_inventory_adjustment_screen.dart';
import '../screens/delivery/confirm_delivery_screen.dart';
import '../screens/delivery/create_delivery_screen.dart';
import '../screens/delivery/deliveries_screen.dart';
import '../screens/delivery/delivery_challan_screen.dart';
import '../screens/delivery/delivery_detail_screen.dart';
import '../screens/equipment/add_edit_equipment_screen.dart';
import '../screens/equipment/equipment_detail_screen.dart';
import '../screens/equipment/equipment_screen.dart';
import '../screens/equipment/record_maintenance_screen.dart';
import '../screens/quality/qc_detail_screen.dart';
import '../screens/quality/quality_checks_screen.dart';
import '../screens/quality/record_qc_screen.dart';
import '../screens/labour/add_edit_employee_screen.dart';
import '../screens/labour/daily_attendance_screen.dart';
import '../screens/labour/employee_detail_screen.dart';
import '../screens/labour/employees_screen.dart';
import '../screens/production/add_production_batch_screen.dart';
import '../screens/production/production_batch_detail_screen.dart';
import '../screens/production/production_batches_screen.dart';
import '../screens/suppliers/add_edit_supplier_screen.dart';
import '../screens/suppliers/supplier_detail_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/access_denied_screen.dart';
import '../screens/account_disabled_screen.dart';
import '../screens/settings/team_screen.dart';
import '../screens/settings/onboarding_screen.dart';
import '../screens/settings/factory_settings_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/notifications/notification_center_screen.dart';
import '../screens/shell/main_shell.dart';
import '../utils/auth_context.dart';
import '../utils/user_permissions_context.dart';
import '../../core/utils/date_keys.dart';
import 'go_router_refresh_stream.dart';
import 'permission_route_guard.dart';
import 'route_paths.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AuthBloc authBloc) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isAuthenticated = authState is AuthAuthenticated;
      final isBootstrapping =
          authState is AuthInitial || authState is AuthLoading;
      final isSplash = state.matchedLocation == RoutePaths.splash;
      final isAuthRoute = state.matchedLocation == RoutePaths.login ||
          state.matchedLocation == RoutePaths.signUp ||
          state.matchedLocation == RoutePaths.forgotPassword ||
          state.matchedLocation.startsWith(RoutePaths.acceptInvite);

      final isOnboardingRoute = state.matchedLocation == RoutePaths.onboarding;

      if (isSplash) {
        return null;
      }

      if (isBootstrapping) {
        return null;
      }

      if (!isAuthenticated && !isAuthRoute) {
        return RoutePaths.login;
      }

      final isAccountDisabledRoute =
          state.matchedLocation == RoutePaths.accountDisabled;

      // A member disabled by the owner keeps an Auth session but must be locked
      // out of all app data (rules already deny it). Route them to a dead-end.
      if (isAuthenticated) {
        final user = authState.user;
        if (!user.isActive) {
          return isAccountDisabledRoute ? null : RoutePaths.accountDisabled;
        }
      }

      if (isAccountDisabledRoute) {
        // Active (or signed-out) users have no business here.
        if (isAuthenticated) {
          final user = authState.user;
          return user.needsOnboarding
              ? RoutePaths.onboarding
              : PermissionRouteGuard.homeLocationFor(user);
        }
        return RoutePaths.login;
      }

      if (isAuthenticated && isAuthRoute) {
        final user = authState.user;
        if (user.needsOnboarding) {
          return RoutePaths.onboarding;
        }
        return PermissionRouteGuard.homeLocationFor(user);
      }

      if (isAuthenticated) {
        final user = authState.user;
        final location = state.matchedLocation;

        if (user.needsOnboarding) {
          if (!isOnboardingRoute) {
            return RoutePaths.onboarding;
          }
          return null;
        }

        if (isOnboardingRoute) {
          return PermissionRouteGuard.homeLocationFor(user);
        }

        if (location != RoutePaths.accessDenied &&
            !PermissionRouteGuard.canAccessLocation(user, location)) {
          return RoutePaths.accessDenied;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: RoutePaths.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RoutePaths.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: RoutePaths.signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: RoutePaths.acceptInvite,
        builder: (context, state) => AcceptInviteScreen(
          inviteId: state.uri.queryParameters['id'],
        ),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RoutePaths.accessDenied,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccessDeniedScreen(),
      ),
      GoRoute(
        path: RoutePaths.accountDisabled,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const AccountDisabledScreen(),
      ),
      GoRoute(
        path: RoutePaths.team,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          return BlocProvider(
            create: (context) {
              final bloc = getIt<TeamBloc>();
              final authState = authBloc.state;
              if (authState is AuthAuthenticated) {
                bloc.add(
                  TeamWatchStarted(
                    factoryId: authState.user.factoryId,
                    currentUserId: authState.user.id,
                  ),
                );
              }
              return bloc;
            },
            child: const TeamScreen(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.factorySettings,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final factoryId = readFactoryId(context);
          return BlocProvider(
            create: (_) {
              final bloc = getIt<FactoryProfileBloc>();
              if (factoryId != null) {
                bloc.add(FactoryProfileWatchStarted(factoryId));
              }
              return bloc;
            },
            child: const FactorySettingsScreen(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.notifications,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final filterName = state.uri.queryParameters['filter'];
          final initialFilter = filterName == null
              ? NotificationFilter.all
              : NotificationFilter.values.firstWhere(
                  (filter) => filter.name == filterName,
                  orElse: () => NotificationFilter.all,
                );
          return NotificationCenterScreen(initialFilter: initialFilter);
        },
      ),
      GoRoute(
        path: RoutePaths.expenses,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          return BlocProvider(
            create: (context) {
              final bloc = getIt<ExpenseListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(ExpenseListWatchStarted(factoryId));
              }
              return bloc;
            },
            child: const ExpensesScreen(),
          );
        },
        routes: [
          GoRoute(
            path: 'add',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final supplierId = state.uri.queryParameters['supplierId'];
              final payeeName = state.uri.queryParameters['payee'];
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<ExpenseFormBloc>();
                  final factoryId = readFactoryId(context);
                  if (factoryId != null) {
                    bloc.add(ExpenseFormInitialized(factoryId: factoryId));
                  }
                  return bloc;
                },
                child: AddEditExpenseScreen(
                  initialSupplierId: supplierId,
                  initialPayeeName: payeeName,
                ),
              );
            },
          ),
          GoRoute(
            path: ':expenseId/edit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final expenseId = state.pathParameters['expenseId']!;
              return BlocProvider(
                create: (_) => getIt<ExpenseFormBloc>()
                  ..add(ExpenseFormLoadRequested(expenseId)),
                child: AddEditExpenseScreen(expenseId: expenseId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.plReport,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage<void>(
            key: state.pageKey,
            child: BlocProvider(
              create: (context) {
                final bloc = getIt<PlReportBloc>();
                final factoryId = readFactoryId(context);
                if (factoryId != null) {
                  bloc.add(PlReportWatchStarted(factoryId));
                }
                return bloc;
              },
              child: const PlReportScreen(),
            ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.reportsHub,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage<void>(
            key: state.pageKey,
            child: const ReportsHubScreen(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.expenseSummary,
        parentNavigatorKey: rootNavigatorKey,
        pageBuilder: (context, state) {
          return MaterialPage<void>(
            key: state.pageKey,
            child: const ExpenseSummaryScreen(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.suppliers,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          return BlocProvider(
            create: (context) {
              final bloc = getIt<SupplierListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(SupplierListWatchStarted(factoryId));
              }
              return bloc;
            },
            child: const SuppliersScreen(),
          );
        },
        routes: [
          GoRoute(
            path: 'add',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<SupplierFormBloc>();
                  final factoryId = readFactoryId(context);
                  if (factoryId != null) {
                    bloc.add(SupplierFormInitialized(factoryId: factoryId));
                  }
                  return bloc;
                },
                child: const AddEditSupplierScreen(),
              );
            },
          ),
          GoRoute(
            path: ':supplierId',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final supplierId = state.pathParameters['supplierId']!;
              return BlocProvider(
                create: (_) => getIt<SupplierFormBloc>()
                  ..add(SupplierFormLoadRequested(supplierId)),
                child: SupplierDetailScreen(supplierId: supplierId),
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final supplierId = state.pathParameters['supplierId']!;
                  return BlocProvider(
                    create: (_) => getIt<SupplierFormBloc>()
                      ..add(SupplierFormLoadRequested(supplierId)),
                    child: AddEditSupplierScreen(supplierId: supplierId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.rawMaterials,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final filterName = state.uri.queryParameters['filter'];
          final initialFilter = filterName == null
              ? null
              : RawMaterialListFilter.values.firstWhere(
                  (filter) => filter.name == filterName,
                  orElse: () => RawMaterialListFilter.all,
                );

          return BlocProvider(
            create: (context) {
              final bloc = getIt<RawMaterialListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(RawMaterialListWatchStarted(factoryId));
              }
              return bloc;
            },
            child: RawMaterialsScreen(
              initialFilter: filterName == null ? null : initialFilter,
            ),
          );
        },
        routes: [
          GoRoute(
            path: ':materialType',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final materialType = state.pathParameters['materialType']!;
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<RawMaterialDetailBloc>();
                  final factoryId = readFactoryId(context);
                  if (factoryId != null) {
                    bloc.add(
                      RawMaterialDetailWatchStarted(
                        factoryId: factoryId,
                        materialType:
                            RawMaterialType.fromString(materialType),
                      ),
                    );
                  }
                  return bloc;
                },
                child: RawMaterialDetailScreen(materialTypeName: materialType),
              );
            },
            routes: [
              GoRoute(
                path: 'stock-in',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final materialType = state.pathParameters['materialType']!;
                  final supplierId = state.uri.queryParameters['supplierId'];
                  return BlocProvider(
                    create: (context) {
                      final bloc = getIt<StockMovementBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        bloc.add(
                          StockMovementInitialized(
                            factoryId: factoryId,
                            materialType:
                                RawMaterialType.fromString(materialType),
                            movementType: StockMovementType.stockIn,
                          ),
                        );
                      }
                      return bloc;
                    },
                    child: RecordStockMovementScreen(
                      materialTypeName: materialType,
                      movementTypeName: StockMovementType.stockIn.name,
                      initialSupplierId: supplierId,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'stock-out',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final materialType = state.pathParameters['materialType']!;
                  return BlocProvider(
                    create: (context) {
                      final bloc = getIt<StockMovementBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        bloc.add(
                          StockMovementInitialized(
                            factoryId: factoryId,
                            materialType:
                                RawMaterialType.fromString(materialType),
                            movementType: StockMovementType.stockOut,
                          ),
                        );
                      }
                      return bloc;
                    },
                    child: RecordStockMovementScreen(
                      materialTypeName: materialType,
                      movementTypeName: StockMovementType.stockOut.name,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'adjust-in',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final materialType = state.pathParameters['materialType']!;
                  final factoryId = readFactoryId(context);
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) {
                          final bloc = getIt<RawMaterialDetailBloc>();
                          if (factoryId != null) {
                            bloc.add(
                              RawMaterialDetailWatchStarted(
                                factoryId: factoryId,
                                materialType:
                                    RawMaterialType.fromString(materialType),
                              ),
                            );
                          }
                          return bloc;
                        },
                      ),
                      BlocProvider(
                        create: (_) {
                          final bloc = getIt<RawMaterialAdjustmentBloc>();
                          if (factoryId != null) {
                            bloc.add(
                              RawMaterialAdjustmentInitialized(
                                factoryId: factoryId,
                                materialType:
                                    RawMaterialType.fromString(materialType),
                                movementType: StockMovementType.adjustmentIn,
                              ),
                            );
                          }
                          return bloc;
                        },
                      ),
                    ],
                    child: RecordRawMaterialAdjustmentScreen(
                      materialTypeName: materialType,
                      movementTypeName: StockMovementType.adjustmentIn.name,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'adjust-out',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final materialType = state.pathParameters['materialType']!;
                  final factoryId = readFactoryId(context);
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) {
                          final bloc = getIt<RawMaterialDetailBloc>();
                          if (factoryId != null) {
                            bloc.add(
                              RawMaterialDetailWatchStarted(
                                factoryId: factoryId,
                                materialType:
                                    RawMaterialType.fromString(materialType),
                              ),
                            );
                          }
                          return bloc;
                        },
                      ),
                      BlocProvider(
                        create: (_) {
                          final bloc = getIt<RawMaterialAdjustmentBloc>();
                          if (factoryId != null) {
                            bloc.add(
                              RawMaterialAdjustmentInitialized(
                                factoryId: factoryId,
                                materialType:
                                    RawMaterialType.fromString(materialType),
                                movementType: StockMovementType.adjustmentOut,
                              ),
                            );
                          }
                          return bloc;
                        },
                      ),
                    ],
                    child: RecordRawMaterialAdjustmentScreen(
                      materialTypeName: materialType,
                      movementTypeName: StockMovementType.adjustmentOut.name,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'correct/:transactionId',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final materialType = state.pathParameters['materialType']!;
                  final transactionId =
                      state.pathParameters['transactionId']!;
                  return BlocProvider(
                    create: (_) {
                      final bloc = getIt<RawMaterialDetailBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        bloc.add(
                          RawMaterialDetailWatchStarted(
                            factoryId: factoryId,
                            materialType:
                                RawMaterialType.fromString(materialType),
                          ),
                        );
                      }
                      return bloc;
                    },
                    child: RecordRawMaterialCorrectionScreen(
                      materialTypeName: materialType,
                      transactionId: transactionId,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.production,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final filterName = state.uri.queryParameters['filter'];
          final initialFilter = filterName == null
              ? null
              : ProductionListFilter.values.firstWhere(
                  (filter) => filter.name == filterName,
                  orElse: () => ProductionListFilter.thisMonth,
                );

          return BlocProvider(
            create: (context) {
              final bloc = getIt<ProductionListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(ProductionListWatchStarted(factoryId));
              }
              return bloc;
            },
            child: ProductionBatchesScreen(
              initialFilter: filterName == null ? null : initialFilter,
            ),
          );
        },
        routes: [
          GoRoute(
            path: 'add',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<ProductionFormBloc>();
                  final factoryId = readFactoryId(context);
                  if (factoryId != null) {
                    bloc.add(ProductionFormInitialized(factoryId: factoryId));
                  }
                  return bloc;
                },
                child: const AddProductionBatchScreen(),
              );
            },
          ),
          GoRoute(
            path: ':batchId/edit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final batchId = state.pathParameters['batchId']!;
              return BlocProvider(
                create: (_) => getIt<ProductionFormBloc>()
                  ..add(ProductionFormLoadRequested(batchId)),
                child: AddProductionBatchScreen(batchId: batchId),
              );
            },
          ),
          GoRoute(
            path: ':batchId',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final batchId = state.pathParameters['batchId']!;
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<ProductionDetailBloc>();
                  bloc.add(ProductionDetailWatchStarted(batchId));
                  return bloc;
                },
                child: ProductionBatchDetailScreen(batchId: batchId),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.finishedGoods,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final filterName = state.uri.queryParameters['filter'];
          final initialFilter = filterName == null
              ? null
              : FinishedGoodsListFilter.values.firstWhere(
                  (filter) => filter.name == filterName,
                  orElse: () => FinishedGoodsListFilter.all,
                );

          return BlocProvider(
            create: (context) {
              final bloc = getIt<FinishedGoodsListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(FinishedGoodsListWatchStarted(factoryId));
              }
              return bloc;
            },
            child: FinishedGoodsScreen(
              initialFilter: filterName == null ? null : initialFilter,
            ),
          );
        },
        routes: [
          GoRoute(
            path: ':finishedGoodId',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final finishedGoodId = state.pathParameters['finishedGoodId']!;
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<FinishedGoodsDetailBloc>();
                  final factoryId = readFactoryId(context);
                  if (factoryId != null) {
                    bloc.add(
                      FinishedGoodsDetailWatchStarted(
                        factoryId: factoryId,
                        finishedGoodId: finishedGoodId,
                      ),
                    );
                  }
                  return bloc;
                },
                child: FinishedGoodDetailScreen(
                  finishedGoodId: finishedGoodId,
                ),
              );
            },
            routes: [
              GoRoute(
                path: 'adjust-in',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final finishedGoodId = state.pathParameters['finishedGoodId']!;
                  final factoryId = readFactoryId(context);
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) {
                          final bloc = getIt<FinishedGoodsDetailBloc>();
                          if (factoryId != null) {
                            bloc.add(
                              FinishedGoodsDetailWatchStarted(
                                factoryId: factoryId,
                                finishedGoodId: finishedGoodId,
                              ),
                            );
                          }
                          return bloc;
                        },
                      ),
                      BlocProvider(
                        create: (_) {
                          final bloc = getIt<InventoryAdjustmentBloc>();
                          if (factoryId != null) {
                            bloc.add(
                              InventoryAdjustmentInitialized(
                                factoryId: factoryId,
                                finishedGoodId: finishedGoodId,
                                movementType: InventoryMovementType.adjustmentIn,
                              ),
                            );
                          }
                          return bloc;
                        },
                      ),
                    ],
                    child: RecordInventoryAdjustmentScreen(
                      finishedGoodId: finishedGoodId,
                      movementTypeName:
                          InventoryMovementType.adjustmentIn.name,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'adjust-out',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final finishedGoodId = state.pathParameters['finishedGoodId']!;
                  final factoryId = readFactoryId(context);
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(
                        create: (_) {
                          final bloc = getIt<FinishedGoodsDetailBloc>();
                          if (factoryId != null) {
                            bloc.add(
                              FinishedGoodsDetailWatchStarted(
                                factoryId: factoryId,
                                finishedGoodId: finishedGoodId,
                              ),
                            );
                          }
                          return bloc;
                        },
                      ),
                      BlocProvider(
                        create: (_) {
                          final bloc = getIt<InventoryAdjustmentBloc>();
                          if (factoryId != null) {
                            bloc.add(
                              InventoryAdjustmentInitialized(
                                factoryId: factoryId,
                                finishedGoodId: finishedGoodId,
                                movementType:
                                    InventoryMovementType.adjustmentOut,
                              ),
                            );
                          }
                          return bloc;
                        },
                      ),
                    ],
                    child: RecordInventoryAdjustmentScreen(
                      finishedGoodId: finishedGoodId,
                      movementTypeName:
                          InventoryMovementType.adjustmentOut.name,
                    ),
                  );
                },
              ),
              GoRoute(
                path: 'correct/:transactionId',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final finishedGoodId = state.pathParameters['finishedGoodId']!;
                  final transactionId =
                      state.pathParameters['transactionId']!;
                  return BlocProvider(
                    create: (_) {
                      final bloc = getIt<FinishedGoodsDetailBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        bloc.add(
                          FinishedGoodsDetailWatchStarted(
                            factoryId: factoryId,
                            finishedGoodId: finishedGoodId,
                          ),
                        );
                      }
                      return bloc;
                    },
                    child: RecordInventoryCorrectionScreen(
                      finishedGoodId: finishedGoodId,
                      transactionId: transactionId,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.employees,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          return BlocProvider(
            create: (context) {
              final bloc = getIt<EmployeeListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(EmployeeListWatchStarted(factoryId));
              }
              return bloc;
            },
            child: const EmployeesScreen(),
          );
        },
        routes: [
          GoRoute(
            path: 'add',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<EmployeeFormBloc>();
                  final factoryId = readFactoryId(context);
                  if (factoryId != null) {
                    bloc.add(EmployeeFormInitialized(factoryId: factoryId));
                  }
                  return bloc;
                },
                child: const AddEditEmployeeScreen(),
              );
            },
          ),
          GoRoute(
            path: ':employeeId',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final employeeId = state.pathParameters['employeeId']!;
              final factoryId = readFactoryId(context);
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<EmployeeDetailBloc>();
                  if (factoryId != null) {
                    bloc.add(
                      EmployeeDetailWatchStarted(
                        factoryId: factoryId,
                        employeeId: employeeId,
                      ),
                    );
                  }
                  return bloc;
                },
                child: EmployeeDetailScreen(employeeId: employeeId),
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final employeeId = state.pathParameters['employeeId']!;
                  return BlocProvider(
                    create: (_) => getIt<EmployeeFormBloc>()
                      ..add(EmployeeFormLoadRequested(employeeId)),
                    child: AddEditEmployeeScreen(employeeId: employeeId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.attendance,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final dateParam = state.uri.queryParameters['date'];
          DateTime? initialDate;
          if (dateParam != null) {
            try {
              initialDate = DateKeys.toDate(dateParam);
            } catch (_) {
              initialDate = null;
            }
          }

          return BlocProvider(
            create: (context) {
              final bloc = getIt<DailyAttendanceBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(
                  DailyAttendanceWatchStarted(
                    factoryId: factoryId,
                    initialDate: initialDate,
                  ),
                );
              }
              return bloc;
            },
            child: DailyAttendanceScreen(initialDate: initialDate),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.equipment,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final filterName = state.uri.queryParameters['filter'];
          final initialFilter = filterName == null
              ? null
              : EquipmentListFilter.fromQuery(filterName);

          return BlocProvider(
            create: (context) {
              final bloc = getIt<EquipmentListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(
                  EquipmentListWatchStarted(
                    factoryId,
                    initialFilter: initialFilter,
                  ),
                );
              }
              return bloc;
            },
            child: EquipmentScreen(initialFilter: initialFilter),
          );
        },
        routes: [
          GoRoute(
            path: 'add',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<EquipmentFormBloc>();
                  final factoryId = readFactoryId(context);
                  if (factoryId != null) {
                    bloc.add(EquipmentFormInitialized(factoryId: factoryId));
                  }
                  return bloc;
                },
                child: const AddEditEquipmentScreen(),
              );
            },
          ),
          GoRoute(
            path: ':equipmentId',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final equipmentId = state.pathParameters['equipmentId']!;
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<EquipmentDetailBloc>();
                  bloc.add(EquipmentDetailWatchStarted(equipmentId));
                  return bloc;
                },
                child: EquipmentDetailScreen(equipmentId: equipmentId),
              );
            },
            routes: [
              GoRoute(
                path: 'edit',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final equipmentId = state.pathParameters['equipmentId']!;
                  return BlocProvider(
                    create: (_) => getIt<EquipmentFormBloc>()
                      ..add(EquipmentFormLoadRequested(equipmentId)),
                    child: AddEditEquipmentScreen(equipmentId: equipmentId),
                  );
                },
              ),
              GoRoute(
                path: 'maintenance',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final equipmentId = state.pathParameters['equipmentId']!;
                  return BlocProvider(
                    create: (_) => getIt<MaintenanceFormBloc>()
                      ..add(MaintenanceFormInitialized(equipmentId)),
                    child: RecordMaintenanceScreen(equipmentId: equipmentId),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.qualityChecks,
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final filterName = state.uri.queryParameters['filter'];
          final initialFilter = filterName == null
              ? null
              : QcListFilter.fromQuery(filterName);

          return BlocProvider(
            create: (context) {
              final bloc = getIt<QcListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(
                  QcListWatchStarted(
                    factoryId,
                    initialFilter: initialFilter,
                  ),
                );
              }
              return bloc;
            },
            child: QualityChecksScreen(initialFilter: initialFilter),
          );
        },
        routes: [
          GoRoute(
            path: 'add',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final refTypeName = state.uri.queryParameters['refType'];
              final referenceId = state.uri.queryParameters['referenceId'];
              final referenceType = refTypeName == null
                  ? null
                  : QcReferenceType.fromString(refTypeName);

              return BlocProvider(
                create: (context) {
                  final bloc = getIt<QcFormBloc>();
                  final factoryId = readFactoryId(context);
                  if (factoryId != null) {
                    bloc.add(
                      QcFormInitialized(
                        factoryId: factoryId,
                        referenceType: referenceType,
                        referenceId: referenceId,
                      ),
                    );
                  }
                  return bloc;
                },
                child: RecordQcScreen(
                  referenceType: referenceType,
                  referenceId: referenceId,
                ),
              );
            },
          ),
          GoRoute(
            path: ':qcId/edit',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final qcId = state.pathParameters['qcId']!;
              return BlocProvider(
                create: (_) => getIt<QcFormBloc>()
                  ..add(QcFormLoadRequested(qcId)),
                child: RecordQcScreen(qcId: qcId),
              );
            },
          ),
          GoRoute(
            path: ':qcId',
            parentNavigatorKey: rootNavigatorKey,
            builder: (context, state) {
              final qcId = state.pathParameters['qcId']!;
              return BlocProvider(
                create: (context) {
                  final bloc = getIt<QcDetailBloc>();
                  bloc.add(QcDetailWatchStarted(qcId));
                  return bloc;
                },
                child: QcDetailScreen(qcId: qcId),
              );
            },
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.dashboard,
                builder: (context, state) {
                  return BlocProvider(
                    create: (context) {
                      final bloc = getIt<DashboardBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        bloc.add(DashboardWatchStarted(factoryId));
                      }
                      return bloc;
                    },
                    child: const DashboardScreen(),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.jobWork,
                builder: (context, state) {
                  return BlocProvider(
                    create: (context) {
                      final bloc = getIt<JobWorkListBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        final filter = JobWorkListStageFilter.fromQuery(
                          state.uri.queryParameters['filter'],
                        );
                        bloc.add(
                          JobWorkListWatchStarted(
                            factoryId,
                            initialFilter: filter,
                          ),
                        );
                      }
                      return bloc;
                    },
                    child: const JobWorkListScreen(),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      return BlocProvider(
                        create: (context) {
                          final bloc = getIt<JobWorkFormBloc>();
                          final factoryId = readFactoryId(context);
                          if (factoryId != null) {
                            bloc.add(
                              JobWorkFormInitialized(factoryId: factoryId),
                            );
                          }
                          return bloc;
                        },
                        child: const AddEditJobWorkScreen(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'invoices/:invoiceId/edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final invoiceId = state.pathParameters['invoiceId']!;
                      return BlocProvider(
                        create: (_) => getIt<JobWorkInvoiceBloc>()
                          ..add(JobWorkInvoiceLoadById(invoiceId)),
                        child: EditJobWorkInvoiceScreen(invoiceId: invoiceId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'invoices/:invoiceId/payment',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final invoiceId = state.pathParameters['invoiceId']!;
                      return BlocProvider(
                        create: (_) => getIt<JobWorkInvoiceBloc>()
                          ..add(JobWorkInvoiceLoadById(invoiceId)),
                        child: RecordPaymentScreen(invoiceId: invoiceId),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: ':paymentId/edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final invoiceId =
                              state.pathParameters['invoiceId']!;
                          final paymentId =
                              state.pathParameters['paymentId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkInvoiceBloc>()
                              ..add(JobWorkInvoiceLoadById(invoiceId)),
                            child: RecordPaymentScreen(
                              invoiceId: invoiceId,
                              paymentId: paymentId,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'collections/:collectionId/slip',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final collectionId =
                          state.pathParameters['collectionId']!;
                      return JobWorkCollectionSlipScreen(
                        collectionId: collectionId,
                      );
                    },
                  ),
                  GoRoute(
                    path: ':jobWorkId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final jobWorkId = state.pathParameters['jobWorkId']!;
                      return BlocProvider(
                        create: (_) => getIt<JobWorkFormBloc>()
                          ..add(JobWorkFormLoadRequested(jobWorkId)),
                        child: JobWorkDetailScreen(jobWorkId: jobWorkId),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkFormBloc>()
                              ..add(JobWorkFormLoadRequested(jobWorkId)),
                            child: AddEditJobWorkScreen(jobWorkId: jobWorkId),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'loads/add',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkLoadFormBloc>()
                              ..add(
                                JobWorkLoadFormInitialized(
                                  jobWorkId: jobWorkId,
                                ),
                              ),
                            child: AddJobWorkLoadScreen(jobWorkId: jobWorkId),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'loads/:loadId',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          final loadId = state.pathParameters['loadId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkLoadDetailBloc>()
                              ..add(
                                JobWorkLoadDetailStarted(
                                  jobWorkId: jobWorkId,
                                  loadId: loadId,
                                ),
                              ),
                            child: JobWorkLoadDetailScreen(
                              jobWorkId: jobWorkId,
                              loadId: loadId,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'loads/:loadId/record-output',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          final loadId = state.pathParameters['loadId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkOutputBloc>()
                              ..add(
                                JobWorkOutputLoadRequested(
                                  jobWorkId: jobWorkId,
                                  loadId: loadId,
                                ),
                              ),
                            child: RecordJobWorkOutputScreen(
                              jobWorkId: jobWorkId,
                              loadId: loadId,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'loads/:loadId/collect-material',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          final loadId = state.pathParameters['loadId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkCollectionFormBloc>()
                              ..add(
                                JobWorkCollectionFormInitialized(
                                  jobWorkOrderId: jobWorkId,
                                  loadId: loadId,
                                ),
                              ),
                            child: CollectMaterialScreen(
                              jobWorkId: jobWorkId,
                              loadId: loadId,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'collect-material',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkCollectionFormBloc>()
                              ..add(
                                JobWorkCollectionFormInitialized(
                                  jobWorkOrderId: jobWorkId,
                                ),
                              ),
                            child: CollectMaterialScreen(
                              jobWorkId: jobWorkId,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'record-output',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkOutputBloc>()
                              ..add(
                                JobWorkOutputLoadRequested(
                                  jobWorkId: jobWorkId,
                                ),
                              ),
                            child: RecordJobWorkOutputScreen(
                              jobWorkId: jobWorkId,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'invoice',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkInvoiceBloc>()
                              ..add(
                                JobWorkInvoiceLoadByJobWork(
                                  factoryId: readFactoryId(context)!,
                                  jobWorkId: jobWorkId,
                                ),
                              ),
                            child: JobWorkInvoiceScreen(jobWorkId: jobWorkId),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.customers,
                builder: (context, state) {
                  return BlocProvider(
                    create: (context) {
                      final bloc = getIt<CustomerListBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        bloc.add(CustomerListWatchStarted(factoryId));
                      }
                      return bloc;
                    },
                    child: const CustomersScreen(),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      return BlocProvider(
                        create: (context) {
                          final bloc = getIt<CustomerFormBloc>();
                          final factoryId = readFactoryId(context);
                          if (factoryId != null) {
                            bloc.add(
                              CustomerFormInitialized(factoryId: factoryId),
                            );
                          }
                          return bloc;
                        },
                        child: const AddEditCustomerScreen(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'statement/:customerId',
                    parentNavigatorKey: rootNavigatorKey,
                    pageBuilder: (context, state) {
                      final customerId = state.pathParameters['customerId']!;
                      return MaterialPage<void>(
                        key: state.pageKey,
                        child: CustomerStatementScreen(customerId: customerId),
                      );
                    },
                  ),
                  GoRoute(
                    path: ':customerId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final customerId = state.pathParameters['customerId']!;
                      return BlocProvider(
                        create: (_) => getIt<CustomerFormBloc>()
                          ..add(CustomerFormLoadRequested(customerId)),
                        child: CustomerDetailScreen(customerId: customerId),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final customerId =
                              state.pathParameters['customerId']!;
                          return BlocProvider(
                            create: (_) => getIt<CustomerFormBloc>()
                              ..add(CustomerFormLoadRequested(customerId)),
                            child: AddEditCustomerScreen(
                              customerId: customerId,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.sales,
                builder: (context, state) {
                  return BlocProvider(
                    create: (context) {
                      final bloc = getIt<SalesOrderListBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        final filter = SalesListFilter.fromQuery(
                          state.uri.queryParameters['filter'],
                        );
                        bloc.add(
                          SalesOrderListWatchStarted(
                            factoryId,
                            initialFilter: filter,
                          ),
                        );
                      }
                      return bloc;
                    },
                    child: const SalesOrderListScreen(),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      return BlocProvider(
                        create: (context) {
                          final bloc = getIt<SalesOrderFormBloc>();
                          final factoryId = readFactoryId(context);
                          if (factoryId != null) {
                            bloc.add(
                              SalesOrderFormInitialized(factoryId: factoryId),
                            );
                          }
                          return bloc;
                        },
                        child: const AddEditSalesOrderScreen(),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'invoices/:invoiceId/edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final invoiceId = state.pathParameters['invoiceId']!;
                      return BlocProvider(
                        create: (_) => getIt<SalesInvoiceBloc>()
                          ..add(SalesInvoiceLoadById(invoiceId)),
                        child: EditSalesInvoiceScreen(invoiceId: invoiceId),
                      );
                    },
                  ),
                  GoRoute(
                    path: 'invoices/:invoiceId/payment',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final invoiceId = state.pathParameters['invoiceId']!;
                      return BlocProvider(
                        create: (_) => getIt<SalesInvoiceBloc>()
                          ..add(SalesInvoiceLoadById(invoiceId)),
                        child: RecordSalesPaymentScreen(invoiceId: invoiceId),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: ':paymentId/edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final invoiceId =
                              state.pathParameters['invoiceId']!;
                          final paymentId =
                              state.pathParameters['paymentId']!;
                          return BlocProvider(
                            create: (_) => getIt<SalesInvoiceBloc>()
                              ..add(SalesInvoiceLoadById(invoiceId)),
                            child: RecordSalesPaymentScreen(
                              invoiceId: invoiceId,
                              paymentId: paymentId,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: ':salesOrderId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final salesOrderId = state.pathParameters['salesOrderId']!;
                      return BlocProvider(
                        create: (_) => getIt<SalesOrderFormBloc>()
                          ..add(SalesOrderFormLoadRequested(salesOrderId)),
                        child: SalesOrderDetailScreen(salesOrderId: salesOrderId),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'edit',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final salesOrderId =
                              state.pathParameters['salesOrderId']!;
                          return BlocProvider(
                            create: (_) => getIt<SalesOrderFormBloc>()
                              ..add(SalesOrderFormLoadRequested(salesOrderId)),
                            child: AddEditSalesOrderScreen(
                              salesOrderId: salesOrderId,
                            ),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'invoice',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final salesOrderId =
                              state.pathParameters['salesOrderId']!;
                          return BlocProvider(
                            create: (_) => getIt<SalesInvoiceBloc>()
                              ..add(
                                SalesInvoiceLoadByOrder(
                                  factoryId: readFactoryId(context)!,
                                  salesOrderId: salesOrderId,
                                ),
                              ),
                            child: SalesInvoiceScreen(salesOrderId: salesOrderId),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.deliveries,
                builder: (context, state) {
                  final filterName = state.uri.queryParameters['filter'];
                  final initialFilter = filterName == null
                      ? null
                      : DeliveryListFilter.fromQuery(filterName);

                  return BlocProvider(
                    create: (context) {
                      final bloc = getIt<DeliveryListBloc>();
                      final factoryId = readFactoryId(context);
                      if (factoryId != null) {
                        bloc.add(
                          DeliveryListWatchStarted(
                            factoryId,
                            initialFilter: initialFilter,
                            driverEmployeeId: readDriverEmployeeId(context),
                          ),
                        );
                      }
                      return bloc;
                    },
                    child: DeliveriesScreen(initialFilter: initialFilter),
                  );
                },
                routes: [
                  GoRoute(
                    path: 'add',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final salesOrderId =
                          state.uri.queryParameters['salesOrderId'];
                      return BlocProvider(
                        create: (context) {
                          final bloc = getIt<DeliveryFormBloc>();
                          final factoryId = readFactoryId(context);
                          if (factoryId != null) {
                            bloc.add(
                              DeliveryFormInitialized(
                                factoryId: factoryId,
                                salesOrderId: salesOrderId,
                              ),
                            );
                          }
                          return bloc;
                        },
                        child: CreateDeliveryScreen(salesOrderId: salesOrderId),
                      );
                    },
                  ),
                  GoRoute(
                    path: ':deliveryId/edit',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final deliveryId = state.pathParameters['deliveryId']!;
                      return BlocProvider(
                        create: (context) {
                          final bloc = getIt<DeliveryFormBloc>();
                          bloc.add(DeliveryFormLoadRequested(deliveryId));
                          return bloc;
                        },
                        child: CreateDeliveryScreen(deliveryId: deliveryId),
                      );
                    },
                  ),
                  GoRoute(
                    path: ':deliveryId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final deliveryId = state.pathParameters['deliveryId']!;
                      return BlocProvider(
                        create: (context) {
                          final bloc = getIt<DeliveryDetailBloc>();
                          bloc.add(
                            DeliveryDetailWatchStarted(
                              deliveryId,
                              driverEmployeeId: readDriverEmployeeId(context),
                            ),
                          );
                          return bloc;
                        },
                        child: DeliveryDetailScreen(deliveryId: deliveryId),
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'challan',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final deliveryId =
                              state.pathParameters['deliveryId']!;
                          return BlocProvider(
                            create: (context) {
                              final bloc = getIt<DeliveryDetailBloc>();
                              bloc.add(
                                DeliveryDetailWatchStarted(
                                  deliveryId,
                                  driverEmployeeId:
                                      readDriverEmployeeId(context),
                                ),
                              );
                              return bloc;
                            },
                            child: DeliveryChallanScreen(deliveryId: deliveryId),
                          );
                        },
                      ),
                      GoRoute(
                        path: 'confirm',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final deliveryId =
                              state.pathParameters['deliveryId']!;
                          return BlocProvider(
                            create: (_) => getIt<DeliveryConfirmBloc>()
                              ..add(DeliveryConfirmInitialized(deliveryId)),
                            child: ConfirmDeliveryScreen(deliveryId: deliveryId),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RoutePaths.more,
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
