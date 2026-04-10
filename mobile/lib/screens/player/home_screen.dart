import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/responsive.dart';
import '../../providers/auth_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../models/futsal.dart';
import '../../models/user.dart';
import 'futsal_details_screen.dart';
import '../../providers/favorite_provider.dart';
import 'home/widgets/filter_chips.dart';
import 'home/widgets/banner_card.dart';
import 'home/widgets/filter_panel.dart';
import 'home/widgets/futsal_card.dart';
import '../../widgets/profile/profile_dialog.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/search_bar.dart';
import 'home/widgets/home_app_bar.dart';
import 'home/widgets/banner_carousel.dart';

class PlayerHomeScreen extends StatefulWidget {
  const PlayerHomeScreen({super.key});

  @override
  State<PlayerHomeScreen> createState() => _PlayerHomeScreenState();
}

class _PlayerHomeScreenState extends State<PlayerHomeScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _showFilters = false;

  // Location state
  Position? _userPosition;
  bool _isGettingLocation = false;
  double _distanceRadius = 5.0;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<String> _filters = ['All', 'Popular'];

  final List<Map<String, String>> _banners = [
    {
      'title': 'Weekend Special',
      'subtitle': '20% off on all bookings',
      'image': '🎯',
      'color': 'FF6B6B',
    },
    {
      'title': 'New Venues',
      'subtitle': 'Check out newly added futsals',
      'image': '⚽',
      'color': '4ECDC4',
    },
    {
      'title': 'Tournament Season',
      'subtitle': 'Book now for tournaments',
      'image': '🏆',
      'color': '45B7D1',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadFutsals();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFutsals() async {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await futsalProvider.fetchFutsals();
    _updateFilters();

    if (auth.isAuthenticated) {
      final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
      await favProvider.loadFavorites();
    }
  }

  void _updateFilters() {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    final Set<String> filterSet = {'All', 'Popular'};

    for (var futsal in futsalProvider.futsals) {
      final courtTypes = futsal.getCourtTypes();
      filterSet
          .addAll(courtTypes.map((t) => t == 'indoor' ? 'Indoor' : 'Outdoor'));
    }

    setState(() {
      _filters = filterSet.toList();
    });
  }

  Future<void> _getUserLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Enable in settings.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );

      setState(() {
        _userPosition = position;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Location set! Showing futsals within $_distanceRadius km'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  double _calculateDistance(
      double lat1, double lng1, double lat2, double lng2) {
    const R = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  List<Futsal> get _filteredFutsals {
    final futsalProvider = Provider.of<FutsalProvider>(context, listen: false);
    var futsals = futsalProvider.futsals;

    if (_searchQuery.isNotEmpty) {
      futsals = futsals.where((f) {
        return f.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            f.address.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedFilter != 'All' && _selectedFilter != 'Popular') {
      final filterLower = _selectedFilter.toLowerCase();
      futsals = futsals.where((f) {
        final courtTypes = f.getCourtTypes();
        return courtTypes.contains(filterLower);
      }).toList();
    }

    if (_userPosition != null) {
      for (var futsal in futsals) {
        if (futsal.latitude != null && futsal.longitude != null) {
          futsal.distance = _calculateDistance(
            _userPosition!.latitude,
            _userPosition!.longitude,
            futsal.latitude!,
            futsal.longitude!,
          );
        }
      }

      futsals = futsals.where((f) {
        return f.distance == null || f.distance! <= _distanceRadius;
      }).toList();

      futsals.sort((a, b) {
        final aDist = a.distance ?? double.infinity;
        final bDist = b.distance ?? double.infinity;
        return aDist.compareTo(bDist);
      });
    }

    if (_selectedFilter == 'Popular') {
      futsals.sort((a, b) {
        return (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
      });
    }

    return futsals;
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final futsalProvider = Provider.of<FutsalProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: () async {
          final futsalProvider =
              Provider.of<FutsalProvider>(context, listen: false);
          final auth = Provider.of<AuthProvider>(context, listen: false);

          await futsalProvider.fetchFutsals();
          _updateFilters();

          if (auth.isAuthenticated) {
            await Provider.of<FavoriteProvider>(context, listen: false)
                .loadFavorites();
          }
        },
        child: CustomScrollView(
          slivers: [
            HomeAppBar(
              user: auth.user!,
              isOwner: auth.isOwner,
              showFilters: _showFilters,
              onFilterToggle: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
              onSwitchToOwner: () {
                Navigator.pushReplacementNamed(context, '/owner/dashboard');
              },
            ),

            // Search Bar - Responsive padding
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Padding(
                  padding: Responsive.getScreenPadding(context).copyWith(
                    top: 16,
                    bottom: 8,
                  ),
                  child: CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Search by name or location...',
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  ),
                ),
              ),
            ),

            // Filter Panel
            SliverToBoxAdapter(
              child: _showFilters
                  ? Padding(
                      padding: Responsive.getScreenPadding(context),
                      child: FilterPanel(
                        userPosition: _userPosition,
                        isGettingLocation: _isGettingLocation,
                        distanceRadius: _distanceRadius,
                        onGetLocation: _getUserLocation,
                        onDistanceChanged: (value) {
                          setState(() {
                            _distanceRadius = value;
                          });
                        },
                      ),
                    )
                  : const SizedBox.shrink(),
            ),

            // Banner Section - Responsive height
            SliverToBoxAdapter(
              child: SizedBox(
                height: Responsive.getBannerHeight(context),
                child: BannerCarousel(
                  banners: _banners,
                  pageController: _bannerController,
                  onPageChanged: (index) {
                    // Optional: handle page change if needed
                  },
                ),
              ),
            ),

            // Filter Chips - Responsive padding
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: FilterChips(
                  filters: _filters,
                  selectedFilter: _selectedFilter,
                  onFilterSelected: (filter) {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                ),
              ),
            ),

            // Responsive Futsals Grid - Using GridView for proper layout
            _buildResponsiveFutsalsGrid(futsalProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveFutsalsGrid(FutsalProvider provider) {
  if (provider.isLoading && provider.futsals.isEmpty) {
    return const SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading futsals...'),
          ],
        ),
      ),
    );
  }

  if (provider.error != null) {
    return SliverFillRemaining(
      child: EmptyState.error(
        provider.error!,
        onRetry: _loadFutsals,
      ),
    );
  }

  final filteredList = _filteredFutsals;

  if (filteredList.isEmpty) {
    return SliverFillRemaining(
      child: _searchQuery.isEmpty
          ? EmptyState.noFutsals()
          : EmptyState.noSearchResults(
              onClearFilters: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'All';
                });
              },
            ),
    );
  }

  // Get responsive grid settings
  final isDesktop = Responsive.isDesktop(context);
  final isTablet = Responsive.isTablet(context);
  
  int crossAxisCount;
  double crossAxisSpacing;
  double mainAxisSpacing;
  double horizontalPadding;
  
  if (isDesktop) {
    crossAxisCount = 3;
    crossAxisSpacing = 20;
    mainAxisSpacing = 20;
    horizontalPadding = 32;
  } else if (isTablet) {
    crossAxisCount = 2;
    crossAxisSpacing = 16;
    mainAxisSpacing = 16;
    horizontalPadding = 24;
  } else {
    crossAxisCount = 1;
    crossAxisSpacing = 0;
    mainAxisSpacing = 12;
    horizontalPadding = 16;
  }

  // Use SliverList with Row for dynamic heights (no forced aspect ratio)
  return SliverPadding(
    padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
    sliver: SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, rowIndex) {
          // Calculate items for this row
          final startIndex = rowIndex * crossAxisCount;
          final endIndex = startIndex + crossAxisCount;
          
          if (startIndex >= filteredList.length) return null;
          
          final rowItems = filteredList.sublist(
            startIndex,
            endIndex > filteredList.length ? filteredList.length : endIndex,
          );
          
          return Padding(
            padding: EdgeInsets.only(bottom: mainAxisSpacing),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < rowItems.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < rowItems.length - 1 ? crossAxisSpacing : 0,
                      ),
                      child: FutsalCard(
                        futsal: rowItems[i],
                        onTap: () => _navigateToDetails(rowItems[i]),
                      ),
                    ),
                  ),
                // Add empty placeholders to maintain row structure
                for (int i = rowItems.length; i < crossAxisCount; i++)
                  Expanded(child: SizedBox.shrink()),
              ],
            ),
          );
        },
        childCount: (filteredList.length / crossAxisCount).ceil(),
      ),
    ),
  );
}

  void _navigateToDetails(Futsal futsal) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to book a futsal'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FutsalDetailsScreen(
          futsal: futsal,
          initialTabIndex: 1,
        ),
      ),
    );
  }
}
