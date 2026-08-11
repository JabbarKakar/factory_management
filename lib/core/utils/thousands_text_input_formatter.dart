import 'package:flutter/services.dart';

/// A production-ready, internationalization-friendly [TextInputFormatter]
/// that dynamically formats numeric inputs into standard digit group separators
/// (e.g., transforming "123400998" into "123,400,998" in real-time).
///
/// Features:
/// - Stable cursor placement during mid-string edits, insertions, and deletions.
/// - Configurable thousands and decimal separators (e.g., US: `,` and `.`, EU: `.` and `,`, space: ` ` and `.`).
/// - Optional decimal point support with precision limits.
/// - Unformatted raw value extraction helper methods (`toRawString`, `tryParseDouble`, `tryParseInt`).
/// - Handles zero states, leading zero cleanup, paste actions, and full field clearance without NaN errors.
class ThousandsTextInputFormatter extends TextInputFormatter {
  ThousandsTextInputFormatter({
    this.thousandsSeparator = ',',
    this.decimalSeparator = '.',
    this.allowDecimal = true,
    this.decimalDigits = 2,
    this.allowNegative = false,
  })  : assert(thousandsSeparator != decimalSeparator,
            'Thousands separator and decimal separator must be different.'),
        assert(decimalDigits == null || decimalDigits >= 0,
            'Decimal digits cannot be negative.');

