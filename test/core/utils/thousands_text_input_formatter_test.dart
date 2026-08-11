import 'package:factory_management/core/utils/thousands_text_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThousandsTextInputFormatter Tests', () {
    final formatter = ThousandsTextInputFormatter(
      thousandsSeparator: ',',
      decimalSeparator: '.',
      allowDecimal: true,
      decimalDigits: 2,
    );

    test('Formats integer input dynamically with comma separators', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '123400998',
        selection: TextSelection.collapsed(offset: 9),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('123,400,998'));
      expect(result.selection.end, equals(11));
    });

    test('Cursor position remains stable during mid-string edits', () {
      // Insertion of '9' inside '12,345' after '2' -> '129,345'
      const oldValue = TextEditingValue(
        text: '12,345',
        selection: TextSelection.collapsed(offset: 2),
      );
      const newValue = TextEditingValue(
        text: '129,345',
        selection: TextSelection.collapsed(offset: 3),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('129,345'));
      expect(result.selection.end, equals(3));
    });

    test('Supports decimal precision limits', () {
      const oldValue = TextEditingValue.empty;
      const newValue = TextEditingValue(
        text: '123456.789',
        selection: TextSelection.collapsed(offset: 10),
      );

      final result = formatter.formatEditUpdate(oldValue, newValue);
      expect(result.text, equals('123,456.78'));
    });

    test('Helper method toRawString extracts clean unformatted payload', () {
      expect(
        ThousandsTextInputFormatter.toRawString('123,400,998.50'),
        equals('123400998.50'),
      );
    });

    test('Helper method tryParseDouble converts to double correctly', () {
      expect(
        ThousandsTextInputFormatter.tryParseDouble('123,400,998.50'),
        equals(123400998.50),
      );
    });

    test('Helper method tryParseInt converts to integer correctly', () {
      expect(
        ThousandsTextInputFormatter.tryParseInt('123,400,998'),
        equals(123400998),
      );
    });

    test('Helper method format programmatically formats num values', () {
      expect(
        ThousandsTextInputFormatter.format(123400998),
        equals('123,400,998'),
      );
      expect(
        ThousandsTextInputFormatter.format(123400998.5),
        equals('123,400,998.5'),
      );
    });
  });
}
