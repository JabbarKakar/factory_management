import '../../core/constants/app_strings.dart';
import '../repositories/factory_repository.dart';

class FactoryDisplayService {
  FactoryDisplayService({required FactoryRepository repository})
      : _repository = repository;

  final FactoryRepository _repository;
  final Map<String, String> _cache = {};

  Future<String> resolveName(String factoryId) async {
    final cached = _cache[factoryId];
    if (cached != null) return cached;

    final profile = await _repository.getFactory(factoryId);
    final name = profile?.name.trim();
    final resolved =
        name != null && name.isNotEmpty ? name : AppStrings.appName;
    _cache[factoryId] = resolved;
    return resolved;
  }
}
