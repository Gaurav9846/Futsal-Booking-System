import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ResponsiveSliverGrid<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double? childAspectRatio;
  final int? crossAxisCount;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final EdgeInsetsGeometry? padding;

  const ResponsiveSliverGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.childAspectRatio,
    this.crossAxisCount,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: padding ?? Responsive.getScreenPadding(context),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount ?? Responsive.getGridCrossAxisCount(context),
          childAspectRatio: childAspectRatio ?? Responsive.getGridChildAspectRatio(context),
          crossAxisSpacing: crossAxisSpacing ?? Responsive.getGridSpacing(context),
          mainAxisSpacing: mainAxisSpacing ?? Responsive.getGridSpacing(context),
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => itemBuilder(context, items[index], index),
          childCount: items.length,
        ),
      ),
    );
  }
}