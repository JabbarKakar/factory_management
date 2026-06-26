import 'package:get_it/get_it.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/theme_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<AuthRepository>(AuthRepository.new);
  getIt.registerLazySingleton<ThemeRepository>(ThemeRepository.new);

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<ThemeRepository>()),
  );
}
