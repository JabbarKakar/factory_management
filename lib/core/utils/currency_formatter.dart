import 'package:intl/intl.dart';

/// Centralized single source of truth for Currency Formatting across the application.
abstract final class CurrencyFormatter {
  /// Global active currency setting derived from the active FactoryProfile.
  static String activeCurrency = 'PKR';

  /// Formats amounts according to the active or specified currency.
  /// Supported currency codes include: 'PKR', 'USD', 'EUR', 'AED', 'GBP', 'INR', etc.
  static String format(
    num amount, {
    String? currencyCode,
    bool showSymbol = true,
    int? decimalDigits,
    bool asciiSafe = false,
  }) {
    final code = (currencyCode != null && currencyCode.trim().isNotEmpty)
        ? currencyCode.trim().toUpperCase()
        : activeCurrency.trim().toUpperCase();

    final isNegative = amount < 0;
    final absAmount = amount.abs().toDouble();

    final decimals = decimalDigits ?? _defaultDecimals(code, absAmount);

    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: decimals,
    );
    final formattedNumber = formatter.format(absAmount).trim();

    if (!showSymbol) {
      return isNegative ? '- $formattedNumber' : formattedNumber;
    }

    final symbol = getSymbol(code, asciiSafe: asciiSafe);
    final prefix = isNegative ? '- ' : '';

    return '$prefix$symbol $formattedNumber'.trim();
  }

  /// Formats exact un-abbreviated currency value with localized symbol and thousands separators.
  /// Example: 30900 -> "Rs 30,900", 4500000 -> "Rs 4,500,000".
  static String formatFull(
    num amount, {
    String? currencyCode,
    bool showDecimals = false,
    bool asciiSafe = false,
  }) {
    return format(
      amount,
      currencyCode: currencyCode,
      decimalDigits: showDecimals ? 2 : (amount.toDouble() % 1 == 0 ? 0 : 2),
      asciiSafe: asciiSafe,
    );
  }

  /// Compact currency for dense UI (K / M suffixes).
  static String formatCompact(
    num amount, {
    String? currencyCode,
    bool asciiSafe = false,
  }) {
    final code = (currencyCode != null && currencyCode.trim().isNotEmpty)
        ? currencyCode.trim().toUpperCase()
        : activeCurrency.trim().toUpperCase();

    final isNegative = amount < 0;
    final absAmount = amount.abs().toDouble();
    final symbol = getSymbol(code, asciiSafe: asciiSafe);
    final prefix = isNegative ? '- ' : '';

    final String number;
    if (absAmount >= 10000000) {
      number = '${_trimTrailingZeros((absAmount / 1000000).toStringAsFixed(2))}M';
    } else if (absAmount >= 1000000) {
      number = '${_trimTrailingZeros((absAmount / 1000000).toStringAsFixed(2))}M';
    } else if (absAmount >= 10000) {
      number = '${_trimTrailingZeros((absAmount / 1000).toStringAsFixed(1))}K';
    } else {
      return format(amount, currencyCode: code, decimalDigits: 0, asciiSafe: asciiSafe);
    }

    return '$prefix$symbol $number'.trim();
  }

  static String _trimTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    return value
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  /// Returns the currency symbol or prefix string for a currency code.
  static String getSymbol(String currencyCode, {bool asciiSafe = false}) {
    final code = currencyCode.trim().toUpperCase();
    switch (code) {
      case 'PKR':
        return asciiSafe ? 'PKR' : 'Rs';
      case 'USD':
        return '\$';
      case 'EUR':
        return asciiSafe ? 'EUR' : '€';
      case 'AED':
        return 'AED';
      case 'GBP':
        return asciiSafe ? 'GBP' : '£';
      case 'SAR':
        return 'SAR';
      case 'INR':
        return asciiSafe ? 'INR' : '₹';
      case 'CAD':
        return 'CA\$';
      case 'AUD':
        return 'A\$';
      default:
        return code;
    }
  }

  static int _defaultDecimals(String code, double amount) {
    if (code == 'PKR' || code == 'INR') {
      return (amount == amount.roundToDouble()) ? 0 : 2;
    }
    return 2;
  }
}
