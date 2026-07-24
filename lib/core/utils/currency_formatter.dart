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
