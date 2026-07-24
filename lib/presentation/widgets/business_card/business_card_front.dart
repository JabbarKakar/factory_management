import 'package:flutter/material.dart';
import '../../../domain/entities/factory_profile.dart';

/// Front side of the Onyx & Gold Business Card.
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
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF3E5AB);
  static const Color warmGray = Color(0xFFA0A0A0);

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
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF252525),
              darkBg,
              darkBgGradient,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color: goldAccent.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            children: [
              // Subtle background geometric accents
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: goldAccent.withValues(alpha: 0.06),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: goldAccent.withValues(alpha: 0.08),
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
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: goldAccent, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: goldAccent.withValues(alpha: 0.2),
                              blurRadius: 8,
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

                    const SizedBox(height: 12),

                    // Business Name
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        businessName.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: goldAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(0, 1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Gold decorative line divider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 1,
                          color: goldAccent.withValues(alpha: 0.5),
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
                          width: 24,
                          height: 1,
                          color: goldAccent.withValues(alpha: 0.5),
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
                        color: warmGray,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),

                    if (establishedYear != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'EST. $establishedYear',
                        style: TextStyle(
                          color: goldAccent.withValues(alpha: 0.7),
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
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
                  height: 3.5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF997A15),
                        goldAccent,
                        goldLight,
                        goldAccent,
                        Color(0xFF997A15),
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
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goldAccent.withValues(alpha: 0.2),
            goldAccent.withValues(alpha: 0.05),
          ],
        ),
        border: Border.all(color: goldAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: goldAccent.withValues(alpha: 0.15),
            blurRadius: 6,
          ),
        ],
      ),
      child: Center(
        child: Text(
          _getInitials(businessName),
          style: const TextStyle(
            color: goldAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}
