abstract final class RoutePaths {
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String dashboard = '/dashboard';
  static const String jobWork = '/job-work';
  static const String jobWorkAdd = '/job-work/add';

  static String jobWorkDetail(String id) => '/job-work/$id';

  static String jobWorkEdit(String id) => '/job-work/$id/edit';

  static String jobWorkRecordOutput(String id) => '/job-work/$id/record-output';
  static const String customers = '/customers';
  static const String customersAdd = '/customers/add';

  static String customerDetail(String id) => '/customers/$id';

  static String customerEdit(String id) => '/customers/$id/edit';
  static const String sales = '/sales';
  static const String more = '/more';
}
