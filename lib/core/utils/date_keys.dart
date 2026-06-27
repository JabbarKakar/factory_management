import 'package:intl/intl.dart';

abstract final class DateKeys {
  static final _formatter = DateFormat('yyyy-MM-dd');

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
}
