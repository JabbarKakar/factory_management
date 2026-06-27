import '../../domain/enums/delivery_enums.dart';
import '../../domain/enums/equipment_enums.dart';
import '../../domain/enums/inventory_enums.dart';
import '../../domain/enums/job_work_enums.dart';
import '../../domain/enums/notification_enums.dart';
import '../../domain/enums/production_enums.dart';
import '../../domain/enums/quality_enums.dart';
import '../../domain/enums/raw_material_enums.dart';

abstract final class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String jobWork = '/job-work';
  static const String jobWorkAdd = '/job-work/add';

  static String jobWorkList({JobWorkListStageFilter? filter}) {
    if (filter == null || filter == JobWorkListStageFilter.all) {
      return jobWork;
    }
    return '$jobWork?filter=${filter.name}';
  }

  static String jobWorkDetail(String id) => '/job-work/$id';

  static String jobWorkEdit(String id) => '/job-work/$id/edit';

  static String jobWorkRecordOutput(String id) => '/job-work/$id/record-output';

  static String jobWorkInvoice(String jobWorkId) => '/job-work/$jobWorkId/invoice';

  static String recordPayment(String invoiceId) =>
      '/job-work/invoices/$invoiceId/payment';
  static const String customers = '/customers';
  static const String customersAdd = '/customers/add';

  static String customerDetail(String id) => '/customers/$id';

  static String customerEdit(String id) => '/customers/$id/edit';
  static const String sales = '/sales';
  static const String salesAdd = '/sales/add';

  static String salesList({String? filter}) {
    if (filter == null || filter.isEmpty) return sales;
    return '$sales?filter=$filter';
  }

  static String salesDetail(String id) => '/sales/$id';

  static String salesEdit(String id) => '/sales/$id/edit';

  static String salesInvoice(String salesOrderId) => '/sales/$salesOrderId/invoice';

  static String salesRecordPayment(String invoiceId) =>
      '/sales/invoices/$invoiceId/payment';
  static const String more = '/more';
  static const String accessDenied = '/access-denied';
  static const String team = '/settings/team';
  static const String notifications = '/notifications';
  static const String expenses = '/expenses';
  static const String expensesAdd = '/expenses/add';

  static String expensesAddForSupplier({
    required String supplierId,
    String? payeeName,
  }) {
    final query = <String, String>{'supplierId': supplierId};
    if (payeeName != null && payeeName.trim().isNotEmpty) {
      query['payee'] = payeeName.trim();
    }
    return Uri(path: expensesAdd, queryParameters: query).toString();
  }

  static String expenseEdit(String id) => '/expenses/$id/edit';
  static const String plReport = '/reports/pl';
  static const String suppliers = '/suppliers';
  static const String suppliersAdd = '/suppliers/add';

  static String supplierDetail(String id) => '/suppliers/$id';

  static String supplierEdit(String id) => '/suppliers/$id/edit';
  static const String rawMaterials = '/raw-materials';

  static String rawMaterialsList({RawMaterialListFilter? filter}) {
    if (filter == null || filter == RawMaterialListFilter.all) {
      return rawMaterials;
    }
    return '$rawMaterials?filter=${filter.name}';
  }

  static String rawMaterialDetail(String materialType) =>
      '/raw-materials/$materialType';

  static String rawMaterialStockIn(
    String materialType, {
    String? supplierId,
  }) {
    final query = <String, String>{};
    if (supplierId != null && supplierId.isNotEmpty) {
      query['supplierId'] = supplierId;
    }
    return Uri(
      path: '/raw-materials/$materialType/stock-in',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  static String rawMaterialStockOut(String materialType) =>
      '/raw-materials/$materialType/stock-out';

  static const String production = '/production';
  static const String productionAdd = '/production/add';

  static String productionDetail(String id) => '/production/$id';

  static String productionList({ProductionListFilter? filter}) {
    if (filter == null || filter == ProductionListFilter.all) {
      return production;
    }
    return '$production?filter=${filter.name}';
  }

  static const String finishedGoods = '/finished-goods';

  static String finishedGoodsList({FinishedGoodsListFilter? filter}) {
    if (filter == null || filter == FinishedGoodsListFilter.all) {
      return finishedGoods;
    }
    return '$finishedGoods?filter=${filter.name}';
  }

  static String finishedGoodDetail(String id) => '/finished-goods/$id';

  static String finishedGoodAdjustIn(String id) =>
      '/finished-goods/$id/adjust-in';

  static String finishedGoodAdjustOut(String id) =>
      '/finished-goods/$id/adjust-out';

  static const String employees = '/employees';
  static const String employeesAdd = '/employees/add';
  static const String attendance = '/attendance';

  static String employeeDetail(String id) => '/employees/$id';

  static String employeeEdit(String id) => '/employees/$id/edit';

  static String attendanceForDate(DateTime date) {
    final key =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$attendance?date=$key';
  }

  static const String deliveries = '/deliveries';
  static const String deliveriesAdd = '/deliveries/add';

  static String deliveriesAddForOrder(String salesOrderId) =>
      '$deliveriesAdd?salesOrderId=$salesOrderId';

  static String deliveryDetail(String id) => '/deliveries/$id';

  static String deliveryChallan(String id) => '/deliveries/$id/challan';

  static String deliveryConfirm(String id) => '/deliveries/$id/confirm';

  static String deliveriesList({DeliveryListFilter? filter}) {
    if (filter == null || filter == DeliveryListFilter.all) {
      return deliveries;
    }
    return '$deliveries?filter=${filter.name}';
  }

  static const String equipment = '/equipment';
  static const String equipmentAdd = '/equipment/add';

  static String equipmentDetail(String id) => '/equipment/$id';

  static String equipmentEdit(String id) => '/equipment/$id/edit';

  static String equipmentRecordMaintenance(String id) =>
      '/equipment/$id/maintenance';

  static String equipmentList({EquipmentListFilter? filter}) {
    if (filter == null || filter == EquipmentListFilter.all) {
      return equipment;
    }
    return '$equipment?filter=${filter.name}';
  }

  static const String qualityChecks = '/quality-checks';
  static const String qualityChecksAdd = '/quality-checks/add';

  static String qualityCheckDetail(String id) => '/quality-checks/$id';

  static String qualityChecksAddForReference({
    required QcReferenceType refType,
    required String referenceId,
  }) =>
      '$qualityChecksAdd?refType=${refType.name}&referenceId=$referenceId';

  static String qualityChecksList({QcListFilter? filter}) {
    if (filter == null || filter == QcListFilter.all) {
      return qualityChecks;
    }
    return '$qualityChecks?filter=${filter.name}';
  }

  static String notificationsWithFilter(NotificationFilter filter) =>
      '$notifications?filter=${filter.name}';
}
