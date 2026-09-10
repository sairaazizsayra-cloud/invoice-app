import 'package:invoice_pro/core/utils/date_formatter.dart';

enum DateFilterPreset { today, thisWeek, thisMonth, thisYear, custom }

class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  static DateRange fromPreset(DateFilterPreset preset, {DateTime? now}) {
    final current = now ?? DateTime.now();
    final todayStart = AppDateFormatter.startOfDay(current);
    final todayEnd = AppDateFormatter.endOfDay(current);

    switch (preset) {
      case DateFilterPreset.today:
        return DateRange(start: todayStart, end: todayEnd);
      case DateFilterPreset.thisWeek:
        final weekday = current.weekday; // Monday = 1
        final weekStart = todayStart.subtract(Duration(days: weekday - 1));
        return DateRange(start: weekStart, end: todayEnd);
      case DateFilterPreset.thisMonth:
        return DateRange(start: DateTime(current.year, current.month), end: todayEnd);
      case DateFilterPreset.thisYear:
        return DateRange(start: DateTime(current.year), end: todayEnd);
      case DateFilterPreset.custom:
        return DateRange(start: todayStart, end: todayEnd);
    }
  }
}
