import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';
import '../../../../utils/app_theme.dart';

class FilterChips extends StatelessWidget {
  final List<String> filters;
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const FilterChips({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  IconData _getFilterIcon(String filter) {
    switch (filter.toLowerCase()) {
      case 'all':
        return Icons.grid_view_rounded;
      case 'popular':
        return Icons.trending_up;
      case 'indoor':
        return Icons.house;
      case 'outdoor':
        return Icons.wb_sunny;
      default:
        return Icons.sports_soccer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    
    return SizedBox(
      height: Responsive.getFilterChipsHeight(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
        ),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          
          return Padding(
            padding: EdgeInsets.only(right: isDesktop ? 12 : 8),
            child: GestureDetector(
              onTap: () {
                if (isSelected) {
                  onFilterSelected('All');
                } else {
                  onFilterSelected(filter);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 20 : 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppTheme.primary 
                      : AppTheme.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusRound),
                  border: Border.all(
                    color: isSelected 
                        ? AppTheme.primary 
                        : AppTheme.surfaceBorder,
                    width: 1,
                  ),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFilterIcon(filter),
                      size: 16,
                      color: isSelected 
                          ? Colors.white 
                          : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      filter,
                      style: TextStyle(
                        color: isSelected 
                            ? Colors.white 
                            : AppTheme.textSecondary,
                        fontWeight: isSelected 
                            ? FontWeight.w600 
                            : FontWeight.w500,
                        fontSize: Responsive.bodyText(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
