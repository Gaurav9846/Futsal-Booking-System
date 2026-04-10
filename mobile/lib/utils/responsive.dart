import 'package:flutter/material.dart';

class Responsive {
  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1200;
  
  // Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;
  
  // Get screen dimensions
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
  
  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
  
  // Responsive padding
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    } else if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    } else {
      return const EdgeInsets.all(16);
    }
  }
  
  // Responsive font sizes
  static double headline1(BuildContext context) {
    if (isDesktop(context)) return 32;
    if (isTablet(context)) return 28;
    return 24;
  }
  
  static double headline2(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 22;
    return 20;
  }
  
  static double bodyText(BuildContext context) {
    if (isDesktop(context)) return 16;
    if (isTablet(context)) return 15;
    return 14;
  }
  
  static double caption(BuildContext context) {
    if (isDesktop(context)) return 14;
    return 12;
  }
  
  // Grid configuration
  static int getGridCrossAxisCount(BuildContext context) {
    if (isDesktop(context)) return 3;
    if (isTablet(context)) return 2;
    return 1;
  }
  
static double getGridChildAspectRatio(BuildContext context) {
  // Make cards shorter (smaller ratio = taller card = less white space)
  if (isDesktop(context)) return 0.6;   // Changed from 0.7
  if (isTablet(context)) return 0.65;   // Changed from 0.75
  return 0.7;                            // Changed from 0.8
}
  
  static double getGridSpacing(BuildContext context) {
    if (isDesktop(context)) return 24;
    if (isTablet(context)) return 20;
    return 16;
  }
  
  // Banner height
  static double getBannerHeight(BuildContext context) {
    if (isDesktop(context)) return 220;
    if (isTablet(context)) return 180;
    return 150;
  }
  
  // AppBar expanded height
  static double getAppBarExpandedHeight(BuildContext context) {
    if (isDesktop(context)) return 200;
    if (isTablet(context)) return 180;
    return 160;
  }
  
  // Card image height
  static double getCardImageHeight(BuildContext context) {
    if (isDesktop(context)) return 220;
    if (isTablet(context)) return 200;
    return 180;
  }
  
  // Filter chips height
  static double getFilterChipsHeight(BuildContext context) => 50;
  
  // Check orientation
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;
  
  // Adaptive layout: return different widgets based on screen size
  static Widget adaptiveLayout({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
}