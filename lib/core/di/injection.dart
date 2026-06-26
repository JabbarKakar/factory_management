import 'package:get_it/get_it.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/customer/customer_form_bloc.dart';
import '../../blocs/customer/customer_list_bloc.dart';
import '../../blocs/job_work/job_work_form_bloc.dart';
import '../../blocs/job_work/job_work_list_bloc.dart';
import '../../blocs/job_work/job_work_output_bloc.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/theme_repository.dart';
import '../../data/services/job_work_cleanup_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<AuthRepository>(AuthRepository.new);
  getIt.registerLazySingleton<ThemeRepository>(ThemeRepository.new);
  getIt.registerLazySingleton<CustomerRepository>(CustomerRepository.new);
  getIt.registerLazySingleton<JobWorkRepository>(JobWorkRepository.new);
  getIt.registerLazySingleton<JobWorkCleanupService>(
    () => JobWorkCleanupService(jobWorkRepository: getIt<JobWorkRepository>()),
  );

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
    () => CustomerFormBloc(
      repository: getIt<CustomerRepository>(),
      jobWorkRepository: getIt<JobWorkRepository>(),
    ),
  );
  getIt.registerFactory<JobWorkListBloc>(
    () => JobWorkListBloc(repository: getIt<JobWorkRepository>()),
  );
  getIt.registerFactory<JobWorkFormBloc>(
    () => JobWorkFormBloc(repository: getIt<JobWorkRepository>()),
  );
  getIt.registerFactory<JobWorkOutputBloc>(
    () => JobWorkOutputBloc(repository: getIt<JobWorkRepository>()),
  );
}
