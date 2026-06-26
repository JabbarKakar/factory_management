import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/notification/notification_bloc.dart';
import 'blocs/theme/theme_cubit.dart';
import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'data/services/job_work_cleanup_service.dart';
import 'data/services/payment_due_scanner_service.dart';
import 'presentation/routes/app_router.dart';

class FactoryManagementApp extends StatefulWidget {
  const FactoryManagementApp({super.key});

  @override
  State<FactoryManagementApp> createState() => _FactoryManagementAppState();
}

class _FactoryManagementAppState extends State<FactoryManagementApp> {
  late final AuthBloc _authBloc;
  late final ThemeCubit _themeCubit;
  late final NotificationBloc _notificationBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
    _themeCubit = getIt<ThemeCubit>();
    _notificationBloc = getIt<NotificationBloc>();
    _router = createAppRouter(_authBloc);
    _runStartupServicesIfNeeded();
  }

  void _runStartupServicesIfNeeded() {
    void onAuthenticated(AuthAuthenticated state) {
      getIt<JobWorkCleanupService>()
          .runIfNeeded(state.user.factoryId)
          .ignore();
      getIt<PaymentDueScannerService>()
          .runIfNeeded(state.user.factoryId)
          .ignore();
      _notificationBloc.add(
        NotificationWatchStarted(
          factoryId: state.user.factoryId,
          userId: state.user.id,
        ),
      );
    }

    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      onAuthenticated(authState);
      return;
    }

    _authBloc.stream
        .where((state) => state is AuthAuthenticated)
        .first
        .then((state) => onAuthenticated(state as AuthAuthenticated))
        .ignore();
  }

  @override
  void dispose() {
    _authBloc.close();
    _themeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _themeCubit),
        BlocProvider.value(value: _notificationBloc),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: AppStrings.appName,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
