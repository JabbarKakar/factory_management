import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../widgets/coming_soon_placeholder.dart';

class JobWorkPlaceholderScreen extends StatelessWidget {
  const JobWorkPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.jobWork)),
      body: const ComingSoonPlaceholder(
        title: AppStrings.jobWork,
        icon: Icons.content_cut,
        subtitle: 'Job work orders start in Sprint 3.',
      ),
    );
  }
}
