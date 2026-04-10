import 'package:flutter/material.dart';
import '/models/futsal.dart';

class FutsalAppBar extends StatelessWidget {
  final Futsal futsal;
  final int selectedImageIndex;
  final Function(int) onPageChanged;
  final bool isProcessing;
  final VoidCallback onBack;
  final VoidCallback onFavorite;
  final VoidCallback onShare;
  final bool isFavorite;

  const FutsalAppBar({
    super.key,
    required this.futsal,
    required this.selectedImageIndex,
    required this.onPageChanged,
    required this.isProcessing,
    required this.onBack,
    required this.onFavorite,
    required this.onShare,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.green,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            _buildImagePageView(),
            _buildImageIndicators(),
            _buildGradient(),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack,
      ),
      actions: [
        IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: Colors.white,
          ),
          onPressed: isProcessing ? null : onFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: isProcessing ? null : onShare,
        ),
      ],
    );
  }

  Widget _buildImagePageView() {
    return PageView.builder(
      itemCount: futsal.images.isNotEmpty ? futsal.images.length : 1,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        return futsal.images.isNotEmpty
            ? Image.network(
                futsal.images[index],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder();
      },
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.green.shade200,
      child: Center(
        child: Icon(
          Icons.sports_soccer,
          size: 80,
          color: Colors.green.shade400,
        ),
      ),
    );
  }

  Widget _buildImageIndicators() {
    return Positioned(
      bottom: 16,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          futsal.images.isNotEmpty ? futsal.images.length : 1,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selectedImageIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}