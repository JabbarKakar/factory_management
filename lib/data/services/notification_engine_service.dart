import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'operational_alert_scanner_service.dart';
import 'payment_due_scanner_service.dart';

class NotificationEngineService {
  NotificationEngineService({
    required PaymentDueScannerService paymentDueScannerService,
    required OperationalAlertScannerService operationalAlertScannerService,
    SharedPreferences? preferences,
  })  : _paymentDueScannerService = paymentDueScannerService,
        _operationalAlertScannerService = operationalAlertScannerService,
        _preferences = preferences;

  static const _prefKeyPrefix = 'notification_engine_scan_';

  final PaymentDueScannerService _paymentDueScannerService;
  final OperationalAlertScannerService _operationalAlertScannerService;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<int> runIfNeeded(String factoryId) async {
    final prefs = await _prefs;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (prefs.getString('$_prefKeyPrefix$factoryId') == today) {
      return 0;
    }

    final created = await scan(factoryId);
    await prefs.setString('$_prefKeyPrefix$factoryId', today);
    return created;
  }

  Future<int> scan(String factoryId) async {
    final paymentCreated = await _paymentDueScannerService.scan(factoryId);
    final operationalCreated =
        await _operationalAlertScannerService.scan(factoryId);
    return paymentCreated + operationalCreated;
  }
}
