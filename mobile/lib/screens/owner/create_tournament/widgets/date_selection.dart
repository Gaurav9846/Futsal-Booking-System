import 'package:flutter/material.dart';

class DateSelection extends StatelessWidget {
  final DateTime startDate;
  final DateTime? endDate;
  final Function(DateTime) onStartDateSelected;
  final Function(DateTime?) onEndDateSelected;
  final bool isDisabled;

  const DateSelection({
    super.key,
    required this.startDate,
    this.endDate,
    required this.onStartDateSelected,
    required this.onEndDateSelected,
    required this.isDisabled,
  });

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? startDate
          : (endDate ?? startDate.add(const Duration(days: 30))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      if (isStart) {
        onStartDateSelected(picked);
      } else {
        onEndDateSelected(picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Start Date
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.green),
              title: const Text('Start Date *'),
              subtitle: Text(
                '${startDate.day}/${startDate.month}/${startDate.year}',
              ),
              trailing: isDisabled
                  ? null
                  : TextButton(
                      onPressed: () => _selectDate(context, true),
                      child: const Text('Select'),
                    ),
            ),
            const Divider(),
            // End Date (Optional)
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.orange),
              title: const Text('End Date (Optional)'),
              subtitle: Text(
                endDate == null
                    ? 'Not set'
                    : '${endDate!.day}/${endDate!.month}/${endDate!.year}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (endDate != null && !isDisabled)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () => onEndDateSelected(null),
                    ),
                  if (!isDisabled)
                    TextButton(
                      onPressed: () => _selectDate(context, false),
                      child: const Text('Select'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}