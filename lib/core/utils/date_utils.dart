import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isYesterday(DateTime date) =>
      isSameDay(date, DateTime.now().subtract(const Duration(days: 1)));

  static DateTime startOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static DateTime endOfWeek(DateTime date) {
    final start = startOfWeek(date);
    return DateTime(start.year, start.month, start.day + 6, 23, 59, 59, 999);
  }

  static DateTime startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  static DateTime endOfMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 0, 23, 59, 59, 999);

  static DateTime startOfYear(DateTime date) => DateTime(date.year, 1, 1);

  static DateTime endOfYear(DateTime date) => DateTime(date.year, 12, 31, 23, 59, 59, 999);

  static String formatShort(DateTime date) => DateFormat('MMM d, yyyy').format(date);

  static String formatDayMonth(DateTime date) => DateFormat('MMM d').format(date);

  static String formatMonthYear(DateTime date) => DateFormat('MMMM yyyy').format(date);
}
