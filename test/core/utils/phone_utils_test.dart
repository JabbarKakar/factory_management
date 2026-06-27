import 'package:factory_management/core/utils/phone_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhoneUtils.normalizeForWhatsApp', () {
    test('normalizes local Pakistani mobile', () {
      expect(PhoneUtils.normalizeForWhatsApp('0300-1234567'), '923001234567');
    });

    test('normalizes +92 format', () {
      expect(PhoneUtils.normalizeForWhatsApp('+92 300 1234567'), '923001234567');
    });

    test('keeps already normalized number', () {
      expect(PhoneUtils.normalizeForWhatsApp('923001234567'), '923001234567');
    });

    test('returns null for empty input', () {
      expect(PhoneUtils.normalizeForWhatsApp(''), isNull);
      expect(PhoneUtils.normalizeForWhatsApp(null), isNull);
    });
  });

  group('PhoneUtils.pickWhatsAppNumber', () {
    test('prefers whatsApp field', () {
      expect(
        PhoneUtils.pickWhatsAppNumber(
          whatsApp: '03001112222',
          phone: '03003334444',
        ),
        '923001112222',
      );
    });

    test('falls back to phone', () {
      expect(
        PhoneUtils.pickWhatsAppNumber(phone: '03005556666'),
        '923005556666',
      );
    });
  });
}
