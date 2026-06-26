import 'package:get_it/get_it.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/customer/customer_form_bloc.dart';
import '../../blocs/customer/customer_list_bloc.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/theme_repository.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<AuthRepository>(AuthRepository.new);
  getIt.registerLazySingleton<ThemeRepository>(ThemeRepository.new);
  getIt.registerLazySingleton<CustomerRepository>(CustomerRepository.new);

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<ThemeRepository>()),
  );
  getIt.registerFactory<CustomerListBloc>(
    () => CustomerListBloc(repository: getIt<CustomerRepository>()),
  );
  getIt.registerFactory<CustomerFormBloc>(
    () => CustomerFormBloc(repository: getIt<CustomerRepository>()),
  );
}
