import 'package:intl/intl.dart';

class AppDateFormatter {
  AppDateFormatter._();

  static final DateFormat _display = DateFormat('dd MMM yyyy');
  static final DateFormat _displayWithTime = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  static String display(DateTime date) => _display.format(date);

  static String displayWithTime(DateTime date) => _displayWithTime.format(date);

  static String isoDate(DateTime date) => _isoDate.format(date);

  static DateTime startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  static DateTime endOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
}
