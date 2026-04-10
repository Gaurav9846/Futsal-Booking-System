import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/futsal.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/favorite_provider.dart';
import '../../../../utils/responsive.dart';

class FutsalCard extends StatelessWidget {
  final Futsal futsal;
  final VoidCallback onTap;

  const FutsalCard({
    super.key,
    required this.futsal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final amenities = futsal.getAllAmenities();
    final minPrice = futsal.getMinPrice();
    final courtTypes = futsal.getCourtTypes();
    final isDesktop = Responsive.isDesktop(context);
    final imageHeight = Responsive.getCardImageHeight(context);

    return Container(
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          mainAxisSize: MainAxisSize.min, // CRITICAL: Prevents extra space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(15),
                  ),
                  child: futsal.images.isNotEmpty
                      ? Image.network(
                          futsal.images.first,
                          height: imageHeight,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderImage(imageHeight);
                          },
                        )
                      : _buildPlaceholderImage(imageHeight),
                ),
                // Favorite Button
                Positioned(
                  top: 10,
                  right: 10,
                  child: Consumer<FavoriteProvider>(
                    builder: (context, favProvider, child) {
                      final isFav = favProvider.isFavorite(futsal.id);
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : Colors.grey.shade600,
                            size: isDesktop ? 24 : 20,
                          ),
                          onPressed: () async {
                            final auth = Provider.of<AuthProvider>(context,
                                listen: false);
                            if (!auth.isAuthenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Please log in to save favorites'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            final success =
                                await favProvider.toggleFavorite(futsal.id);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isFav
                                        ? 'Removed from favorites'
                                        : 'Added to favorites',
                                  ),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                // Rating Badge
                if (futsal.averageRating != null)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.shade700.withOpacity(0.3),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            futsal.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content Section - Reduced padding
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 20 : 16,  // left
                isDesktop ? 16 : 12,  // top - REDUCED
                isDesktop ? 20 : 16,  // right
                isDesktop ? 16 : 12,  // bottom - REDUCED
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Prevents extra space
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and badges row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          futsal.name,
                          style: TextStyle(
                            fontSize: Responsive.headline2(context),
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: isDesktop ? 2 : 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (courtTypes.isNotEmpty)
                        Wrap(
                          spacing: 4,
                          children: courtTypes.map((type) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, 
                              vertical: 2
                            ),
                            decoration: BoxDecoration(
                              color: type == 'indoor'
                                  ? Colors.blue.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: type == 'indoor'
                                    ? Colors.blue.shade200
                                    : Colors.green.shade200,
                              ),
                            ),
                            child: Text(
                              type == 'indoor' ? 'Indoor' : 'Outdoor',
                              style: TextStyle(
                                fontSize: Responsive.caption(context),
                                color: type == 'indoor'
                                    ? Colors.blue.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )).toList(),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 6), // REDUCED from 8
                  
                  // Location with distance
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: isDesktop ? 18 : 14, // SMALLER
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          futsal.address,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: Responsive.bodyText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (futsal.distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,  // REDUCED from 8
                            vertical: 2,    // REDUCED from 3
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10), // REDUCED from 12
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me,
                                  size: isDesktop ? 12 : 10, // SMALLER
                                  color: Colors.blue.shade600),
                              const SizedBox(width: 2), // REDUCED from 4
                              Text(
                                futsal.distance! < 1
                                    ? '${(futsal.distance! * 1000).round()}m'
                                    : '${futsal.distance!.toStringAsFixed(1)}km',
                                style: TextStyle(
                                  fontSize: Responsive.caption(context) - 1,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 6), // REDUCED from 8
                  
                  // Amenities
                  if (amenities.isNotEmpty)
                    SizedBox(
                      height: isDesktop ? 32 : 28, // REDUCED from 40/32
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: isDesktop 
                            ? amenities.take(4).length 
                            : amenities.take(3).length,
                        itemBuilder: (context, index) {
                          final amenity = amenities[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 6), // REDUCED from 8
                            child: _buildAmenityChip(
                              _getAmenityIcon(amenity),
                              amenity.length > (isDesktop ? 20 : 15)
                                  ? '${amenity.substring(0, isDesktop ? 17 : 12)}...'
                                  : amenity,
                              context,
                            ),
                          );
                        },
                      ),
                    ),
                  
                  const SizedBox(height: 8), // REDUCED from 12
                  
                  // Price and Book Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            minPrice != null ? 'Starting from' : 'Price varies',
                            style: TextStyle(
                              fontSize: Responsive.caption(context) - 1,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          if (minPrice != null)
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'रू ',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontSize: isDesktop ? 20 : 18, // REDUCED
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: minPrice.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: isDesktop ? 24 : 20, // REDUCED
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/hr',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: isDesktop ? 12 : 10, // REDUCED
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'Check availability',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: Responsive.bodyText(context) - 1,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8), // REDUCED from 10
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: isDesktop ? 20 : 16, // REDUCED
                            vertical: isDesktop ? 10 : 8,    // REDUCED
                          ),
                          minimumSize: Size.zero, // Allows button to shrink
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Book Now',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: Responsive.bodyText(context) - 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade100, Colors.green.shade50],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.sports_soccer,
          size: 50,
          color: Colors.green.shade300,
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('water')) return Icons.local_drink;
    if (lower.contains('light')) return Icons.light_mode;
    if (lower.contains('chair') || lower.contains('seating'))
      return Icons.chair;
    if (lower.contains('shower') || lower.contains('changing'))
      return Icons.shower;
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('ac')) return Icons.ac_unit;
    return Icons.fitness_center;
  }

  Widget _buildAmenityChip(IconData icon, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), // REDUCED
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8), // REDUCED from 12
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.grey.shade700), // REDUCED from 12/14
          const SizedBox(width: 3), // REDUCED from 4
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.caption(context) - 1,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}