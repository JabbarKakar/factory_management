abstract final class Formatters {
  static String roleLabel(String role) {
    if (role.isEmpty) return 'User';
    return role
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
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
}
