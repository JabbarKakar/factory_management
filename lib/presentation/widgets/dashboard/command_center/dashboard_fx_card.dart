import 'package:flutter/material.dart';

import 'dashboard_fx_theme.dart';

class DashboardFxCard extends StatefulWidget {
  const DashboardFxCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.glowColor,
    this.title,
    this.subtitle,
    this.trailing,
    this.expandChild = true,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glowColor;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool expandChild;

  @override
  State<DashboardFxCard> createState() => _DashboardFxCardState();
}

class _DashboardFxCardState extends State<DashboardFxCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.glowColor ?? DashboardFx.primary(context);

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: _ShimmerBorderPainter(
            progress: _shimmer.value,
            color: glow,
            radius: 16,
          ),
          child: child,
        );
      },
      child: _buildCard(context, glow),
    );
  }

  Widget _buildCard(BuildContext context, Color glow) {
    final isDark = DashboardFx.isDark(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DashboardFx.cardBg(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DashboardFx.cardBorder(context)),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? glow.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: isDark ? 18 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: widget.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize:
              widget.expandChild ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (widget.title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title!,
                          style: TextStyle(
                            color: DashboardFx.text(context),
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            letterSpacing: -0.2,
                          ),
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.subtitle!,
                            style: TextStyle(
                              color: DashboardFx.muted(context),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) widget.trailing!,
                ],
              ),
              const SizedBox(height: 10),
            ],
            if (widget.expandChild)
              Expanded(child: widget.child)
            else
              widget.child,
          ],
        ),
      ),
    );
  }
}

class _ShimmerBorderPainter extends CustomPainter {
  _ShimmerBorderPainter({
    required this.progress,
    required this.color,
    required this.radius,
  });

  final double progress;
  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    final path = Path()..addRRect(rrect);

    final metrics = path.computeMetrics().first;
    final totalLength = metrics.length;

    // Shimmer sweeps: bright head with a fading tail (25% of perimeter).
    final headPos = progress * totalLength;
    final tailAbsolute = 0.25 * totalLength;
    final tailPos = (headPos - tailAbsolute).clamp(0.0, totalLength);
    final extractLen = headPos - tailPos;
    if (extractLen <= 0) return;

    final shimmerPath = metrics.extractPath(tailPos, headPos);

    // Fade envelope: brightest at head, vanishes as animation completes.
    final opacity = Curves.easeOut.transform(
      (1 - progress).clamp(0.0, 1.0),
    );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = LinearGradient(
        colors: [
          color.withValues(alpha: 0),
          color.withValues(alpha: 0.7 * opacity),
        ],
      ).createShader(rect);

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(shimmerPath, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ShimmerBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
