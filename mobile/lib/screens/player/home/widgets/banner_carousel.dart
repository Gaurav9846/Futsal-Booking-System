import 'package:flutter/material.dart';
import 'banner_card.dart';

class BannerCarousel extends StatefulWidget {
  final List<Map<String, String>> banners;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const BannerCarousel({
    super.key,
    required this.banners,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentBanner = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), _autoScrollBanner);
  }

  void _autoScrollBanner() {
    if (!mounted) return;
    if (widget.pageController.hasClients) {
      _currentBanner = (_currentBanner + 1) % widget.banners.length;
      widget.pageController.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      Future.delayed(const Duration(seconds: 3), _autoScrollBanner);
    } else {
      Future.delayed(const Duration(milliseconds: 100), _autoScrollBanner);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: widget.pageController,
      itemCount: widget.banners.length,
      onPageChanged: (index) {
        setState(() {
          _currentBanner = index;
        });
        widget.onPageChanged(index);
      },
      itemBuilder: (context, index) {
        final banner = widget.banners[index];
        return BannerCard(
          banner: banner,
          index: index,
          currentIndex: _currentBanner,
        );
      },
    );
  }
}