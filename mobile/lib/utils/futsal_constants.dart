// lib/utils/futsal_constants.dart
import 'package:flutter/material.dart';

class FutsalConstants {
  static const int maxBookingHours = 4;
  static const int lockDurationMinutes = 5;
  static const int peakHourStart = 17;
  static const int peakHourEnd = 20;
  static const int slotGridCrossAxisCount = 3;
  static const double slotAspectRatio = 1.2;
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration snackBarDuration = Duration(seconds: 2);

  // Peak identification
  static bool isPeakHour(int hour, int weekday) {
    final isWeekend =
        weekday == DateTime.saturday || weekday == DateTime.sunday;
    final isPeakHour = hour >= peakHourStart && hour < peakHourEnd;
    return isPeakHour || isWeekend;
  }
}