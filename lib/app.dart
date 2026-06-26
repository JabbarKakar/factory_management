import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'blocs/auth/auth_bloc.dart';
import 'blocs/theme/theme_cubit.dart';
import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'data/services/job_work_cleanup_service.dart';
import 'presentation/routes/app_router.dart';

class FactoryManagementApp extends StatefulWidget {
  const FactoryManagementApp({super.key});

  @override
  State<FactoryManagementApp> createState() => _FactoryManagementAppState();
}

class _FactoryManagementAppState extends State<FactoryManagementApp> {
  late final AuthBloc _authBloc;
  late final ThemeCubit _themeCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
    _themeCubit = getIt<ThemeCubit>();
    _router = createAppRouter(_authBloc);
    _runOrphanedJobWorkCleanupIfNeeded();
  }

  void _runOrphanedJobWorkCleanupIfNeeded() {
    final authState = _authBloc.state;
    if (authState is AuthAuthenticated) {
      getIt<JobWorkCleanupService>()
          .runIfNeeded(authState.user.factoryId)
          .ignore();
      return;
    }

    _authBloc.stream
        .where((state) => state is AuthAuthenticated)
        .first
        .then((state) {
      final user = (state as AuthAuthenticated).user;
      getIt<JobWorkCleanupService>().runIfNeeded(user.factoryId).ignore();
    }).ignore();
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
