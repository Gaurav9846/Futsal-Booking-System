import 'package:flutter/material.dart';

class AmenitiesSection extends StatelessWidget {
  final List<String> selectedAmenities;
  final List<String> availableAmenities;
  final Function(List<String>) onChanged;

  const AmenitiesSection({
    super.key,
    required this.selectedAmenities,
    required this.availableAmenities,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: availableAmenities.map((amenity) {
            final isSelected = selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<String>.from(selectedAmenities);
                if (selected) {
                  newList.add(amenity);
                } else {
                  newList.remove(amenity);
                }
                onChanged(newList);
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
              labelStyle: TextStyle(
                color: isSelected ? Colors.green : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.green : Colors.grey.shade300,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}