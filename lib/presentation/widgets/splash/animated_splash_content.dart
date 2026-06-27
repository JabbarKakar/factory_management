import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../common/app_logo.dart';

/// Reusable animated splash body — pass in [Animation] values from a parent
/// [AnimationController] (or multiple controllers).
class AnimatedSplashContent extends StatelessWidget {
  const AnimatedSplashContent({
    required this.logoScale,
    required this.logoOpacity,
    super.key,
  });

  final Animation<double> logoScale;
  final Animation<double> logoOpacity;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: FadeTransition(
              opacity: logoOpacity,
              child: ScaleTransition(
                scale: logoScale,
                child: const AppLogo(
                  width: 280,
                  height: 280,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
