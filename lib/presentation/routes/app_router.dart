import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/job_work/job_work_form_bloc.dart';
import '../../blocs/job_work/job_work_invoice_bloc.dart';
import '../../blocs/job_work/job_work_list_bloc.dart';
import '../../blocs/job_work/job_work_output_bloc.dart';
import '../../blocs/customer/customer_form_bloc.dart';
import '../../blocs/customer/customer_list_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/expense/expense_form_bloc.dart';
import '../../blocs/expense/expense_list_bloc.dart';
import '../../blocs/pl/pl_report_bloc.dart';
import '../../blocs/raw_material/raw_material_detail_bloc.dart';
import '../../blocs/raw_material/raw_material_list_bloc.dart';
import '../../blocs/raw_material/stock_movement_bloc.dart';
import '../../blocs/supplier/supplier_form_bloc.dart';
import '../../blocs/supplier/supplier_list_bloc.dart';
import '../../blocs/sales/sales_invoice_bloc.dart';
import '../../blocs/sales/sales_order_form_bloc.dart';
import '../../blocs/sales/sales_order_list_bloc.dart';
import '../../core/di/injection.dart';
import '../../domain/enums/raw_material_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/notification_enums.dart';
import '../../domain/enums/sales_enums.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/customers/add_edit_customer_screen.dart';
import '../screens/customers/customer_detail_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/job_work/add_edit_job_work_screen.dart';
import '../screens/job_work/job_work_detail_screen.dart';
import '../screens/job_work/job_work_invoice_screen.dart';
import '../screens/job_work/job_work_list_screen.dart';
import '../screens/job_work/record_job_work_output_screen.dart';
import '../screens/job_work/record_payment_screen.dart';
import '../screens/sales/add_edit_sales_order_screen.dart';
import '../screens/sales/record_sales_payment_screen.dart';
import '../screens/sales/sales_invoice_screen.dart';
import '../screens/sales/sales_order_detail_screen.dart';
import '../screens/sales/sales_order_list_screen.dart';
import '../screens/expenses/add_edit_expense_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/reports/pl_report_screen.dart';
import '../screens/raw_materials/raw_material_detail_screen.dart';
import '../screens/raw_materials/raw_materials_screen.dart';
import '../screens/raw_materials/record_stock_movement_screen.dart';
import '../screens/suppliers/add_edit_supplier_screen.dart';
import '../screens/suppliers/supplier_detail_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/more/more_screen.dart';
import '../screens/notifications/notification_center_screen.dart';
import '../screens/shell/main_shell.dart';
import '../utils/auth_context.dart';
import 'go_router_refresh_stream.dart';
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
          state.matchedLocation == RoutePaths.forgotPassword;

      if (isSplash) {
        return null;
      }

      if (isBootstrapping) {
        return null;
      }

      if (!isAuthenticated && !isAuthRoute) {
        return RoutePaths.login;
      }

      if (isAuthenticated && isAuthRoute) {
        return RoutePaths.dashboard;
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
        builder: (context, state) {
          return BlocProvider(
            create: (context) {
              final bloc = getIt<PlReportBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(PlReportWatchStarted(factoryId));
              }
              return bloc;
            },
            child: const PlReportScreen(),
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
          return BlocProvider(
            create: (context) {
              final bloc = getIt<RawMaterialListBloc>();
              final factoryId = readFactoryId(context);
              if (factoryId != null) {
                bloc.add(RawMaterialListWatchStarted(factoryId));
              }
              return bloc;
            },
            child: const RawMaterialsScreen(),
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
            ],
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
                        path: 'record-output',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) {
                          final jobWorkId =
                              state.pathParameters['jobWorkId']!;
                          return BlocProvider(
                            create: (_) => getIt<JobWorkOutputBloc>()
                              ..add(JobWorkOutputLoadRequested(jobWorkId)),
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
                                JobWorkInvoiceLoadByJobWork(jobWorkId),
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
                              ..add(SalesInvoiceLoadByOrder(salesOrderId)),
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
