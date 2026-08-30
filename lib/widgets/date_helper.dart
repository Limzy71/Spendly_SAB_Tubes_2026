class DateHelper {
  DateHelper._();

  static const int minYear = 2023;
  static DateTime get minDate => DateTime(minYear, 1, 1);

  static DateTime get today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  static DateTime endOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0, 23, 59, 59);
  }

  static DateTime nextMonthEnd({DateTime? from}) {
    final base = from ?? today;
    return endOfMonth(DateTime(base.year, base.month + 1, 1));
  }

  static bool isUpcoming(String dateString) {
    final date = DateTime.tryParse(dateString);
    if (date == null) return false;
    return date.isAfter(today);
  }
}
