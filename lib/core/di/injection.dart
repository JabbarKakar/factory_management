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
import '../../blocs/labour/daily_attendance_bloc.dart';
import '../../blocs/labour/employee_detail_bloc.dart';
import '../../blocs/labour/employee_form_bloc.dart';
import '../../blocs/labour/employee_list_bloc.dart';
import '../../blocs/pl/pl_report_bloc.dart';
import '../../blocs/production/production_detail_bloc.dart';
import '../../blocs/production/production_form_bloc.dart';
import '../../blocs/production/production_list_bloc.dart';
import '../../blocs/quality/qc_detail_bloc.dart';
import '../../blocs/quality/qc_form_bloc.dart';
import '../../blocs/quality/qc_list_bloc.dart';
import '../../blocs/raw_material/raw_material_detail_bloc.dart';
import '../../blocs/raw_material/raw_material_list_bloc.dart';
import '../../blocs/raw_material/stock_movement_bloc.dart';
import '../../blocs/supplier/supplier_form_bloc.dart';
import '../../blocs/supplier/supplier_list_bloc.dart';
import '../../blocs/team/team_bloc.dart';
import '../../blocs/sales/sales_invoice_bloc.dart';
import '../../blocs/sales/sales_order_form_bloc.dart';
import '../../blocs/sales/sales_order_list_bloc.dart';
import '../../blocs/theme/theme_cubit.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/attendance_repository.dart';
import '../../data/repositories/delivery_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/equipment_repository.dart';
import '../../data/repositories/finished_goods_repository.dart';
import '../../data/repositories/job_work_invoice_repository.dart';
import '../../data/repositories/job_work_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/production_repository.dart';
import '../../data/repositories/quality_check_repository.dart';
import '../../data/repositories/raw_material_repository.dart';
import '../../data/repositories/sales_invoice_repository.dart';
import '../../data/repositories/sales_order_repository.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/repositories/theme_repository.dart';
import '../../data/services/customer_ledger_service.dart';
import '../../data/services/finished_goods_stock_service.dart';
import '../../data/services/pl_report_service.dart';
import '../../data/services/raw_material_stock_service.dart';
import '../../data/services/job_work_cleanup_service.dart';
import '../../data/services/notification_engine_service.dart';
import '../../data/services/operational_alert_scanner_service.dart';
import '../../data/services/dashboard_analytics_service.dart';
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
  getIt.registerLazySingleton<UserRepository>(UserRepository.new);
  getIt.registerLazySingleton<NotificationRepository>(NotificationRepository.new);
  getIt.registerLazySingleton<CustomerLedgerService>(
    () => CustomerLedgerService(
      customerRepository: getIt<CustomerRepository>(),
      jobWorkInvoiceRepository: getIt<JobWorkInvoiceRepository>(),
      salesInvoiceRepository: getIt<SalesInvoiceRepository>(),
    ),
  );
  getIt.registerLazySingleton<DashboardAnalyticsService>(
    () => DashboardAnalyticsService(),
  );
  getIt.registerLazySingleton<PaymentDueScannerService>(
    () => PaymentDueScannerService(
      jobWorkInvoiceRepository: getIt<JobWorkInvoiceRepository>(),
      salesInvoiceRepository: getIt<SalesInvoiceRepository>(),
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );
  getIt.registerLazySingleton<OperationalAlertScannerService>(
    () => OperationalAlertScannerService(
      rawMaterialRepository: getIt<RawMaterialRepository>(),
      finishedGoodsRepository: getIt<FinishedGoodsRepository>(),
      equipmentRepository: getIt<EquipmentRepository>(),
      deliveryRepository: getIt<DeliveryRepository>(),
      jobWorkRepository: getIt<JobWorkRepository>(),
      notificationRepository: getIt<NotificationRepository>(),
    ),
  );
  getIt.registerLazySingleton<NotificationEngineService>(
    () => NotificationEngineService(
      paymentDueScannerService: getIt<PaymentDueScannerService>(),
      operationalAlertScannerService: getIt<OperationalAlertScannerService>(),
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
  getIt.registerLazySingleton<PlReportService>(PlReportService.new);
  getIt.registerLazySingleton<ExpenseRepository>(ExpenseRepository.new);
  getIt.registerLazySingleton<SupplierRepository>(SupplierRepository.new);
  getIt.registerLazySingleton<EmployeeRepository>(EmployeeRepository.new);
  getIt.registerLazySingleton<AttendanceRepository>(AttendanceRepository.new);
  getIt.registerLazySingleton<DeliveryRepository>(
    () => DeliveryRepository(
      salesOrderRepository: getIt<SalesOrderRepository>(),
    ),
  );
  getIt.registerLazySingleton<EquipmentRepository>(EquipmentRepository.new);
  getIt.registerLazySingleton<QualityCheckRepository>(
    () => QualityCheckRepository(
      productionRepository: getIt<ProductionRepository>(),
      jobWorkRepository: getIt<JobWorkRepository>(),
    ),
  );
  getIt.registerLazySingleton<RawMaterialStockService>(
    RawMaterialStockService.new,
  );
  getIt.registerLazySingleton<FinishedGoodsStockService>(
    FinishedGoodsStockService.new,
  );
  getIt.registerLazySingleton<FinishedGoodsRepository>(
    () => FinishedGoodsRepository(
      stockService: getIt<FinishedGoodsStockService>(),
    ),
  );
  getIt.registerLazySingleton<RawMaterialRepository>(
    () => RawMaterialRepository(stockService: getIt<RawMaterialStockService>()),
  );
  getIt.registerLazySingleton<ProductionRepository>(
    () => ProductionRepository(
      stockService: getIt<RawMaterialStockService>(),
      finishedGoodsRepository: getIt<FinishedGoodsRepository>(),
    ),
  );
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
      engineService: getIt<NotificationEngineService>(),
    ),
  );
  getIt.registerFactory<TeamBloc>(
    () => TeamBloc(
      repository: getIt<UserRepository>(),
      employeeRepository: getIt<EmployeeRepository>(),
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
      expenseRepository: getIt<ExpenseRepository>(),
      rawMaterialRepository: getIt<RawMaterialRepository>(),
      employeeRepository: getIt<EmployeeRepository>(),
      attendanceRepository: getIt<AttendanceRepository>(),
      deliveryRepository: getIt<DeliveryRepository>(),
      equipmentRepository: getIt<EquipmentRepository>(),
      qualityCheckRepository: getIt<QualityCheckRepository>(),
      productionRepository: getIt<ProductionRepository>(),
      scannerService: getIt<PaymentDueScannerService>(),
      analyticsService: getIt<DashboardAnalyticsService>(),
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
    () => JobWorkListBloc(
      repository: getIt<JobWorkRepository>(),
      qualityCheckRepository: getIt<QualityCheckRepository>(),
    ),
  );
  getIt.registerFactory<JobWorkFormBloc>(
    () => JobWorkFormBloc(
      repository: getIt<JobWorkRepository>(),
      qualityCheckRepository: getIt<QualityCheckRepository>(),
      operationalAlertScannerService: getIt<OperationalAlertScannerService>(),
    ),
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
    () => SalesOrderFormBloc(
      repository: getIt<SalesOrderRepository>(),
      deliveryRepository: getIt<DeliveryRepository>(),
    ),
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
  getIt.registerFactory<PlReportBloc>(
    () => PlReportBloc(
      paymentRepository: getIt<PaymentRepository>(),
      expenseRepository: getIt<ExpenseRepository>(),
      reportService: getIt<PlReportService>(),
    ),
  );
  getIt.registerFactory<SupplierListBloc>(
    () => SupplierListBloc(repository: getIt<SupplierRepository>()),
  );
  getIt.registerFactory<SupplierFormBloc>(
    () => SupplierFormBloc(repository: getIt<SupplierRepository>()),
  );
  getIt.registerFactory<RawMaterialListBloc>(
    () => RawMaterialListBloc(repository: getIt<RawMaterialRepository>()),
  );
  getIt.registerFactory<RawMaterialDetailBloc>(
    () => RawMaterialDetailBloc(repository: getIt<RawMaterialRepository>()),
  );
  getIt.registerFactory<StockMovementBloc>(
    () => StockMovementBloc(repository: getIt<RawMaterialRepository>()),
  );
  getIt.registerFactory<ProductionListBloc>(
    () => ProductionListBloc(repository: getIt<ProductionRepository>()),
  );
  getIt.registerFactory<ProductionFormBloc>(
    () => ProductionFormBloc(repository: getIt<ProductionRepository>()),
  );
  getIt.registerFactory<ProductionDetailBloc>(
    () => ProductionDetailBloc(
      repository: getIt<ProductionRepository>(),
      qualityCheckRepository: getIt<QualityCheckRepository>(),
    ),
  );
  getIt.registerFactory<FinishedGoodsListBloc>(
    () => FinishedGoodsListBloc(repository: getIt<FinishedGoodsRepository>()),
  );
  getIt.registerFactory<FinishedGoodsDetailBloc>(
    () => FinishedGoodsDetailBloc(repository: getIt<FinishedGoodsRepository>()),
  );
  getIt.registerFactory<InventoryAdjustmentBloc>(
    () => InventoryAdjustmentBloc(repository: getIt<FinishedGoodsRepository>()),
  );
  getIt.registerFactory<EmployeeListBloc>(
    () => EmployeeListBloc(repository: getIt<EmployeeRepository>()),
  );
  getIt.registerFactory<EmployeeFormBloc>(
    () => EmployeeFormBloc(repository: getIt<EmployeeRepository>()),
  );
  getIt.registerFactory<EmployeeDetailBloc>(
    () => EmployeeDetailBloc(
      employeeRepository: getIt<EmployeeRepository>(),
      attendanceRepository: getIt<AttendanceRepository>(),
    ),
  );
  getIt.registerFactory<DailyAttendanceBloc>(
    () => DailyAttendanceBloc(
      employeeRepository: getIt<EmployeeRepository>(),
      attendanceRepository: getIt<AttendanceRepository>(),
    ),
  );
  getIt.registerFactory<DeliveryListBloc>(
    () => DeliveryListBloc(repository: getIt<DeliveryRepository>()),
  );
  getIt.registerFactory<DeliveryFormBloc>(
    () => DeliveryFormBloc(
      deliveryRepository: getIt<DeliveryRepository>(),
      employeeRepository: getIt<EmployeeRepository>(),
    ),
  );
  getIt.registerFactory<DeliveryDetailBloc>(
    () => DeliveryDetailBloc(repository: getIt<DeliveryRepository>()),
  );
  getIt.registerFactory<DeliveryConfirmBloc>(
    () => DeliveryConfirmBloc(repository: getIt<DeliveryRepository>()),
  );
  getIt.registerFactory<EquipmentListBloc>(
    () => EquipmentListBloc(repository: getIt<EquipmentRepository>()),
  );
  getIt.registerFactory<EquipmentFormBloc>(
    () => EquipmentFormBloc(repository: getIt<EquipmentRepository>()),
  );
  getIt.registerFactory<EquipmentDetailBloc>(
    () => EquipmentDetailBloc(repository: getIt<EquipmentRepository>()),
  );
  getIt.registerFactory<MaintenanceFormBloc>(
    () => MaintenanceFormBloc(repository: getIt<EquipmentRepository>()),
  );
  getIt.registerFactory<QcListBloc>(
    () => QcListBloc(repository: getIt<QualityCheckRepository>()),
  );
  getIt.registerFactory<QcFormBloc>(
    () => QcFormBloc(
      repository: getIt<QualityCheckRepository>(),
      jobWorkRepository: getIt<JobWorkRepository>(),
      operationalAlertScannerService: getIt<OperationalAlertScannerService>(),
    ),
  );
  getIt.registerFactory<QcDetailBloc>(
    () => QcDetailBloc(repository: getIt<QualityCheckRepository>()),
  );
}
