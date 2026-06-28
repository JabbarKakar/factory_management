import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../common/app_logo.dart';

class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          const AppLogo(height: 72, showBackground: true),
          const SizedBox(height: 16),
          Text(
            AppStrings.appFullName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppStrings.loginSubtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
