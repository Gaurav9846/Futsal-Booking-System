import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/futsal.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/favorite_provider.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/app_theme.dart';

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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.surfaceBorder, width: 1),
        boxShadow: AppTheme.cardShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusLarge),
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
                
                // Gradient overlay at bottom
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppTheme.surface.withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Court type badges
                if (courtTypes.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: courtTypes.map((type) {
                        final isIndoor = type == 'indoor';
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isIndoor 
                                ? AppTheme.indoor.withOpacity(0.9) 
                                : AppTheme.outdoor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isIndoor ? Icons.house : Icons.wb_sunny,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isIndoor ? 'Indoor' : 'Outdoor',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                
                // Favorite Button
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<FavoriteProvider>(
                    builder: (context, favProvider, child) {
                      final isFav = favProvider.isFavorite(futsal.id);
                      return Container(
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? AppTheme.error : AppTheme.textSecondary,
                            size: isDesktop ? 22 : 20,
                          ),
                          onPressed: () async {
                            final auth = Provider.of<AuthProvider>(context, listen: false);
                            if (!auth.isAuthenticated) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                                      SizedBox(width: 12),
                                      Text('Please log in to save favorites'),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.warning,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
                                ),
                              );
                              return;
                            }

                            final success = await favProvider.toggleFavorite(futsal.id);
                            if (success && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(
                                        isFav ? Icons.heart_broken : Icons.favorite,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        isFav ? 'Removed from favorites' : 'Added to favorites',
                                      ),
                                    ],
                                  ),
                                  backgroundColor: AppTheme.success,
                                  duration: const Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                  ),
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
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.warning,
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.warning.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            futsal.averageRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Content Section
            Padding(
              padding: EdgeInsets.all(isDesktop ? 20 : 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    futsal.name,
                    style: TextStyle(
                      fontSize: Responsive.headline2(context),
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: isDesktop ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Location with distance
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          size: 14,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          futsal.address,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: Responsive.bodyText(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (futsal.distance != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.info.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                            border: Border.all(
                              color: AppTheme.info.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.near_me,
                                size: 12,
                                color: AppTheme.info,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                futsal.distance! < 1
                                    ? '${(futsal.distance! * 1000).round()}m'
                                    : '${futsal.distance!.toStringAsFixed(1)}km',
                                style: TextStyle(
                                  fontSize: Responsive.caption(context),
                                  color: AppTheme.info,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Amenities
                  if (amenities.isNotEmpty)
                    SizedBox(
                      height: isDesktop ? 34 : 30,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: isDesktop
                            ? amenities.take(4).length
                            : amenities.take(3).length,
                        itemBuilder: (context, index) {
                          final amenity = amenities[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildAmenityChip(
                              _getAmenityIcon(amenity),
                              amenity.length > (isDesktop ? 20 : 12)
                                  ? '${amenity.substring(0, isDesktop ? 17 : 9)}...'
                                  : amenity,
                              context,
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Divider
                  Container(
                    height: 1,
                    color: AppTheme.surfaceBorder,
                  ),

                  const SizedBox(height: 16),

                  // Price and Book Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            minPrice != null ? 'Starting from' : 'Price varies',
                            style: TextStyle(
                              fontSize: Responsive.caption(context),
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (minPrice != null)
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Rs ',
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: isDesktop ? 16 : 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  TextSpan(
                                    text: minPrice.toStringAsFixed(0),
                                    style: TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: isDesktop ? 24 : 20,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '/hr',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: isDesktop ? 12 : 11,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'Check availability',
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: Responsive.bodyText(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                          boxShadow: AppTheme.primaryShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: isDesktop ? 24 : 20,
                              vertical: isDesktop ? 14 : 12,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Book Now',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: Responsive.bodyText(context),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward, size: 16),
                            ],
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
          colors: [
            AppTheme.primary.withOpacity(0.2),
            AppTheme.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 48,
              color: AppTheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No Image',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    final lower = amenity.toLowerCase();
    if (lower.contains('parking')) return Icons.local_parking;
    if (lower.contains('water')) return Icons.local_drink;
    if (lower.contains('light')) return Icons.light_mode;
    if (lower.contains('chair') || lower.contains('seating')) return Icons.chair;
    if (lower.contains('shower') || lower.contains('changing')) return Icons.shower;
    if (lower.contains('wifi')) return Icons.wifi;
    if (lower.contains('ac')) return Icons.ac_unit;
    if (lower.contains('locker')) return Icons.lock;
    if (lower.contains('cafe') || lower.contains('food')) return Icons.restaurant;
    return Icons.check_circle_outline;
  }

  Widget _buildAmenityChip(IconData icon, String label, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
        border: Border.all(color: AppTheme.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.caption(context),
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
