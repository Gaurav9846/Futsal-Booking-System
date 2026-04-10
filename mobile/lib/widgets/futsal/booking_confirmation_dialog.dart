// lib/widgets/futsal/booking_confirmation_dialog.dart
import 'package:flutter/material.dart';
import '../../utils/date_formatter.dart';
import '../../utils/futsal_constants.dart';

class BookingConfirmationDialog extends StatefulWidget {
  final Map<String, dynamic> selectedSlot;
  final DateTime selectedDate;
  final bool isProcessing;
  final Function(int) onConfirm;
  final VoidCallback onCancel;

  const BookingConfirmationDialog({
    super.key,
    required this.selectedSlot,
    required this.selectedDate,
    required this.isProcessing,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  State<BookingConfirmationDialog> createState() =>
      _BookingConfirmationDialogState();
}

class _BookingConfirmationDialogState
    extends State<BookingConfirmationDialog> {
  int _selectedDuration = 1;

  String _getCourtNumber() {
    final slot = widget.selectedSlot;
    if (slot.containsKey('court')) {
      return 'Court ${slot['court']}';
    } else if (slot.containsKey('courtNumber')) {
      return 'Court ${slot['courtNumber']}';
    } else if (slot.containsKey('court_no')) {
      return 'Court ${slot['court_no']}';
    } else {
      return 'Court 1';
    }
  }

  bool _isSlotPeak() {
    try {
      final timeStr = widget.selectedSlot['startTime'] as String? ?? '00:00';
      final hour = int.tryParse(timeStr.split(':').first) ?? 0;
      return FutsalConstants.isPeakHour(hour, widget.selectedDate.weekday);
    } catch (e) {
      return false;
    }
  }

  num _getSlotPrice() {
    return num.tryParse(widget.selectedSlot['price']?.toString() ?? '0') ?? 0;
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildPeakChip() {
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

  @override
  Widget build(BuildContext context) {
    final price = _getSlotPrice();
    final isPeak = _isSlotPeak();
    final total = price * _selectedDuration;

    return AlertDialog(
      title: const Text('Confirm Booking'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Details container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                    Icons.calendar_today,
                    DateFormatter.formatDateFull(widget.selectedDate)),
                const SizedBox(height: 8),
                _buildDetailRow(
                    Icons.access_time, widget.selectedSlot['startTime']),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.sports_soccer, _getCourtNumber()),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Duration selector
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Duration (hours)'),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _selectedDuration > 1
                              ? () => setState(() => _selectedDuration--)
                              : null,
                          color: _selectedDuration > 1
                              ? Colors.green
                              : Colors.grey,
                        ),
                        Container(
                          width: 40,
                          alignment: Alignment.center,
                          child: Text(
                            '$_selectedDuration',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _selectedDuration <
                                  FutsalConstants.maxBookingHours
                              ? () => setState(() => _selectedDuration++)
                              : null,
                          color: _selectedDuration <
                                  FutsalConstants.maxBookingHours
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Price per hour'),
                        if (isPeak) _buildPeakChip(),
                      ],
                    ),
                    Text(
                      'रू ${price.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: isPeak ? Colors.red.shade700 : Colors.black,
                        fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'रू ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.isProcessing ? null : widget.onCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: widget.isProcessing
              ? null
              : () => widget.onConfirm(_selectedDuration),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}