import 'package:flutter/material.dart';
import 'amenities_section.dart';

class CourtDialog {
  static final List<String> _courtTypes = ['indoor', 'outdoor'];
  static final List<String> _availableAmenities = [
    'Lights',
    'Roof',
    'Changing Room',
    'Parking',
    'Drinking Water',
    'Seating',
    'Floodlights',
    'Synthetic Turf',
  ];

  static Future<Map<String, dynamic>?> show({
    required BuildContext context,
    String? initialCourtNumber,
    String? initialCourtType,
    double? initialBasePrice,
    double? initialPeakPrice,
    List<String>? initialAmenities,
  }) async {
    final courtNumberController = TextEditingController(text: initialCourtNumber ?? '');
    final basePriceController = TextEditingController(
      text: initialBasePrice?.toString() ?? '',
    );
    final peakPriceController = TextEditingController(
      text: initialPeakPrice?.toString() ?? '',
    );
    String selectedCourtType = initialCourtType ?? 'indoor';
    List<String> selectedAmenities = List.from(initialAmenities ?? []);

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(initialCourtNumber == null ? 'Add New Court' : 'Edit Court'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Court Number
                  TextField(
                    controller: courtNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Court Number',
                      hintText: 'e.g., 1, 2, A, B',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Court Type
                  DropdownButtonFormField(
                    value: selectedCourtType,
                    items: _courtTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedCourtType = value.toString();
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Court Type',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Base Price
                  TextField(
                    controller: basePriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Base Price (per hour)',
                      prefixText: 'रू ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Peak Price (Optional)
                  TextField(
                    controller: peakPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Peak Price (per hour) - Optional',
                      prefixText: 'रू ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Amenities Section
                  AmenitiesSection(
                    selectedAmenities: selectedAmenities,
                    availableAmenities: _availableAmenities,
                    onChanged: (newList) {
                      setDialogState(() {
                        selectedAmenities = newList;
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CANCEL'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (courtNumberController.text.isEmpty || basePriceController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please fill all required fields'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx, {
                    'courtNumber': courtNumberController.text,
                    'courtType': selectedCourtType,
                    'basePrice': int.parse(basePriceController.text),
                    'peakPrice': peakPriceController.text.isNotEmpty
                        ? int.parse(peakPriceController.text)
                        : null,
                    'amenities': selectedAmenities,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: Text(initialCourtNumber == null ? 'ADD COURT' : 'UPDATE'),
              ),
            ],
          );
        },
      ),
    );
  }
}