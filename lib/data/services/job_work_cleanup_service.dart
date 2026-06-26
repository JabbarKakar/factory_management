import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/job_work_repository.dart';

/// One-time migration to remove job work orders whose customer was deleted
/// before cascade-delete was implemented.
class JobWorkCleanupService {
  JobWorkCleanupService({
    required JobWorkRepository jobWorkRepository,
    SharedPreferences? preferences,
  })  : _jobWorkRepository = jobWorkRepository,
        _preferences = preferences;

  static const _prefKeyPrefix = 'orphaned_job_work_cleanup_v1_';

  final JobWorkRepository _jobWorkRepository;
  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<int> runIfNeeded(String factoryId) async {
    final prefs = await _prefs;
    final prefKey = '$_prefKeyPrefix$factoryId';
    if (prefs.getBool(prefKey) == true) return 0;

    try {
      final deletedCount =
          await _jobWorkRepository.deleteOrphanedOrders(factoryId);
      await prefs.setBool(prefKey, true);
      return deletedCount;
    } catch (_) {
      return 0;
    }
  }
}
