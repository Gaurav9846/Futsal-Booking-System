import 'package:flutter/material.dart';

class CalendarGrid extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) getBookingsForDate;
  final Function(DateTime) onDateSelected;

  const CalendarGrid({
    super.key,
    required this.selectedDate,
    required this.getBookingsForDate,
    required this.onDateSelected,
  });

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  int _getBookingCountForDate(DateTime date) {
    final bookings = getBookingsForDate(date);
    return bookings.length;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: 42,
      itemBuilder: (ctx, index) {
        final day = index - startingWeekday + 2;
        final isCurrentMonth = day >= 1 && day <= daysInMonth;

        if (!isCurrentMonth) {
          return Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        final date = DateTime(selectedDate.year, selectedDate.month, day);
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _isSameDay(date, selectedDate);
        final bookingCount = _getBookingCountForDate(date);

        return GestureDetector(
          onTap: () => onDateSelected(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green
                  : isToday
                      ? Colors.green.shade50
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                if (bookingCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bookingCount.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.green : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}