  final String thousandsSeparator;
  final String decimalSeparator;
  final bool allowDecimal;
  final int? decimalDigits;
  final bool allowNegative;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return TextEditingValue.empty;
    }

    final newText = newValue.text;

    // Check if negative sign is allowed and present at start
    final isNegative = allowNegative && newText.startsWith('-');

    // Sanitize string to extract raw numeric chars + decimal separator
    final rawBuffer = StringBuffer();
    bool hasDecimal = false;

    for (var i = 0; i < newText.length; i++) {
      final char = newText[i];
      if (RegExp(r'\d').hasMatch(char)) {
        rawBuffer.write(char);
      } else if (allowDecimal &&
          char == decimalSeparator &&
          !hasDecimal) {
        hasDecimal = true;
        rawBuffer.write(decimalSeparator);
      }
    }

    final sanitizedRaw = rawBuffer.toString();
    if (sanitizedRaw.isEmpty) {
      return isNegative
          ? const TextEditingValue(
              text: '-',
              selection: TextSelection.collapsed(offset: 1),
            )
          : TextEditingValue.empty;
    }

    // Determine how many raw valid characters (digits/decimal) were before the selection cursor
    final selectionEnd = newValue.selection.end.clamp(0, newText.length);
    int rawCharsBeforeCursor = 0;
    bool decimalSeenBeforeCursor = false;

    for (var i = 0; i < selectionEnd; i++) {
      final char = newText[i];
      if (RegExp(r'\d').hasMatch(char)) {
        rawCharsBeforeCursor++;
      } else if (allowDecimal &&
          char == decimalSeparator &&
          !decimalSeenBeforeCursor) {
        decimalSeenBeforeCursor = true;
        rawCharsBeforeCursor++;
      }
    }

    // Split integer and decimal parts
    String integerPart;
    String? decimalPart;

    if (sanitizedRaw.contains(decimalSeparator)) {
      final parts = sanitizedRaw.split(decimalSeparator);
      integerPart = parts[0];
      decimalPart = parts.sublist(1).join();
    } else {
      integerPart = sanitizedRaw;
    }

    // Strip redundant leading zeros for integer part (except '0')
    if (integerPart.length > 1 && integerPart.startsWith('0')) {
      integerPart = integerPart.replaceFirst(RegExp(r'^0+'), '');
      if (integerPart.isEmpty) integerPart = '0';
    } else if (integerPart.isEmpty) {
      integerPart = '0';
    }

    // Truncate decimal part if decimalDigits is configured
    if (decimalPart != null &&
        decimalDigits != null &&
        decimalPart.length > decimalDigits!) {
      decimalPart = decimalPart.substring(0, decimalDigits);
    }

    // Format integer part with thousands separators
    final formattedInteger =
        _formatIntegerPart(integerPart, thousandsSeparator);

    // Combine formatted output
    final formattedBuffer = StringBuffer();
    if (isNegative) {
      formattedBuffer.write('-');
    }
    formattedBuffer.write(formattedInteger);
    if (hasDecimal) {
      formattedBuffer.write(decimalSeparator);
      if (decimalPart != null) {
        formattedBuffer.write(decimalPart);
      }
    }

    final formattedText = formattedBuffer.toString();

    // Map rawCharsBeforeCursor back to character index in formattedText
    int newCursorOffset = 0;
    int rawCharsEncountered = 0;

    for (var i = 0; i < formattedText.length; i++) {
      final char = formattedText[i];
      if (RegExp(r'\d').hasMatch(char) || char == decimalSeparator) {
        rawCharsEncountered++;
      }
      if (rawCharsEncountered >= rawCharsBeforeCursor) {
        newCursorOffset = i + 1;
        break;
      }
    }

    if (rawCharsBeforeCursor == 0) {
      newCursorOffset = isNegative ? 1 : 0;
    }

    newCursorOffset = newCursorOffset.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursorOffset),
    );
  }

  static String _formatIntegerPart(String intStr, String separator) {
    if (intStr.length <= 3) return intStr;
    final buffer = StringBuffer();
    final length = intStr.length;
    for (var i = 0; i < length; i++) {
      if (i > 0 && (length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(intStr[i]);
    }
    return buffer.toString();
  }

  // ===========================================================================
  // HELPER UTILITIES
  // ===========================================================================

  /// Converts a formatted number string back to a clean unformatted numeric string.
  /// Example: "123,400,998.50" -> "123400998.50"
  static String toRawString(
    String? formattedText, {
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
  }) {
    if (formattedText == null || formattedText.isEmpty) return '';
    var cleaned = formattedText
        .replaceAll(thousandsSeparator, '')
        .replaceAll(RegExp(r'[^\d\.-]'), '');
    if (decimalSeparator != '.') {
      cleaned = cleaned.replaceAll(decimalSeparator, '.');
    }
    return cleaned;
  }

  /// Parses a formatted string to [double], returning `null` if invalid or empty.
  static double? tryParseDouble(
    String? formattedText, {
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
  }) {
    final raw = toRawString(
      formattedText,
      thousandsSeparator: thousandsSeparator,
      decimalSeparator: decimalSeparator,
    );
    return double.tryParse(raw);
  }

  /// Parses a formatted string to [int], returning `null` if invalid or empty.
  static int? tryParseInt(
    String? formattedText, {
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
  }) {
    final raw = toRawString(
      formattedText,
      thousandsSeparator: thousandsSeparator,
      decimalSeparator: decimalSeparator,
    );
    final intRaw = raw.split('.').first;
    return int.tryParse(intRaw);
  }

  /// Parses a formatted string to [num], returning `null` if invalid or empty.
  static num? tryParseNum(
    String? formattedText, {
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
  }) {
    final raw = toRawString(
      formattedText,
      thousandsSeparator: thousandsSeparator,
      decimalSeparator: decimalSeparator,
    );
    return num.tryParse(raw);
  }

  /// Formats a raw numeric value programmatically for TextField initial values or display.
  static String format(
    num? value, {
    String thousandsSeparator = ',',
    String decimalSeparator = '.',
    bool allowDecimal = true,
    int? decimalDigits,
  }) {
    if (value == null) return '';
    if (value == 0) return '0';

    final isNegative = value < 0;
    final absVal = value.abs();

    String intPart;
    String? decPart;

    if (allowDecimal && (decimalDigits == null || decimalDigits > 0)) {
      final str = decimalDigits != null
          ? absVal.toStringAsFixed(decimalDigits)
          : absVal.toString();
      final parts = str.split('.');
      intPart = parts[0];
      if (parts.length > 1 && parts[1] != '0' && parts[1] != '00') {
        decPart = parts[1];
      }
    } else {
      intPart = absVal.toInt().toString();
    }

    final formattedInt = _formatIntegerPart(intPart, thousandsSeparator);
    final buffer = StringBuffer();
    if (isNegative) buffer.write('-');
    buffer.write(formattedInt);
    if (decPart != null && decPart.isNotEmpty) {
      buffer.write(decimalSeparator);
      buffer.write(decPart);
    }
    return buffer.toString();
  }
}
