import 'package:intl/intl.dart';
import '../../domain/enums/factory_role_enums.dart';
import 'currency_formatter.dart';

export 'thousands_text_input_formatter.dart';

abstract final class Formatters {
  static String roleLabel(String role) {
    return FactoryRole.fromString(role).label;
  }

  static String userInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String get activeCurrency => CurrencyFormatter.activeCurrency;
  static set activeCurrency(String code) {
    CurrencyFormatter.activeCurrency = code;
  }

  static String currency(
    num amount, {
    String? currencyCode,
    bool showSymbol = true,
    int? decimalDigits,
    bool asciiSafe = false,
  }) {
    return CurrencyFormatter.format(
      amount,
      currencyCode: currencyCode,
      showSymbol: showSymbol,
      decimalDigits: decimalDigits,
      asciiSafe: asciiSafe,
    );
  }

  static String currencyPkr(double amount, {String? currencyCode}) {
    return CurrencyFormatter.format(
      amount,
      currencyCode: currencyCode,
    );
  }

  static String currencyPkrWhole(double amount, {String? currencyCode}) {
    return CurrencyFormatter.format(
      amount,
      currencyCode: currencyCode,
      decimalDigits: 0,
    );
  }

  /// Short currency for tight UI strips (e.g. Rs 1.45M, Rs 650K).
  static String currencyCompact(double amount, {String? currencyCode}) {
    return CurrencyFormatter.formatCompact(
      amount,
      currencyCode: currencyCode,
    );
  }

  /// Precise full currency without K/M truncation (e.g. Rs 30,900).
  static String currencyFull(
    double amount, {
    String? currencyCode,
    bool showDecimals = false,
  }) {
    return CurrencyFormatter.formatFull(
      amount,
      currencyCode: currencyCode,
      showDecimals: showDecimals,
    );
  }


  /// ASCII-safe currency for PDF/Excel exports (Helvetica fallback friendly).
  static String currencyForExport(double amount, {String? currencyCode}) {
    return CurrencyFormatter.format(
      amount,
      currencyCode: currencyCode,
      asciiSafe: true,
    );
  }

  /// Replaces symbols that default PDF fonts cannot render.
  static String textForExport(String? text) {
    if (text == null || text.isEmpty) return '';
    return text
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u00b7', '-')
        .replaceAll('\u20a8', 'Rs');
  }

  static const String exportEmpty = '-';

  /// Formats physical inventory quantities (e.g. sqft / pcs) without currency symbols.
  /// Standard (exact): formatStockQuantity(211400, 'sqft') -> "211,400 sqft"
  /// Compact: formatStockQuantity(211400, 'sqft', compact: true) -> "211.4K sqft"
  static String formatStockQuantity(
    num value,
    String unit, {
    bool compact = false,
    int? decimalDigits,
  }) {
    final absVal = value.abs().toDouble();
    final isNeg = value < 0;
    final prefix = isNeg ? '-' : '';

    final String formattedNum;
    if (compact) {
      if (absVal >= 1000000000) {
        formattedNum = '${_trimZeros((absVal / 1000000000).toStringAsFixed(1))}B';
      } else if (absVal >= 1000000) {
        formattedNum = '${_trimZeros((absVal / 1000000).toStringAsFixed(1))}M';
      } else if (absVal >= 1000) {
        formattedNum = '${_trimZeros((absVal / 1000).toStringAsFixed(1))}K';
      } else {
        formattedNum = _formatExactNum(value, decimalDigits);
      }
    } else {
      formattedNum = _formatExactNum(value, decimalDigits);
    }

    final trimmedUnit = unit.trim();
    final unitSuffix = trimmedUnit.isNotEmpty ? ' $trimmedUnit' : '';
    return '$prefix$formattedNum$unitSuffix'.trim();
  }

  static String _trimZeros(String v) {
    if (!v.contains('.')) return v;
    return v.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  static String _formatExactNum(num value, int? decimalDigits) {
    if (decimalDigits != null) {
      final pattern = decimalDigits > 0
          ? '#,##0.${'0' * decimalDigits}'
          : '#,##0';
      return NumberFormat(pattern).format(value);
    }
    if (value is int || value.toDouble() == value.toDouble().roundToDouble()) {
      return NumberFormat('#,##0').format(value.toInt());
    }
    return NumberFormat('#,##0.##').format(value);
  }

  static String stockQuantity(double quantity, String unitLabel) {
    return formatStockQuantity(quantity, unitLabel);
  }
}
