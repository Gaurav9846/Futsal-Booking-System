import 'package:flutter/material.dart';
import '../../../../utils/responsive.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final chipPadding = isDesktop ? 12.0 : 8.0;
    
    return SizedBox(
      height: Responsive.getFilterChipsHeight(context),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.isDesktop(context) ? 32 : 16,
        ),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          return Padding(
            padding: EdgeInsets.only(right: chipPadding),
            child: FilterChip(
              label: Text(filter),
              selected: selectedFilter == filter,
              onSelected: (selected) {
                if (selected) {
                  onFilterSelected(filter);
                } else {
                  onFilterSelected('All');
                }
              },
              backgroundColor: Colors.white,
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
              labelStyle: TextStyle(
                color: selectedFilter == filter
                    ? Colors.green
                    : Colors.grey.shade700,
                fontWeight: selectedFilter == filter
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: Responsive.bodyText(context),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: selectedFilter == filter
                      ? Colors.green
                      : Colors.grey.shade300,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}