import 'package:get_it/get_it.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/customer/customer_form_bloc.dart';
import '../../blocs/customer/customer_list_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/job_work/job_work_form_bloc.dart';
import '../../blocs/job_work/job_work_invoice_bloc.dart';
import '../../blocs/job_work/job_work_list_bloc.dart';
import '../../blocs/job_work/job_work_output_bloc.dart';
import '../../blocs/notification/notification_bloc.dart';
import '../../blocs/expense/expense_form_bloc.dart';
import '../../blocs/expense/expense_list_bloc.dart';
import '../../blocs/sales/sales_invoice_bloc.dart';
import '../../blocs/sales/sales_order_form_bloc.dart';
import '../../blocs/sales/sales_order_list_bloc.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/repositories/theme_repository.dart';
import '../../data/services/customer_ledger_service.dart';
import '../../data/services/job_work_cleanup_service.dart';
import '../../data/services/payment_due_scanner_service.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerLazySingleton<AuthRepository>(AuthRepository.new);
  getIt.registerLazySingleton<ThemeRepository>(ThemeRepository.new);
  getIt.registerLazySingleton<CustomerRepository>(CustomerRepository.new);
  getIt.registerLazySingleton<JobWorkRepository>(JobWorkRepository.new);
  getIt.registerLazySingleton<SalesOrderRepository>(SalesOrderRepository.new);
  getIt.registerLazySingleton<JobWorkInvoiceRepository>(
    () => JobWorkInvoiceRepository(
      jobWorkRepository: getIt<JobWorkRepository>(),
    ),
  );
  getIt.registerLazySingleton<SalesInvoiceRepository>(
    () => SalesInvoiceRepository(
      salesOrderRepository: getIt<SalesOrderRepository>(),
    ),
  );
  getIt.registerLazySingleton<NotificationRepository>(NotificationRepository.new);
  getIt.registerLazySingleton<CustomerLedgerService>(
    () => CustomerLedgerService(
      customerRepository: getIt<CustomerRepository>(),
      jobWorkInvoiceRepository: getIt<JobWorkInvoiceRepository>(),
      salesInvoiceRepository: getIt<SalesInvoiceRepository>(),
    ),
  );
  getIt.registerLazySingleton<PaymentDueScannerService>(
    () => PaymentDueScannerService(
      jobWorkInvoiceRepository: getIt<JobWorkInvoiceRepository>(),
      salesInvoiceRepository: getIt<SalesInvoiceRepository>(),
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );
  getIt.registerLazySingleton<PaymentRepository>(
    () => PaymentRepository(
      jobWorkInvoiceRepository: getIt<JobWorkInvoiceRepository>(),
      salesInvoiceRepository: getIt<SalesInvoiceRepository>(),
      jobWorkRepository: getIt<JobWorkRepository>(),
      salesOrderRepository: getIt<SalesOrderRepository>(),
      ledgerService: getIt<CustomerLedgerService>(),
      notificationRepository: getIt<NotificationRepository>(),
      scannerService: getIt<PaymentDueScannerService>(),
    ),
  );
  getIt.registerLazySingleton<ExpenseRepository>(ExpenseRepository.new);
  getIt.registerLazySingleton<JobWorkCleanupService>(
    () => JobWorkCleanupService(jobWorkRepository: getIt<JobWorkRepository>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authRepository: getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<ThemeCubit>(
    () => ThemeCubit(getIt<ThemeRepository>()),
  );
  getIt.registerLazySingleton<NotificationBloc>(
    () => NotificationBloc(
      repository: getIt<NotificationRepository>(),
      scannerService: getIt<PaymentDueScannerService>(),
    ),
  );
  getIt.registerFactory<CustomerListBloc>(
    () => CustomerListBloc(repository: getIt<CustomerRepository>()),
  );
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(
      paymentRepository: getIt<PaymentRepository>(),
      jobWorkRepository: getIt<JobWorkRepository>(),
      salesOrderRepository: getIt<SalesOrderRepository>(),
      customerRepository: getIt<CustomerRepository>(),
      jobWorkInvoiceRepository: getIt<JobWorkInvoiceRepository>(),
      salesInvoiceRepository: getIt<SalesInvoiceRepository>(),
      scannerService: getIt<PaymentDueScannerService>(),
    ),
  );
  getIt.registerFactory<CustomerFormBloc>(
    () => CustomerFormBloc(
      repository: getIt<CustomerRepository>(),
      jobWorkRepository: getIt<JobWorkRepository>(),
      salesOrderRepository: getIt<SalesOrderRepository>(),
      salesInvoiceRepository: getIt<SalesInvoiceRepository>(),
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
  getIt.registerFactory<JobWorkInvoiceBloc>(
    () => JobWorkInvoiceBloc(
      invoiceRepository: getIt<JobWorkInvoiceRepository>(),
      paymentRepository: getIt<PaymentRepository>(),
      ledgerService: getIt<CustomerLedgerService>(),
      scannerService: getIt<PaymentDueScannerService>(),
    ),
  );
  getIt.registerFactory<SalesOrderListBloc>(
    () => SalesOrderListBloc(repository: getIt<SalesOrderRepository>()),
  );
  getIt.registerFactory<SalesOrderFormBloc>(
    () => SalesOrderFormBloc(repository: getIt<SalesOrderRepository>()),
  );
  getIt.registerFactory<SalesInvoiceBloc>(
    () => SalesInvoiceBloc(
      invoiceRepository: getIt<SalesInvoiceRepository>(),
      paymentRepository: getIt<PaymentRepository>(),
      ledgerService: getIt<CustomerLedgerService>(),
      scannerService: getIt<PaymentDueScannerService>(),
    ),
  );
  getIt.registerFactory<ExpenseListBloc>(
    () => ExpenseListBloc(repository: getIt<ExpenseRepository>()),
  );
  getIt.registerFactory<ExpenseFormBloc>(
    () => ExpenseFormBloc(repository: getIt<ExpenseRepository>()),
  );
}
