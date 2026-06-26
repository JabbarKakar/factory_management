import 'package:get_it/get_it.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../data/repositories/auth_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<AuthRepository>(AuthRepository.new);
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
}
