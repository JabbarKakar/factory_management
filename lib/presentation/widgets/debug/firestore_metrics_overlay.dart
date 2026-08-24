import 'package:flutter/material.dart';

import '../../../core/observability/firestore_metrics.dart';

/// Debug-only heads-up display of Firestore document reads and writes.
///
/// Wraps the app via `MaterialApp.builder`. Returns [child] untouched when
/// instrumentation is disabled, so release builds are unaffected.
class FirestoreMetricsOverlay extends StatefulWidget {
  const FirestoreMetricsOverlay({required this.child, super.key});

  final Widget child;

  @override
  State<FirestoreMetricsOverlay> createState() =>
      _FirestoreMetricsOverlayState();
}

class _FirestoreMetricsOverlayState extends State<FirestoreMetricsOverlay> {
  bool _expanded = false;
  Offset _position = const Offset(12, 90);

  @override
  Widget build(BuildContext context) {
    if (!FirestoreMetrics.enabled) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned(
          left: _position.dx,
          top: _position.dy,
          // A pan gesture rather than Draggable: this widget sits above the
          // Navigator via MaterialApp.builder, so there is no Overlay ancestor
          // for Draggable to render feedback into.
          child: GestureDetector(
            onPanUpdate: (details) {
              final size = MediaQuery.sizeOf(context);
              setState(() {
                _position = Offset(
                  (_position.dx + details.delta.dx)
                      .clamp(0.0, (size.width - 44).clamp(0.0, size.width)),
                  (_position.dy + details.delta.dy)
                      .clamp(0.0, (size.height - 44).clamp(0.0, size.height)),
                );
              });
            },
            child: ValueListenableBuilder<int>(
              valueListenable: FirestoreMetrics.instance.revision,
              builder: (context, _, _) {
                return _expanded ? _buildPanel() : _buildPill();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPill() {
    final metrics = FirestoreMetrics.instance;
    return _Surface(
      onTap: () => setState(() => _expanded = true),
      child: Text(
        'R ${_compact(metrics.totalServerReads)}  '
        'W ${_compact(metrics.totalWrites)}  '
        'L ${metrics.totalListenerAttaches}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  Widget _buildPanel() {
    final metrics = FirestoreMetrics.instance;
    final rows = metrics.breakdown;

    return _Surface(
      onTap: () => setState(() => _expanded = false),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300, maxHeight: 380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Firestore usage',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _Action(
                  icon: Icons.refresh,
                  label: 'Reset counters',
                  onTap: () => FirestoreMetrics.instance.reset(),
                ),
                const SizedBox(width: 4),
                _Action(
                  icon: Icons.close,
                  label: 'Collapse',
                  onTap: () => setState(() => _expanded = false),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'server reads ${metrics.totalServerReads} · '
              'cache ${metrics.totalCachedReads}\n'
              'writes ${metrics.totalWrites} · '
              'listeners ${metrics.totalListenerAttaches} · '
              'gets ${metrics.totalQueryExecutions}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
            // Reads with no server round-trip mean the backend is unreachable
            // and Firestore is answering from the local cache, which can be
            // stale data from a previously used host.
            if (metrics.totalServerReads == 0 && metrics.totalCachedReads > 0)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'CACHE ONLY — no server reached. Data may be stale.',
                  style: TextStyle(
                    color: Color(0xFFFFB74D),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const Divider(color: Colors.white24, height: 14),
            if (rows.isEmpty)
              const Text(
                'No Firestore activity yet.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 1),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              row.collection,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                          Text(
                            '${row.serverReads}r '
                            '${row.cachedReads}c '
                            '${row.writes}w '
                            '${row.listenerAttaches}L',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _compact(int value) {
    if (value < 1000) return '$value';
    if (value < 100000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '${(value / 1000).round()}k';
  }
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Semantics rather than Tooltip: Tooltip needs an Overlay ancestor, which
    // this subtree does not have (see the note on the pan gesture above).
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Icon(icon, size: 16, color: Colors.white70),
      ),
    );
  }
}
