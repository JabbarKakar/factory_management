import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    this.width,
    this.height = 120,
    this.borderRadius = 20,
    this.showBackground = false,
    super.key,
  });

  final double? width;
  final double height;
  final double borderRadius;
  final bool showBackground;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppAssets.logo,
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );

    if (!showBackground) return image;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: EdgeInsets.all(height * 0.08),
        child: image,
      ),
    );
  }
}
