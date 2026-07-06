import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../widgets/coming_soon_placeholder.dart';

/// Placeholder — Sprint S32 implements owner registration.
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.signUp)),
      body: const ComingSoonPlaceholder(
        title: AppStrings.signUp,
        subtitle: AppStrings.signUpSubtitle,
        icon: Icons.app_registration_outlined,
      ),
    );
  }
}
