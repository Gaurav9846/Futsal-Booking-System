import 'package:intl/intl.dart';

class DateFormatter {
  // Private constructor to prevent instantiation
  DateFormatter._();

  // ============================================
  // DATE FORMATS
  // ============================================

  // Format: YYYY-MM-DD (e.g., 2024-01-20)
  static String formatYearMonthDay(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Format: DD/MM/YYYY (e.g., 20/01/2024)
  static String formatDateSlashed(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Format: DD MMM YYYY (e.g., 20 Jan 2024)
  static String formatDateMedium(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  // Format: DD MMMM YYYY (e.g., 20 January 2024)
  static String formatDateFull(DateTime date) {
    return DateFormat('dd MMMM yyyy').format(date);
  }

  // Format: MMM DD, YYYY (e.g., Jan 20, 2024)
  static String formatDateShort(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  // Format: Day, DD MMM (e.g., Monday, 20 Jan)
  static String formatDateWithWeekday(DateTime date) {
    return DateFormat('EEEE, dd MMM').format(date);
  }

  // Format: DD MMM (e.g., 20 Jan)
  static String formatDateDayMonth(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  // ============================================
  // TIME FORMATS
  // ============================================

  // Format: HH:MM (e.g., 14:30)
  static String formatTime24Hour(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // Format: HH:MM AM/PM (e.g., 02:30 PM)
  static String formatTime12Hour(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  // Format time string (e.g., "14:30" -> "02:30 PM")
  static String formatTimeString(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return time;
      
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      
      final period = hour >= 12 ? 'PM' : 'AM';
      final hour12 = hour == 12 ? 12 : hour % 12;
      
      return '$hour12:$minute $period';
    } catch (e) {
      return time;
    }
  }

  // ============================================
  // DAY/MONTH FORMATS
  // ============================================

  // Get day name (e.g., Monday, Tuesday)
  static String formatDay(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  // Get short day name (e.g., Mon, Tue)
  static String formatDayShort(DateTime date) {
    return DateFormat('E').format(date);
  }

  // Get month name (e.g., January)
  static String formatMonth(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  // Get short month name (e.g., Jan)
  static String formatMonthShort(DateTime date) {
    return DateFormat('MMM').format(date);
  }

  // Format: MMM YYYY (e.g., Jan 2024)
  static String formatMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  // ============================================
  // RELATIVE DATES
  // ============================================

  // Get relative day name (Today, Tomorrow, or day name)
  static String getRelativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == tomorrow) {
      return 'Tomorrow';
    } else {
      return formatDay(date);
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
           date.month == tomorrow.month &&
           date.day == tomorrow.day;
  }

  // Check if date is in the past
  static bool isPast(DateTime date) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isBefore(today);
  }

  // Check if date is in the future
  static bool isFuture(DateTime date) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final compareDate = DateTime(date.year, date.month, date.day);
    return compareDate.isAfter(today);
  }

  // ============================================
  // RANGE FORMATS
  // ============================================

  // Format date range (e.g., 20-25 Jan 2024 or 20 Jan - 25 Feb 2024)
  static String formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      // Same month and year: "20-25 Jan 2024"
      return '${start.day}-${end.day} ${formatMonthShort(start)} ${start.year}';
    } else if (start.year == end.year) {
      // Same year, different month: "20 Jan - 25 Feb 2024"
      return '${start.day} ${formatMonthShort(start)} - ${end.day} ${formatMonthShort(end)} ${start.year}';
    } else {
      // Different years: "20 Jan 2024 - 25 Feb 2025"
      return '${start.day} ${formatMonthShort(start)} ${start.year} - ${end.day} ${formatMonthShort(end)} ${end.year}';
    }
  }

  // ============================================
  // PARSE HELPERS
  // ============================================

  // Parse date from string (YYYY-MM-DD)
  static DateTime? parseYearMonthDay(String dateStr) {
    try {
      return DateFormat('yyyy-MM-dd').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // Parse date from string (DD/MM/YYYY)
  static DateTime? parseDateSlashed(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // CALENDAR HELPERS
  // ============================================

  // Get list of days in month
  static List<DateTime> getDaysInMonth(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    
    final days = <DateTime>[];
    for (int i = 1; i <= last.day; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  // Get week days for calendar grid (including previous/next month days)
  static List<DateTime> getCalendarDays(DateTime month) {
    final first = DateTime(month.year, month.month, 1);
    final last = DateTime(month.year, month.month + 1, 0);
    
    // Days from previous month
    final firstWeekday = first.weekday;
    final previousMonthDays = <DateTime>[];
    for (int i = firstWeekday - 1; i > 0; i--) {
      previousMonthDays.add(first.subtract(Duration(days: i)));
    }
    
    // Days from current month
    final currentMonthDays = getDaysInMonth(month);
    
    // Days from next month
    final lastWeekday = last.weekday;
    final nextMonthDays = <DateTime>[];
    for (int i = 1; i <= 7 - lastWeekday; i++) {
      nextMonthDays.add(last.add(Duration(days: i)));
    }
    
    return [...previousMonthDays, ...currentMonthDays, ...nextMonthDays];
  }
}