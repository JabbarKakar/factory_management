import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../widgets/coming_soon_placeholder.dart';

/// Placeholder — Sprint S33 implements factory profile editor.
class FactorySettingsScreen extends StatelessWidget {
  const FactorySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.factorySettings)),
      body: const ComingSoonPlaceholder(
        title: AppStrings.factorySettings,
        subtitle: AppStrings.factorySettingsSubtitle,
        icon: Icons.business_outlined,
      ),
    );
  }
}
