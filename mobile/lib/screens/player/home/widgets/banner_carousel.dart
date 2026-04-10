import 'package:flutter/material.dart';
import '../../../../utils/app_theme.dart';
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
    Future.delayed(const Duration(seconds: 4), _autoScrollBanner);
  }

  void _autoScrollBanner() {
    if (!mounted) return;
    if (widget.pageController.hasClients) {
      _currentBanner = (_currentBanner + 1) % widget.banners.length;
      widget.pageController.animateToPage(
        _currentBanner,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
      Future.delayed(const Duration(seconds: 4), _autoScrollBanner);
    } else {
      Future.delayed(const Duration(milliseconds: 100), _autoScrollBanner);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
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
              return AnimatedBuilder(
                animation: widget.pageController,
                builder: (context, child) {
                  double scale = 1.0;
                  if (widget.pageController.position.haveDimensions) {
                    final page = widget.pageController.page ?? 0;
                    scale = (1 - (page - index).abs() * 0.1).clamp(0.9, 1.0);
                  }
                  return Transform.scale(
                    scale: scale,
                    child: BannerCard(
                      banner: banner,
                      index: index,
                      currentIndex: _currentBanner,
                    ),
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildPageIndicator(),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.banners.length, (index) {
        final isActive = _currentBanner == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: isActive ? AppTheme.primaryGradient : null,
            color: isActive ? null : AppTheme.surfaceBorder,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }
}
