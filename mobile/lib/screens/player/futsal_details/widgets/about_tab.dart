// lib/screens/player/futsal_details/widgets/about_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/futsal.dart';
import '../../../../models/court.dart';
import '../../../../providers/court_provider.dart';

class AboutTab extends StatelessWidget {
  final Futsal futsal;
  final bool isLoading;

  const AboutTab({
    super.key,
    required this.futsal,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final courtProvider = Provider.of<CourtProvider>(context);
    final courts = courtProvider.courts;

    if (isLoading || courtProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.green),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (futsal.description?.isNotEmpty ?? false) ...[
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            futsal.description!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Facilities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildFacilitiesWrap(courts),
        const SizedBox(height: 20),
        const Text(
          'Courts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildCourtsList(courts),
        const SizedBox(height: 20),
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildMapPlaceholder(),
        const SizedBox(height: 20),
        const Text(
          'Operating Hours',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildOperatingHours(),
      ],
    );
  }

  Widget _buildFacilitiesWrap(List<Court> courts) {
    // Get all unique amenities from all courts
    final Set<String> allAmenities = {};
    for (var court in courts) {
      allAmenities.addAll(court.amenities);
    }
    
    // Convert to list and add court count
    final facilities = <String>[];
    facilities.add('${courts.length} Courts');
    facilities.addAll(allAmenities.toList());
    
    if (facilities.isEmpty) {
      return const Text('No facilities listed');
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: facilities.map((facility) {
        return _buildFacilityChip(
          _getFacilityIcon(facility),
          facility,
        );
      }).toList(),
    );
  }

  IconData _getFacilityIcon(String facility) {
    final lower = facility.toLowerCase();
    if (lower.contains('court')) return Icons.sports_soccer;
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('water')) return Icons.local_drink;
    if (lower.contains('light')) return Icons.light_mode;
    if (lower.contains('chair') || lower.contains('seating')) return Icons.chair;
    if (lower.contains('shower') || lower.contains('changing')) return Icons.shower;
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('ac') || lower.contains('air')) return Icons.ac_unit;
    if (lower.contains('floodlight')) return Icons.light;
    return Icons.fitness_center;
  }

  Widget _buildFacilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtsList(List<Court> courts) {
    if (courts.isEmpty) {
      return const Text('No courts available');
    }
    
    return Column(
      children: courts.map((court) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              court.courtType == 'indoor' ? Icons.sports_soccer : Icons.grass,
              color: Colors.green,
            ),
            title: Text('Court ${court.courtNumber}'),
            subtitle: Text(
              '${court.courtTypeDisplay} • रू${court.basePrice}/hr${court.hasPeakPricing ? ' (Peak: रू${court.peakPrice})' : ''}',
            ),
            trailing: court.isUnderMaintenance
                ? const Chip(
                    label: Text('Maintenance'),
                    backgroundColor: Colors.orange,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 10),
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMapPlaceholder() {
    if (futsal.latitude != null && futsal.longitude != null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map, size: 50, color: Colors.grey.shade400),
              const SizedBox(height: 8),
              Text(
                '${futsal.latitude}, ${futsal.longitude}',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: Open in Google Maps
                },
                child: const Text('Open in Maps'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Location not available', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

Widget _buildOperatingHours() {
  // Check if operating hours exist
  if (futsal.operatingHours == null || futsal.operatingHours!.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          'Operating hours not set',
          style: TextStyle(color: Colors.grey),
        ),
      ),
    );
  }

  // Days of the week
  final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
  final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: List.generate(days.length, (index) {
        final day = days[index];
        final dayName = dayNames[index];
        final hours = futsal.operatingHours![day];
        
        // If no hours for this day, show as Closed
        if (hours == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                const Text('Closed', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        
        // Display hours
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dayName, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${hours['open']} - ${hours['close']}'),
            ],
          ),
        );
      }),
    ),
  );
}
}