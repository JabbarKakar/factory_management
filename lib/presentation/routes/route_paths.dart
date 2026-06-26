import '../../domain/enums/notification_enums.dart';
import '../../domain/enums/raw_material_enums.dart';

abstract final class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String jobWork = '/job-work';
  static const String jobWorkAdd = '/job-work/add';

  static String jobWorkList({String? filter}) {
    if (filter == null || filter.isEmpty) return jobWork;
    return '$jobWork?filter=$filter';
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

  static String notificationsWithFilter(NotificationFilter filter) =>
      '$notifications?filter=${filter.name}';
}
