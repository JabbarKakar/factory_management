import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/team_invite.dart';

/// Shown right after an invite is created so the owner can copy/share the code.
class InviteCodeDialog extends StatelessWidget {
  const InviteCodeDialog({required this.invite, super.key});

  final TeamInvite invite;

  static Future<void> show(BuildContext context, TeamInvite invite) {
    return showDialog<void>(
      context: context,
      builder: (_) => InviteCodeDialog(invite: invite),
    );
  }

  String _shareMessage() {
    return 'You have been invited to join a factory on MFMS.\n\n'
        'Email: ${invite.email}\n'
        'Invite code: ${invite.id}\n\n'
        'Open the app, choose "Accept Invite", and enter this code to join. '
        'The code expires in 7 days.';
  }

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: invite.id));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.inviteCopied)),
    );
  }

  Future<void> _share() async {
    await SharePlus.instance.share(ShareParams(text: _shareMessage()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text(AppStrings.inviteCreatedTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.inviteCreatedBody,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _CodeBox(code: invite.id, email: invite.email),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () => _copy(context),
          icon: const Icon(Icons.copy_rounded, size: 18),
          label: const Text(AppStrings.copyCode),
        ),
        FilledButton.icon(
          onPressed: _share,
          icon: const Icon(Icons.share_outlined, size: 18),
          label: const Text(AppStrings.shareInvite),
        ),
      ],
    );
  }
}

class _CodeBox extends StatelessWidget {
  const _CodeBox({required this.code, required this.email});

  final String code;
  final String email;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            email,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          SelectableText(
            code,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
