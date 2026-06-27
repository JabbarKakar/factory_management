import '../../domain/enums/factory_role_enums.dart';

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

  static String currencyPkr(double amount) {
    final formatted = amount.abs().toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
    final prefix = amount < 0 ? '- ' : '';
    return '$prefix₨ $formatted';
  }

  /// ASCII-safe currency for PDF/Excel exports (Helvetica fallback friendly).
  static String currencyForExport(double amount) {
    final formatted =
        amount.abs().toStringAsFixed(amount == amount.roundToDouble() ? 0 : 2);
    final prefix = amount < 0 ? '- ' : '';
    return '$prefix Rs $formatted';
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

  static String stockQuantity(double quantity, String unitLabel) {
    final formatted =
        quantity.toStringAsFixed(quantity == quantity.roundToDouble() ? 0 : 2);
    return '$formatted $unitLabel';
  }
}
