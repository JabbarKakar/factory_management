import 'package:flutter/material.dart';

import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/team_invite.dart';
import '../dashboard/dashboard_surface.dart';
import 'factory_role_badge.dart';

class PendingInvitesCard extends StatelessWidget {
  const PendingInvitesCard({
    required this.invites,
    required this.enabled,
    required this.onRevoke,
    super.key,
  });

  final List<TeamInvite> invites;
  final bool enabled;
  final ValueChanged<TeamInvite> onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DashboardSurfaceCard(
      compact: true,
      borderRadius: 14,
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.mark_email_unread_outlined,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '${AppStrings.pendingInvites} (${invites.length})',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final invite in invites)
            _PendingInviteRow(
              invite: invite,
              enabled: enabled,
              onRevoke: () => onRevoke(invite),
            ),
        ],
      ),
    );
  }
}

class _PendingInviteRow extends StatelessWidget {
  const _PendingInviteRow({
    required this.invite,
    required this.enabled,
    required this.onRevoke,
  });

  final TeamInvite invite;
  final bool enabled;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppStrings.inviteExpiresPrefix} ${_formatDate(invite.expiresAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          FactoryRoleBadge(role: invite.role, compact: true),
          IconButton(
            onPressed: enabled ? onRevoke : null,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            tooltip: AppStrings.revokeInvite,
            visualDensity: VisualDensity.compact,
            color: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final d = date.toLocal();
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
