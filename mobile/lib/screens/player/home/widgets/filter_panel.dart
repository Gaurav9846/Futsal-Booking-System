import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../utils/responsive.dart';

class FilterPanel extends StatelessWidget {
  final Position? userPosition;
  final bool isGettingLocation;
  final double distanceRadius;
  final VoidCallback onGetLocation;
  final ValueChanged<double> onDistanceChanged;

  const FilterPanel({
    super.key,
    required this.userPosition,
    required this.isGettingLocation,
    required this.distanceRadius,
    required this.onGetLocation,
    required this.onDistanceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Location button
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 20, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  userPosition != null
                      ? 'Showing futsals within $distanceRadius km'
                      : 'Enable location to find futsals near you',
                  style: TextStyle(
                    fontSize: Responsive.bodyText(context),
                    color: userPosition != null
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                ),
              ),
              if (isGettingLocation)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: onGetLocation,
                  child: Text(
                    userPosition != null ? 'Update' : 'Use My Location',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: Responsive.bodyText(context),
                    ),
                  ),
                ),
            ],
          ),

          // Distance slider (only show if location is set)
          if (userPosition != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Within $distanceRadius km',
                  style: TextStyle(fontSize: Responsive.bodyText(context)),
                ),
              ],
            ),
            Slider(
              value: distanceRadius,
              min: 1,
              max: 20,
              divisions: 19,
              activeColor: Colors.green,
              onChanged: onDistanceChanged,
            ),
          ],
        ],
      ),
    );
  }
}