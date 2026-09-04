import 'package:intl/intl.dart';

abstract final class DateKeys {
  static final _formatter = DateFormat('yyyy-MM-dd');
  static final _monthFormatter = DateFormat('yyyy-MM');

  static String fromDate(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return _formatter.format(local);
  }

  static DateTime toDate(String dateKey) {
    return _formatter.parse(dateKey);
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Billing-cycle key, e.g. `"2026-09"`.
  static String monthKey(DateTime date) {
    return _monthFormatter.format(DateTime(date.year, date.month));
  }

  static DateTime monthStart(String monthKey) {
    final parts = monthKey.split('-');
    final year = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 1970 : 1970;
    final month = parts.length > 1 ? int.tryParse(parts[1]) ?? 1 : 1;
    return DateTime(year, month);
  }

  static int yearOf(String monthKey) => monthStart(monthKey).year;

  static int monthOf(String monthKey) => monthStart(monthKey).month;

  static String nextMonthKey(String monthKey) {
    final start = monthStart(monthKey);
    return DateKeys.monthKey(DateTime(start.year, start.month + 1));
  }

  static String previousMonthKey(String monthKey) {
    final start = monthStart(monthKey);
    return DateKeys.monthKey(DateTime(start.year, start.month - 1));
  }

  static String monthStartDateKey(String monthKey) {
    return fromDate(monthStart(monthKey));
  }

  static String nextMonthStartDateKey(String monthKey) {
    final start = monthStart(monthKey);
    return fromDate(DateTime(start.year, start.month + 1));
  }

  static String monthLabel(String monthKey) {
    return DateFormat.yMMMM().format(monthStart(monthKey));
  }
}
