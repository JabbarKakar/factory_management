import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/entities/factory_profile.dart';
import 'business_card_front.dart';
import 'business_card_back.dart';

/// Interactive preview widget rendering Front & Back sides of the card
/// with a 3D flip animation and theme-adaptive toggle controls.
class BusinessCardPreviewWidget extends StatefulWidget {
  const BusinessCardPreviewWidget({
    super.key,
    required this.profile,
    this.width = 440,
  });

  final FactoryProfile profile;
  final double width;

  @override
  State<BusinessCardPreviewWidget> createState() =>
      _BusinessCardPreviewWidgetState();
}

class _BusinessCardPreviewWidgetState extends State<BusinessCardPreviewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  bool _showFront = true;

  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldDark = Color(0xFFB8860B);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _animation.addListener(() {
      setState(() {
        _showFront = _animation.value < 0.5;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _flipCard() {
    if (_controller.isAnimating) return;
    if (_showFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _showSide(bool front) {
    if (_controller.isAnimating) return;
    if (front && !_showFront) {
      _controller.reverse();
    } else if (!front && _showFront) {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = math.min(widget.width, screenWidth - 32.0);
    final height = cardWidth * (2.0 / 3.5);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final toggleBg = isDark ? const Color(0xFF242424) : Colors.grey.shade200;
    final hintTextColor = isDark ? Colors.white70 : Colors.grey.shade800;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Side Selector Toggle
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: toggleBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: goldAccent.withValues(alpha: isDark ? 0.5 : 0.7),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.4)
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton(
                label: 'FRONT',
                icon: Icons.subtitles_rounded,
                isSelected: _showFront,
                isDark: isDark,
                onTap: () => _showSide(true),
              ),
              const SizedBox(width: 6),
              _buildToggleButton(
                label: 'BACK',
                icon: Icons.qr_code_2_rounded,
                isSelected: !_showFront,
                isDark: isDark,
                onTap: () => _showSide(false),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Interactive 3D Flip Card
        GestureDetector(
          onTap: _flipCard,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              final angle = _animation.value * math.pi;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // Perspective
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: Container(
                  width: cardWidth,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: _showFront
                      ? BusinessCardFront(
                          profile: widget.profile,
                          width: cardWidth,
                          height: height,
                        )
                      : Transform(
                          transform: Matrix4.identity()..rotateY(math.pi),
                          alignment: Alignment.center,
                          child: BusinessCardBack(
                            profile: widget.profile,
                            width: cardWidth,
                            height: height,
                          ),
                        ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // Hint under card
        InkWell(
          onTap: _flipCard,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.flip_rounded,
                  size: 18,
                  color: goldDark,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tap card to flip (${_showFront ? "Front" : "Back"})',
                  style: TextStyle(
                    color: hintTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? const Color(0xFF141414)
                  : (isDark ? Colors.white70 : Colors.grey.shade800),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF141414)
                    : (isDark ? Colors.white70 : Colors.grey.shade800),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
