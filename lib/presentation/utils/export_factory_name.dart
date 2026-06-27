import 'package:flutter/widgets.dart';

import '../../core/constants/app_strings.dart';
import '../../core/di/injection.dart';
import '../../data/services/factory_display_service.dart';
import '../utils/auth_context.dart';

Future<String> resolveExportFactoryName(BuildContext context) async {
  final factoryId = readFactoryId(context);
  if (factoryId == null) return AppStrings.appName;
  return getIt<FactoryDisplayService>().resolveName(factoryId);
}
