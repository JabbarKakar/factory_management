import 'package:flutter/material.dart';
import '../../../domain/entities/factory_profile.dart';

/// Front side of the Onyx & Gold Business Card with high-contrast text.
class BusinessCardFront extends StatelessWidget {
  const BusinessCardFront({
    super.key,
    required this.profile,
    this.width,
    this.height,
  });

  final FactoryProfile profile;
  final double? width;
  final double? height;

  static const Color darkBg = Color(0xFF1E1E1E);
  static const Color darkBgGradient = Color(0xFF121212);
  static const Color goldAccent = Color(0xFFF5D061);
  static const Color goldLight = Color(0xFFFFF1BD);
  static const Color warmWhite = Color(0xFFF0F0F0);

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'FM';
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.substring(0, trimmed.length >= 2 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final businessName = profile.identity.businessName.isNotEmpty
        ? profile.identity.businessName
        : (profile.name.isNotEmpty ? profile.name : 'FACTORY MANAGEMENT');

    final tagline = (profile.identity.tagline != null &&
            profile.identity.tagline!.trim().isNotEmpty)
        ? profile.identity.tagline!.trim()
        : (profile.identity.legalName != null &&
                profile.identity.legalName!.trim().isNotEmpty
            ? profile.identity.legalName!.trim()
            : 'NATURAL STONE PROCESSING & EXPORT');

    final logoUrl = profile.identity.logoUrl?.trim();
    final establishedYear = profile.identity.establishedYear;

    return AspectRatio(
      aspectRatio: 3.5 / 2.0,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF282828),
              darkBg,
              darkBgGradient,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: goldAccent.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              // Subtle background geometric accents
              Positioned(
                top: -45,
                right: -45,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: goldAccent.withValues(alpha: 0.08),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -25,
                right: -25,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: goldAccent.withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                ),
              ),

              // Main Card Content
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Spacer(),
                    // Logo or Monogram
                    if (logoUrl != null && logoUrl.isNotEmpty)
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: goldAccent, width: 1.8),
                          boxShadow: [
                            BoxShadow(
                              color: goldAccent.withValues(alpha: 0.25),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildMonogram(businessName),
                          ),
                        ),
                      )
                    else
                      _buildMonogram(businessName),

                    const SizedBox(height: 10),

                    // Business Name
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        businessName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: goldAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(0, 1.5),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Gold decorative line divider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 32,
                          height: 1.2,
                          color: goldAccent.withValues(alpha: 0.6),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.square,
                            size: 4,
                            color: goldAccent,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 1.2,
                          color: goldAccent.withValues(alpha: 0.6),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Tagline / Subtitle
                    Text(
                      tagline.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: warmWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            offset: Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),

                    if (establishedYear != null) ...[
                      const SizedBox(height: 5),
                      Text(
                        'EST. $establishedYear',
                        style: TextStyle(
                          color: goldAccent.withValues(alpha: 0.9),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],

                    const Spacer(),
                  ],
                ),
              ),

              // Bottom Gold Accent Line
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 4.0,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFB8860B),
                        goldAccent,
                        goldLight,
                        goldAccent,
                        Color(0xFFB8860B),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonogram(String businessName) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goldAccent.withValues(alpha: 0.25),
            goldAccent.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: goldAccent, width: 1.8),
        boxShadow: [
          BoxShadow(
            color: goldAccent.withValues(alpha: 0.2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitials(businessName),
          style: const TextStyle(
            color: goldAccent,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
