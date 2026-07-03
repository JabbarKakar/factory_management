import 'package:flutter/material.dart';

/// A single entry in a list tile's compact ⋮ options menu.
class TileMenuAction {
  const TileMenuAction({
    required this.label,
    required this.icon,
    required this.onSelected,
    this.destructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onSelected;
  final bool destructive;
}

/// Compact ⋮ button that opens a tight dropdown of [TileMenuAction]s.
///
/// Destructive actions are tinted red and separated with a divider.
class TileOptionsButton extends StatelessWidget {
  const TileOptionsButton({
    required this.actions,
    this.isBusy = false,
    super.key,
  });

  final List<TileMenuAction> actions;
  final bool isBusy;

  Future<void> _openMenu(BuildContext context) async {
    final theme = Theme.of(context);
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenSize = MediaQuery.sizeOf(context);

    const menuWidth = 168.0;
    var left = offset.dx + size.width - menuWidth;
    final top = offset.dy + size.height + 1;
    left = left.clamp(8.0, screenSize.width - menuWidth - 8.0);

    final selected = await showGeneralDialog<TileMenuAction>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Actions',
      barrierColor: Colors.transparent,
      transitionDuration: Duration.zero,
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        final rows = <Widget>[];
        for (final action in actions) {
          if (action.destructive && rows.isNotEmpty) {
            rows.add(
              Divider(
                height: 1,
                thickness: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.18),
              ),
            );
          }
          final color = action.destructive
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface;
          rows.add(
            InkWell(
              onTap: () => Navigator.of(dialogContext).pop(action),
              child: SizedBox(
                width: menuWidth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Icon(action.icon, size: 16, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          action.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              child: Material(
                elevation: 2,
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: rows,
                ),
              ),
            ),
          ],
        );
      },
    );

    selected?.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    if (isBusy) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: iconColor,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _openMenu(context),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
        child: Icon(
          Icons.more_vert_rounded,
          size: 20,
          color: iconColor,
        ),
      ),
    );
  }
}
