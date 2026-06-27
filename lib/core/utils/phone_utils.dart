abstract final class PhoneUtils {
  /// Normalizes Pakistani phone numbers to digits suitable for `wa.me/{number}`.
  ///
  /// Examples:
  /// - `0300-1234567` -> `923001234567`
  /// - `+92 300 1234567` -> `923001234567`
  static String? normalizeForWhatsApp(String? raw) {
    if (raw == null) return null;

    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;

    if (digits.startsWith('92') && digits.length >= 12) {
      return digits;
    }
    if (digits.startsWith('0') && digits.length >= 11) {
      return '92${digits.substring(1)}';
    }
    if (digits.length == 10 && digits.startsWith('3')) {
      return '92$digits';
    }
    if (digits.length >= 11) {
      return digits;
    }
    return null;
  }

  static String? pickWhatsAppNumber({
    String? whatsApp,
    String? phone,
    String? phoneSecondary,
  }) {
    return normalizeForWhatsApp(whatsApp) ??
        normalizeForWhatsApp(phone) ??
        normalizeForWhatsApp(phoneSecondary);
  }
}
