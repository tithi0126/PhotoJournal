import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _isoFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _editorialFormat = DateFormat('EEEE, d MMMM yyyy');
  static final DateFormat _shortEditorialFormat = DateFormat('d MMM yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');
  static final DateFormat _yearFormat = DateFormat('yyyy');
  static final DateFormat _yearMonthFormat = DateFormat('yyyy-MM');

  /// Convert DateTime to 'YYYY-MM-DD'
  static String toIsoDate(DateTime date) => _isoFormat.format(date);

  /// Parse 'YYYY-MM-DD' into DateTime
  static DateTime parseIsoDate(String dateStr) => _isoFormat.parse(dateStr);

  /// Editorial label: "Friday, 23 October 2026"
  static String toEditorial(DateTime date) => _editorialFormat.format(date);

  /// Short: "23 Oct 2026"
  static String toShort(DateTime date) => _shortEditorialFormat.format(date);

  /// "October 2026"
  static String toMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// "2026-10"
  static String toYearMonth(DateTime date) => _yearMonthFormat.format(date);

  /// "2026"
  static String toYear(DateTime date) => _yearFormat.format(date);

  /// Checks if two dates share the exact same calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Midnight boundary grace check per PRD §3.1:
  /// Grace period until 03:00 local time: offers yesterday as an easy option for late-night shooters
  static bool isWithinLateNightGrace(DateTime now) {
    return now.hour < 3;
  }
}
