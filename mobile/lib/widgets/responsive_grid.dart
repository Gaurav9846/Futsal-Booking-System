import 'package:flutter/material.dart';
import '../utils/responsive.dart';

class ResponsiveGridView<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final double? childAspectRatio;
  final int? crossAxisCount;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const ResponsiveGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.childAspectRatio,
    this.crossAxisCount,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      padding: padding ?? Responsive.getScreenPadding(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount ?? Responsive.getGridCrossAxisCount(context),
        childAspectRatio: childAspectRatio ?? Responsive.getGridChildAspectRatio(context),
        crossAxisSpacing: crossAxisSpacing ?? Responsive.getGridSpacing(context),
        mainAxisSpacing: mainAxisSpacing ?? Responsive.getGridSpacing(context),
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => itemBuilder(context, items[index], index),
    );
  }
}