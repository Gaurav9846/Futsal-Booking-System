import 'package:flutter/material.dart';

class Booking {
  final int id;
  final int userId;
  final int futsalId;
  final String futsalName;        // ADD THIS
  final String futsalAddress;      // ADD THIS
  final int courtId;
  final String courtNumber;
  final String? customerName;
  final String? customerPhone;
  final DateTime date;
  final String startTime;
  final String endTime;
  final int totalAmount;
  final String paymentMethod;
  final String paymentStatus; // paid, pending, failed
  final String bookingStatus; // confirmed, cancelled, completed, no_show
  final DateTime? checkInTime;
  final DateTime? checkOutTime;
  final String? bookedBy; // name of person who booked
  final bool isRecurring;
  final int? recurringId;

  Booking({
    required this.id,
    required this.userId,
    required this.futsalId,
    required this.futsalName,      // ADD THIS
    required this.futsalAddress,    // ADD THIS
    required this.courtId,
    required this.courtNumber,
    this.customerName,
    this.customerPhone,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.bookingStatus,
    this.checkInTime,
    this.checkOutTime,
    this.bookedBy,
    this.isRecurring = false,
    this.recurringId,
  });

factory Booking.fromJson(Map<String, dynamic> json) {
  final slotData = json['slot'] as Map<String, dynamic>? ?? {};
  final courtData = slotData['court'] as Map<String, dynamic>? ?? {};   // ✅ fixed path
  final futsalData = courtData['futsal'] as Map<String, dynamic>? ?? {}; // ✅ fixed path

  // ✅ Use slot date for filtering, fall back to bookingDate
  DateTime bookingDate;
  try {
    if (slotData['date'] != null) {
      bookingDate = DateTime.parse(slotData['date']).toLocal();
    } else if (json['bookingDate'] != null) {
      bookingDate = DateTime.parse(json['bookingDate']).toLocal();
    } else {
      bookingDate = DateTime.now();
    }
  } catch (_) {
    bookingDate = DateTime.now();
  }

  return Booking(
    id: json['id'] ?? 0,
    userId: json['userId'] ?? json['user']?['id'] ?? 0,
    futsalId: futsalData['id'] ?? json['futsalId'] ?? 0,
    futsalName: futsalData['name'] ?? json['futsalName'] ?? 'Unknown Futsal',       // ✅
    futsalAddress: futsalData['address'] ?? json['futsalAddress'] ?? 'Unknown Address', // ✅
    courtId: courtData['id'] ?? slotData['courtId'] ?? json['courtId'] ?? 0,        // ✅
    courtNumber: courtData['courtNumber'] ?? json['courtNumber'] ?? '1',             // ✅
    customerName: json['customerName'] ?? json['user']?['fullName'],
    customerPhone: json['customerPhone'] ?? json['user']?['phoneNumber'],
    date: bookingDate,                                                                // ✅
    startTime: slotData['startTime'] ?? json['startTime'] ?? '00:00',
    endTime: slotData['endTime'] ?? json['endTime'] ?? '01:00',
    totalAmount: (json['totalPrice'] ?? json['totalAmount'] ?? 0).toInt(),  
    paymentMethod: json['paymentMethod'] ?? 'COD',         // ✅ toInt() safety
    paymentStatus: json['payment']?['status'] ?? json['paymentStatus'] ?? 'PENDING', // ✅ from payment relation
    bookingStatus: json['status'] ?? json['bookingStatus'] ?? 'PENDING',
    checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
    checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
    bookedBy: json['bookedBy'] ?? json['user']?['fullName'],
    isRecurring: json['isRecurring'] ?? false,
    recurringId: json['recurringId'],
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'futsalId': futsalId,
      'futsalName': futsalName,      // ADD THIS
      'futsalAddress': futsalAddress,  // ADD THIS
      'courtId': courtId,
      'courtNumber': courtNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'date': date.toIso8601String().split('T')[0],
      'startTime': startTime,
      'endTime': endTime,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'bookingStatus': bookingStatus,
      'checkInTime': checkInTime?.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'bookedBy': bookedBy,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
    };
  }

  Booking copyWith({
    int? id,
    int? userId,
    int? futsalId,
    String? futsalName,      // ADD THIS
    String? futsalAddress,    // ADD THIS
    int? courtId,
    String? courtNumber,
    String? customerName,
    String? customerPhone,
    DateTime? date,
    String? startTime,
    String? endTime,
    int? totalAmount,
    String? paymentMethod,
    String? paymentStatus,
    String? bookingStatus,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    String? bookedBy,
    bool? isRecurring,
    int? recurringId,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      futsalId: futsalId ?? this.futsalId,
      futsalName: futsalName ?? this.futsalName,        // ADD THIS
      futsalAddress: futsalAddress ?? this.futsalAddress, // ADD THIS
      courtId: courtId ?? this.courtId,
      courtNumber: courtNumber ?? this.courtNumber,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      bookedBy: bookedBy ?? this.bookedBy,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringId: recurringId ?? this.recurringId,
    );
  }

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  String get duration {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    final diff = end.difference(start);
    return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  bool get isCheckedIn => checkInTime != null;
  
  bool get isCheckedOut => checkOutTime != null;
  
  bool get isPaid => paymentStatus.toLowerCase() == 'completed' ||
                   paymentStatus.toLowerCase() == 'paid';
  
  bool get isPending => bookingStatus.toLowerCase() == 'pending';
  
  bool get isCancelled => bookingStatus.toLowerCase() == 'cancelled';
  
  bool get isCompleted => bookingStatus.toLowerCase() == 'completed';
  
  Color get statusColor {
    if (isCancelled) return Colors.red;
    if (isCompleted) return Colors.green;
    if (isCheckedIn) return Colors.blue;
    if (bookingStatus.toLowerCase() == 'confirmed') return Colors.teal;
    return Colors.orange; // pending
  }

  String get statusText {
    if (isCancelled) return 'Cancelled';
    if (isCompleted) return 'Completed';
    if (isCheckedIn) return 'Checked In';
    if (bookingStatus.toLowerCase() == 'confirmed') return 'Confirmed';
    if (bookingStatus.toLowerCase() == 'pending') return 'Pending';
    return 'Unknown';
  }
}