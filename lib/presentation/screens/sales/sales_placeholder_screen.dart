import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../widgets/coming_soon_placeholder.dart';

class SalesPlaceholderScreen extends StatelessWidget {
  const SalesPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.sales)),
      body: ComingSoonPlaceholder(
        title: AppStrings.sales,
        icon: Icons.shopping_cart,
        subtitle: '${AppStrings.comingSoon} (${AppStrings.phase2}).',
      ),
    );
  }
}
