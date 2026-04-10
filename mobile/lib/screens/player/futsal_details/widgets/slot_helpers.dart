// lib/screens/player/futsal_details/widgets/slot_helpers.dart
import 'package:flutter/material.dart';
import '../../../../utils/futsal_constants.dart';

class SlotHelpers {
  static bool isSlotPeak(Map<String, dynamic> slot, DateTime selectedDate) {
    try {
      final timeStr = slot['startTime'] as String? ?? '00:00';
      final hour = int.tryParse(timeStr.split(':').first) ?? 0;
      return FutsalConstants.isPeakHour(hour, selectedDate.weekday);
    } catch (e) {
      return false;
    }
  }

  static bool isSlotBooked(Map<String, dynamic> slot) {
    final status = slot['status'] as String? ?? '';
    return status == 'BOOKED' || status == 'CONFIRMED' || status == 'COMPLETED';
  }

  static bool isSlotAvailable(Map<String, dynamic> slot) {
    final status = slot['status'] as String? ?? '';
    return status == 'AVAILABLE';
  }

  static bool isSlotLockedBySystem(Map<String, dynamic> slot) {
    final status = slot['status'] as String? ?? '';
    if (status != 'LOCKED') return false;

    try {
      final lockedUntil = slot['lockedUntil'] != null
          ? DateTime.parse(slot['lockedUntil'])
          : null;
      return lockedUntil != null && lockedUntil.isAfter(DateTime.now());
    } catch (e) {
      return true;
    }
  }

  static bool isSlotTemporarilyLocked(
    int slotId,
    Map<int, DateTime> temporaryLocks,
  ) {
    final expiry = temporaryLocks[slotId];
    if (expiry == null) return false;
    if (expiry.isBefore(DateTime.now())) {
      return false;
    }
    return true;
  }

  static bool canSelectSlot(
    Map<String, dynamic> slot,
    Map<int, DateTime> temporaryLocks,
  ) {
    final slotId = slot['id'] as int? ?? 0;
    final isAvailable = isSlotAvailable(slot);
    final isTemporarilyLocked = isSlotTemporarilyLocked(slotId, temporaryLocks);
    final isSystemLocked = isSlotLockedBySystem(slot);

    return isAvailable && !isTemporarilyLocked && !isSystemLocked;
  }

  static String getCourtNumber(Map<String, dynamic> slot) {
    // Try all possible court key names
    if (slot.containsKey('court')) {
      return 'Court ${slot['court']}';
    } else if (slot.containsKey('courtNumber')) {
      return 'Court ${slot['courtNumber']}';
    } else if (slot.containsKey('court_no')) {
      return 'Court ${slot['court_no']}';
    } else if (slot.containsKey('courtId')) {
      return 'Court ${slot['courtId']}';
    } else if (slot.containsKey('court_id')) {
      return 'Court ${slot['court_id']}';
    } else if (slot.containsKey('court_number')) {
      return 'Court ${slot['court_number']}';
    } else {
      // If no court key found, check if there's a nested court object
      if (slot.containsKey('courtDetails') && slot['courtDetails'] is Map) {
        final courtDetails = slot['courtDetails'] as Map;
        if (courtDetails.containsKey('number')) {
          return 'Court ${courtDetails['number']}';
        }
      }

      debugPrint('⚠️ No court number found in slot: ${slot.keys}');
      return 'Court 1'; // Default fallback
    }
  }

  static num getSlotPrice(Map<String, dynamic> slot) {
    return num.tryParse(slot['price']?.toString() ?? '0') ?? 0;
  }

  static Widget buildPeakChip() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        '🔥 Peak',
        style: TextStyle(
          fontSize: 10,
          color: Colors.red.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}