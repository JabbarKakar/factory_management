import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../widgets/coming_soon_placeholder.dart';

class CustomersPlaceholderScreen extends StatelessWidget {
  const CustomersPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.customers)),
      body: const ComingSoonPlaceholder(
        title: AppStrings.customers,
        icon: Icons.people,
        subtitle: 'Customer management starts in Sprint 2.',
      ),
    );
  }
}
