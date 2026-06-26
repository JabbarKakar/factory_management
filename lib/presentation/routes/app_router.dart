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
import '../../core/di/injection.dart';
import '../../domain/enums/notification_enums.dart';
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
import '../screens/more/more_screen.dart';
import '../screens/notifications/notification_center_screen.dart';
import '../screens/sales/sales_placeholder_screen.dart';
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
                        bloc.add(JobWorkListWatchStarted(factoryId));
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
                builder: (context, state) => const SalesPlaceholderScreen(),
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
