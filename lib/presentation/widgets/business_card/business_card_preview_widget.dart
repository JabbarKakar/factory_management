import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/entities/factory_profile.dart';
import 'business_card_front.dart';
import 'business_card_back.dart';

/// Interactive preview widget rendering Front & Back sides of the card
/// with a 3D flip animation and toggle buttons.
class BusinessCardPreviewWidget extends StatefulWidget {
  const BusinessCardPreviewWidget({
    super.key,
    required this.profile,
    this.width = 340,
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
  static const Color darkBg = Color(0xFF1E1E1E);

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
    final height = widget.width * (2.0 / 3.5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Side Selector Toggle
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: darkBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: goldAccent.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildToggleButton(
                label: 'FRONT',
                icon: Icons.subtitles_rounded,
                isSelected: _showFront,
                onTap: () => _showSide(true),
              ),
              const SizedBox(width: 4),
              _buildToggleButton(
                label: 'BACK',
                icon: Icons.qr_code_2_rounded,
                isSelected: !_showFront,
                onTap: () => _showSide(false),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

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
                child: SizedBox(
                  width: widget.width,
                  height: height,
                  child: _showFront
                      ? BusinessCardFront(
                          profile: widget.profile,
                          width: widget.width,
                          height: height,
                        )
                      : Transform(
                          transform: Matrix4.identity()..rotateY(math.pi),
                          alignment: Alignment.center,
                          child: BusinessCardBack(
                            profile: widget.profile,
                            width: widget.width,
                            height: height,
                          ),
                        ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // Hint under card
        InkWell(
          onTap: _flipCard,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.flip_rounded,
                  size: 16,
                  color: goldAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Tap card to flip (${_showFront ? "Front" : "Back"})',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? goldAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: goldAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? darkBg : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? darkBg : Colors.white70,
                fontSize: 11,
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
