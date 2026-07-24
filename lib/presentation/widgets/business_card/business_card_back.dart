import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../domain/entities/factory_profile.dart';

/// Back side of the Onyx & Gold Business Card with high-contrast text.
class BusinessCardBack extends StatelessWidget {
  const BusinessCardBack({
    super.key,
    required this.profile,
    this.width,
    this.height,
  });

  final FactoryProfile profile;
  final double? width;
  final double? height;

  static const Color darkBg = Color(0xFF1E1E1E);
  static const Color darkBgGradient = Color(0xFF141414);
  static const Color goldAccent = Color(0xFFF5D061);
  static const Color goldLight = Color(0xFFFFF1BD);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color warmGray = Color(0xFFCCCCCC);

  String _generateQrData() {
    final mapsUrl = profile.contact.googleMapsLink?.trim();
    final ownerName = profile.ownership.ownerName?.trim().isNotEmpty == true
        ? profile.ownership.ownerName!.trim()
        : (profile.ownerName?.trim().isNotEmpty == true
            ? profile.ownerName!.trim()
            : profile.identity.businessName);

    final bizName = profile.identity.businessName.isNotEmpty
        ? profile.identity.businessName
        : profile.name;

    final phone = profile.contact.phone.trim().isNotEmpty
        ? profile.contact.phone.trim()
        : (profile.contact.whatsapp?.trim() ?? '');

    final email = profile.contact.email?.trim() ?? '';
    final address = profile.contact.fullAddress;

    final sb = StringBuffer();
    sb.writeln('BEGIN:VCARD');
    sb.writeln('VERSION:3.0');
    sb.writeln('FN:$ownerName');
    sb.writeln('ORG:$bizName');
    if (phone.isNotEmpty) sb.writeln('TEL;TYPE=CELL:$phone');
    if (email.isNotEmpty) sb.writeln('EMAIL:$email');
    if (address.isNotEmpty) sb.writeln('ADR:;;$address;;;;');
    if (mapsUrl != null && mapsUrl.isNotEmpty) sb.writeln('URL:$mapsUrl');
    sb.write('END:VCARD');
    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ownerName = (profile.ownership.ownerName != null &&
            profile.ownership.ownerName!.trim().isNotEmpty)
        ? profile.ownership.ownerName!.trim()
        : (profile.ownerName != null && profile.ownerName!.trim().isNotEmpty
            ? profile.ownerName!.trim()
            : 'JABBAR KAKAR');

    const role = 'Owner / Managing Director';

    final phone = profile.contact.phone.trim().isNotEmpty
        ? profile.contact.phone.trim()
        : (profile.contact.whatsapp?.trim() ?? 'N/A');

    final email = profile.contact.email?.trim();
    final address = profile.contact.fullAddress.isNotEmpty
        ? profile.contact.fullAddress
        : 'Industrial Estate Area';

    final ntn = profile.legal.ntn?.trim();
    final strn = profile.legal.strn?.trim();

    final qrData = _generateQrData();

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
              // Top Gold Accent Stripe
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 3.5,
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

              // Content Padding
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Section: Owner Name & Title
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ownerName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: pureWhite,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black87,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: goldAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Business Initials Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: goldAccent.withValues(alpha: 0.6),
                              width: 1.0,
                            ),
                            color: goldAccent.withValues(alpha: 0.12),
                          ),
                          child: Text(
                            profile.identity.businessName.isNotEmpty
                                ? profile.identity.businessName
                                : 'FACTORY',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: goldAccent,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Container(
                      height: 0.8,
                      color: goldAccent.withValues(alpha: 0.35),
                    ),

                    const SizedBox(height: 10),

                    // Body Grid (2 Columns)
                    Expanded(
                      child: Row(
                        children: [
                          // Left Column: Contact Info
                          Expanded(
                            flex: 12,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildContactItem(
                                  Icons.phone_rounded,
                                  phone,
                                ),
                                if (email != null && email.isNotEmpty)
                                  _buildContactItem(
                                    Icons.email_rounded,
                                    email,
                                  ),
                                _buildContactItem(
                                  Icons.location_on_rounded,
                                  address,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Vertical Separator Line
                          Container(
                            width: 0.8,
                            color: goldAccent.withValues(alpha: 0.3),
                          ),

                          const SizedBox(width: 8),

                          // Right Column: Credentials (NTN/STRN) & QR Code
                          Expanded(
                            flex: 9,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Tax Info
                                Column(
                                  children: [
                                    _buildTaxRow('NTN:', ntn ?? 'N/A'),
                                    const SizedBox(height: 3),
                                    _buildTaxRow('STRN:', strn ?? 'N/A'),
                                  ],
                                ),

                                const Spacer(),

                                // QR Code Widget
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.4),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: QrImageView(
                                    data: qrData,
                                    version: QrVersions.auto,
                                    size: 50,
                                    gapless: true,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),

                                const Spacer(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 13,
          color: goldAccent,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: pureWhite,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaxRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: goldAccent,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: pureWhite,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
