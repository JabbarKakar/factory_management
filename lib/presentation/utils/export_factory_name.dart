import 'package:flutter/widgets.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../data/repositories/factory_repository.dart';
import '../../data/services/factory_display_service.dart';
import '../../domain/entities/factory_profile.dart';
import '../utils/auth_context.dart';

Future<String> resolveExportFactoryName(BuildContext context) async {
  final factoryId = readFactoryId(context);
  if (factoryId == null) return AppStrings.appName;
  return getIt<FactoryDisplayService>().resolveName(factoryId);
}

Future<FactoryProfile?> resolveExportFactoryProfile(
  BuildContext context, [
  String? targetFactoryId,
]) async {
  final factoryId = targetFactoryId ?? readFactoryId(context);
  if (factoryId == null || factoryId.isEmpty) return null;
  return getIt<FactoryRepository>().getFactory(factoryId);
}
