// lib/screens/player/futsal_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/futsal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/review_provider.dart';
import '../../providers/favorite_provider.dart';
import 'futsal_details/widgets/futsal_appbar.dart';
import 'futsal_details/widgets/futsal_header.dart';
import 'futsal_details/widgets/futsal_tabs.dart';

class FutsalDetailsScreen extends StatefulWidget {
  final Futsal futsal;
  final int initialTabIndex;

  const FutsalDetailsScreen({
    super.key,
    required this.futsal,
    this.initialTabIndex = 0,
  });

  @override
  State<FutsalDetailsScreen> createState() => _FutsalDetailsScreenState();
}

class _FutsalDetailsScreenState extends State<FutsalDetailsScreen>
    with WidgetsBindingObserver {
  int _selectedImageIndex = 0;
  bool _isProcessing = false;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Check favorite status after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFavoriteStatus();
    });
  }
  
  Future<void> _checkFavoriteStatus() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
      setState(() {
        _isFavorite = favProvider.isFavorite(widget.futsal.id);
      });
    }
  }
  
  Future<void> _toggleFavorite() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showSnackBar('Please log in to save favorites', isError: true);
      return;
    }
    
    final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
    final success = await favProvider.toggleFavorite(widget.futsal.id);
    
    if (success) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      _showSnackBar(
        _isFavorite ? 'Added to favorites' : 'Removed from favorites',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          FutsalAppBar(
            futsal: widget.futsal,
            selectedImageIndex: _selectedImageIndex,
            onPageChanged: (index) {
              if (mounted) {
                setState(() => _selectedImageIndex = index);
              }
            },
            isProcessing: _isProcessing,
            onBack: () => Navigator.pop(context),
            onFavorite: _toggleFavorite,
            onShare: () => _showSnackBar('Share feature coming soon'),
            isFavorite: _isFavorite,
          ),
          FutsalHeader(futsal: widget.futsal),
          SliverFillRemaining(
            child: FutsalTabs(
              futsal: widget.futsal,
              initialTabIndex: widget.initialTabIndex,
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}