import 'package:flutter/material.dart';

class OperatingHoursInput extends StatefulWidget {
  final Map<String, dynamic>? initialHours;
  final Function(Map<String, dynamic>) onChanged;

  const OperatingHoursInput({
    super.key,
    this.initialHours,
    required this.onChanged,
  });

  @override
  State<OperatingHoursInput> createState() => _OperatingHoursInputState();
}

class _OperatingHoursInputState extends State<OperatingHoursInput> {
  late Map<String, Map<String, String>> _hours;
  final List<String> _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];
  final List<String> _dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _initHours();
  }

  void _initHours() {
    _hours = {};
    for (var day in _days) {
      if (widget.initialHours != null && widget.initialHours![day] != null) {
        _hours[day] = {
          'open': widget.initialHours![day]['open'] ?? '09:00',
          'close': widget.initialHours![day]['close'] ?? '22:00',
        };
      } else {
        final isWeekend = day == 'saturday' || day == 'sunday';
        _hours[day] = {
          'open': isWeekend ? '08:00' : '09:00',
          'close': isWeekend ? '23:00' : '22:00',
        };
      }
    }
  }

  void _notifyChange() {
    widget.onChanged(_hours);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.access_time, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Operating Hours',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Set your futsal\'s operating hours for each day',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...List.generate(_days.length, (index) {
              final day = _days[index];
              final dayName = _dayNames[index];
              final hours = _hours[day]!;
              
              return Column(
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          dayName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTimePicker(
                                day,
                                'open',
                                hours['open']!,
                                'Open',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('-'),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildTimePicker(
                                day,
                                'close',
                                hours['close']!,
                                'Close',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String day, String type, String initialValue, String label) {
    return GestureDetector(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: _parseTime(initialValue),
        );
        if (picked != null) {
          setState(() {
            _hours[day]![type] = _formatTime(picked);
          });
          _notifyChange();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(
              initialValue,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}