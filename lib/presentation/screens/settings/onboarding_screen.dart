import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../widgets/coming_soon_placeholder.dart';

/// Placeholder — Sprint S33 implements onboarding gate routing.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.onboarding)),
      body: const ComingSoonPlaceholder(
        title: AppStrings.onboarding,
        subtitle: AppStrings.onboardingSubtitle,
        icon: Icons.factory_outlined,
      ),
    );
  }
}
