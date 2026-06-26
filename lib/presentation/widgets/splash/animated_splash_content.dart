import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// Reusable animated splash body — pass in [Animation] values from a parent
/// [AnimationController] (or multiple controllers).
class AnimatedSplashContent extends StatelessWidget {
  const AnimatedSplashContent({
    required this.logoScale,
    required this.logoOpacity,
    required this.titleOpacity,
    required this.titleSlide,
    required this.taglineOpacity,
    required this.taglineSlide,
    required this.accentPulse,
    super.key,
  });

  final Animation<double> logoScale;
  final Animation<double> logoOpacity;
  final Animation<double> titleOpacity;
  final Animation<Offset> titleSlide;
  final Animation<double> taglineOpacity;
  final Animation<Offset> taglineSlide;
  final Animation<double> accentPulse;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            Color(0xFF283593),
            Color(0xFF1A237E),
          ],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FadeTransition(
                  opacity: logoOpacity,
                  child: ScaleTransition(
                    scale: logoScale,
                    child: AnimatedBuilder(
                      animation: accentPulse,
                      builder: (context, child) {
                        return Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(
                              alpha: 0.08 + (accentPulse.value * 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(
                                  alpha: 0.15 + (accentPulse.value * 0.15),
                                ),
                                blurRadius: 32,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: child,
                        );
                      },
                      child: const Icon(
                        Icons.factory_rounded,
                        size: 72,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                FadeTransition(
                  opacity: titleOpacity,
                  child: SlideTransition(
                    position: titleSlide,
                    child: Text(
                      AppStrings.appName,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FadeTransition(
                  opacity: taglineOpacity,
                  child: SlideTransition(
                    position: taglineSlide,
                    child: Text(
                      AppStrings.appFullName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                      textAlign: TextAlign.center,
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
}
