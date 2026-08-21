import 'package:flutter/material.dart';

import '../dashboard/dashboard_surface.dart';

class JobWorkDetailSection extends StatelessWidget {
  const JobWorkDetailSection({
    required this.title,
    required this.icon,
    required this.child,
    this.action,
    this.collapsible = false,
    this.initiallyExpanded = false,
    this.subtitle,
    super.key,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;
  final bool collapsible;
  final bool initiallyExpanded;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final divider = Divider(
      height: 1,
      thickness: 1,
      color: theme.colorScheme.outline.withValues(alpha: 0.22),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DashboardSurfaceCard(
        compact: true,
        borderRadius: 14,
        padding: EdgeInsets.zero,
        child: collapsible
            ? Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: initiallyExpanded,
                  maintainState: true,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  tilePadding: const EdgeInsets.fromLTRB(16, 2, 12, 2),
                  childrenPadding: EdgeInsets.zero,
                  leading: _SectionIcon(icon: icon),
                  title: Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      letterSpacing: 0.1,
                    ),
                  ),
                  subtitle: subtitle == null
                      ? null
                      : Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  children: [
                    divider,
                    child,
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
                    child: Row(
                      children: [
                        _SectionIcon(icon: icon),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (action != null)
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: action!,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  divider,
                  child,
                ],
              ),
      ),
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 15,
        color: theme.colorScheme.primary,
      ),
    );
  }
}
