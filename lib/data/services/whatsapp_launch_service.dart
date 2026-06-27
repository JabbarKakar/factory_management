import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/phone_utils.dart';

class WhatsAppLaunchService {
  Future<bool> sendMessage({
    required String phoneNumber,
    required String message,
  }) async {
    final normalized = PhoneUtils.normalizeForWhatsApp(phoneNumber);
    if (normalized == null) {
      throw StateError('Invalid WhatsApp number');
    }

    final uri = Uri.parse(
      'https://wa.me/$normalized?text=${Uri.encodeComponent(message)}',
    );

    if (!await canLaunchUrl(uri)) {
      return _tryWhatsAppScheme(normalized, message);
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (launched) return true;
    return _tryWhatsAppScheme(normalized, message);
  }

  Future<bool> _tryWhatsAppScheme(String normalized, String message) async {
    final uri = Uri.parse(
      'whatsapp://send?phone=$normalized&text=${Uri.encodeComponent(message)}',
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
