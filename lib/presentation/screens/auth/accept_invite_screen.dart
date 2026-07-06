import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../widgets/coming_soon_placeholder.dart';

/// Placeholder — Sprint S34 implements invite acceptance.
class AcceptInviteScreen extends StatelessWidget {
  const AcceptInviteScreen({this.inviteId, super.key});

  final String? inviteId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.acceptInvite)),
      body: ComingSoonPlaceholder(
        title: AppStrings.acceptInvite,
        subtitle: inviteId == null || inviteId!.isEmpty
            ? AppStrings.acceptInviteSubtitle
            : '${AppStrings.acceptInviteSubtitle}\nInvite: $inviteId',
        icon: Icons.mail_outline,
      ),
    );
  }
}
