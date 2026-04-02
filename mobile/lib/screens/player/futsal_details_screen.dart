import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/futsal.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../utils/date_formatter.dart';
import '../../services/payment_service.dart';
import '../../services/api_service.dart';
import 'payment_webview_screen.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import '../../providers/review_provider.dart';
import '../../models/review.dart';

// ============================================================================
// CONSTANTS
// ============================================================================
class _Constants {
  static const int maxBookingHours = 4;
  static const int lockDurationMinutes = 5;
  static const int peakHourStart = 17;
  static const int peakHourEnd = 20;
  static const int slotGridCrossAxisCount = 3;
  static const double slotAspectRatio = 1.2;
  static const Duration apiTimeout = Duration(seconds: 15);
  static const Duration snackBarDuration = Duration(seconds: 2);

  // Peak identification
  static bool isPeakHour(int hour, int weekday) {
    final isWeekend =
        weekday == DateTime.saturday || weekday == DateTime.sunday;
    final isPeakHour = hour >= peakHourStart && hour < peakHourEnd;
    return isPeakHour || isWeekend;
  }
}

// ============================================================================
// MAIN SCREEN
// ============================================================================
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
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // ==========================================================================
  // CONTROLLERS
  // ==========================================================================
  late TabController _tabController;
  int _selectedImageIndex = 0;
  DateTime _selectedDate = DateTime.now();

  // ==========================================================================
  // SLOTS STATE
  // ==========================================================================
  List<Map<String, dynamic>> _slots = [];
  bool _isLoadingSlots = false;
  String? _slotsError;
  Map<String, dynamic>? _selectedSlot;

  // ==========================================================================
  // LOCK STATE - SINGLE SOURCE OF TRUTH
  // ==========================================================================
  final Map<int, DateTime> _temporaryLocks = {}; // slotId -> expiry time
  Map<String, dynamic>? _tempLockedSlot; // Current booking flow lock
  Timer? _lockCleanupTimer;
  bool _isProcessing = false; // Prevents double taps

  // ==========================================================================
  // BOOKING STATE
  // ==========================================================================
  int? _tempSelectedDuration;
  int? _tempBookingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _initializeControllers();
    _startLockCleanupTimer();
    _fetchSlots();
    _loadReviewData();
  }

  void _initializeControllers() {
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  void _loadReviewData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      reviewProvider.loadReviews(widget.futsal.id);
      reviewProvider.checkCanReview(widget.futsal.id);
    });
  }

  // ==========================================================================
  // LOCK MANAGEMENT
  // ==========================================================================
  void _startLockCleanupTimer() {
    _lockCleanupTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _cleanupExpiredLocks();
    });
  }

  void _cleanupExpiredLocks() {
    final now = DateTime.now();
    setState(() {
      _temporaryLocks.removeWhere((_, expiry) => expiry.isBefore(now));
    });
  }

  bool _isSlotTemporarilyLocked(int slotId) {
    final expiry = _temporaryLocks[slotId];
    if (expiry == null) return false;
    if (expiry.isBefore(DateTime.now())) {
      // Clean up expired lock
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _temporaryLocks.remove(slotId));
        }
      });
      return false;
    }
    return true;
  }

  void _addTemporaryLock(int slotId) {
    setState(() {
      _temporaryLocks[slotId] = DateTime.now().add(
        Duration(minutes: _Constants.lockDurationMinutes),
      );
    });
  }

  // ==========================================================================
  // SLOT FETCHING
  // ==========================================================================
  Future<void> _fetchSlots() async {
    if (!mounted) return;

    setState(() {
      _isLoadingSlots = true;
      _slotsError = null;
      _selectedSlot = null;
    });

    try {
      final futsalProvider =
          Provider.of<FutsalProvider>(context, listen: false);
      final fetchedSlots = await futsalProvider
          .fetchFutsalSlots(
            widget.futsal.id,
            _selectedDate,
          )
          .timeout(
            _Constants.apiTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );

      if (!mounted) return;

      setState(() {
        _slots = fetchedSlots;
        _isLoadingSlots = false;
      });
    } on TimeoutException catch (_) {
      if (!mounted) return;
      setState(() {
        _slotsError = 'Connection timeout. Please try again.';
        _isLoadingSlots = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _slotsError = 'Failed to load slots: ${e.toString()}';
        _isLoadingSlots = false;
      });
    }
  }

  // ==========================================================================
  // SLOT HELPERS
  // ==========================================================================
  bool _isSlotPeak(Map<String, dynamic> slot) {
    try {
      final timeStr = slot['startTime'] as String? ?? '00:00';
      final hour = int.tryParse(timeStr.split(':').first) ?? 0;
      return _Constants.isPeakHour(hour, _selectedDate.weekday);
    } catch (e) {
      return false;
    }
  }

  bool _isSlotBooked(Map<String, dynamic> slot) {
    final status = slot['status'] as String? ?? '';
    return status == 'BOOKED' || status == 'CONFIRMED' || status == 'COMPLETED';
  }

  bool _isSlotAvailable(Map<String, dynamic> slot) {
    final status = slot['status'] as String? ?? '';
    return status == 'AVAILABLE';
  }

  bool _isSlotLockedBySystem(Map<String, dynamic> slot) {
    final status = slot['status'] as String? ?? '';
    if (status != 'LOCKED') return false;

    try {
      final lockedUntil = slot['lockedUntil'] != null
          ? DateTime.parse(slot['lockedUntil'])
          : null;
      return lockedUntil != null && lockedUntil.isAfter(DateTime.now());
    } catch (e) {
      return true;
    }
  }

  bool _canSelectSlot(Map<String, dynamic> slot) {
    final slotId = slot['id'] as int? ?? 0;
    final isAvailable = _isSlotAvailable(slot);
    final isTemporarilyLocked = _isSlotTemporarilyLocked(slotId);
    final isSystemLocked = _isSlotLockedBySystem(slot);

    return isAvailable && !isTemporarilyLocked && !isSystemLocked;
  }

  // ==========================================================================
  // SLOT SELECTION
  // ==========================================================================
  void _selectSlot(Map<String, dynamic> slot) {
    if (_isProcessing) return; // Prevent during booking flow

    setState(() {
      if (_selectedSlot != null && _selectedSlot!['id'] == slot['id']) {
        _selectedSlot = null; // Deselect
      } else {
        _selectedSlot = slot; // Select
      }
    });
  }

  // ==========================================================================
  // BOOKING FLOW - CLEAN STATE MANAGEMENT
  // ==========================================================================
  Future<void> _proceedToBooking() async {
    if (_selectedSlot == null || _isProcessing) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (!auth.isAuthenticated) {
      _showSnackBar('Please log in to make a booking', isError: true);
      return;
    }

    _showConfirmationDialog();
  }

  void _showConfirmationDialog() {
    if (_selectedSlot == null || _isProcessing) return;

    final price = _getSlotPrice(_selectedSlot!);
    int selectedDuration = 1;

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Confirm Booking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogDetails(),
                const SizedBox(height: 16),
                _buildDialogDurationSelector(
                  selectedDuration: selectedDuration,
                  price: price,
                  onDurationChanged: (newDuration) {
                    setDialogState(() => selectedDuration = newDuration);
                  },
                ),
                const SizedBox(height: 8),
                _buildDialogTotal(price * selectedDuration),
              ],
            ),
            actions: [
              TextButton(
                onPressed:
                    _isProcessing ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () {
                        Navigator.pop(dialogContext);
                        _tempSelectedDuration = selectedDuration;
                        _lockSlotAndShowPayment();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================================
// HELPER METHODS
// ==========================================================================
  String _getCourtNumber(Map<String, dynamic> slot) {
    // Try all possible court key names
    if (slot.containsKey('court')) {
      return 'Court ${slot['court']}';
    } else if (slot.containsKey('courtNumber')) {
      return 'Court ${slot['courtNumber']}';
    } else if (slot.containsKey('court_no')) {
      return 'Court ${slot['court_no']}';
    } else if (slot.containsKey('courtId')) {
      return 'Court ${slot['courtId']}';
    } else if (slot.containsKey('court_id')) {
      return 'Court ${slot['court_id']}';
    } else if (slot.containsKey('court_number')) {
      return 'Court ${slot['court_number']}';
    } else {
      // If no court key found, check if there's a nested court object
      if (slot.containsKey('courtDetails') && slot['courtDetails'] is Map) {
        final courtDetails = slot['courtDetails'] as Map;
        if (courtDetails.containsKey('number')) {
          return 'Court ${courtDetails['number']}';
        }
      }

      print('⚠️ No court number found in slot: ${slot.keys}');
      return 'Court 1'; // Default fallback
    }
  }

  Widget _buildDialogDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          _buildDetailRow(Icons.calendar_today,
              DateFormatter.formatDateFull(_selectedDate)),
          const SizedBox(height: 8),
          _buildDetailRow(Icons.access_time, _selectedSlot!['startTime']),
          const SizedBox(height: 8),
          _buildDetailRow(
              Icons.sports_soccer, 'Court ${_selectedSlot!['courtNumber']}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.green),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  Widget _buildDialogDurationSelector({
    required int selectedDuration,
    required num price,
    required Function(int) onDurationChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Duration (hours)'),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: selectedDuration > 1
                        ? () => onDurationChanged(selectedDuration - 1)
                        : null,
                    color: selectedDuration > 1 ? Colors.green : Colors.grey,
                  ),
                  Container(
                    width: 40,
                    alignment: Alignment.center,
                    child: Text(
                      '$selectedDuration',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: selectedDuration < _Constants.maxBookingHours
                        ? () => onDurationChanged(selectedDuration + 1)
                        : null,
                    color: selectedDuration < _Constants.maxBookingHours
                        ? Colors.green
                        : Colors.grey,
                  ),
                ],
              ),
            ],
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Price per hour'),
                  if (_isSlotPeak(_selectedSlot!)) _buildPeakChip(),
                ],
              ),
              Text(
                'रू ${price.toStringAsFixed(0)}',
                style: TextStyle(
                  color: _isSlotPeak(_selectedSlot!)
                      ? Colors.red.shade700
                      : Colors.black,
                  fontWeight: _isSlotPeak(_selectedSlot!)
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeakChip() {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        '🔥 Peak',
        style: TextStyle(
          fontSize: 10,
          color: Colors.red.shade700,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDialogTotal(num total) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          'रू ${total.toStringAsFixed(0)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  num _getSlotPrice(Map<String, dynamic> slot) {
    return num.tryParse(slot['price']?.toString() ?? '0') ?? 0;
  }

  // ==========================================================================
  // LOCK AND PAYMENT FLOW
  // ==========================================================================
  Future<void> _lockSlotAndShowPayment() async {
    if (_selectedSlot == null || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Show loading
      if (!mounted) return;
      _showLoadingDialog();

      // Lock the slot
      final response = await ApiService.lockSlot(_selectedSlot!['id']).timeout(
        _Constants.apiTimeout,
        onTimeout: () => throw TimeoutException('Server not responding'),
      );

      if (!mounted) {
        await _safeUnlockSlot();
        return;
      }

      // Close loading dialog
      Navigator.pop(context);

      if (response['status'] == 'success') {
        setState(() {
          _tempLockedSlot = _selectedSlot;
          _addTemporaryLock(_selectedSlot!['id']);
        });
        _showPaymentMethodDialog();
      } else {
        await _handleBookingFailure(response['message'] ?? 'Slot unavailable');
      }
    } on TimeoutException catch (_) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      await _handleBookingFailure('Connection timeout');
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading
      await _handleBookingFailure('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.green),
      ),
    );
  }

  Future<void> _handleBookingFailure(String message) async {
    await _safeUnlockSlot();
    await _refreshSlots();
    if (mounted) {
      _showSnackBar(message, isError: true);
    }
  }

  // ==========================================================================
  // PAYMENT METHOD DIALOG
  // ==========================================================================
  void _showPaymentMethodDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.green),
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay at venue'),
              onTap: () {
                Navigator.pop(ctx);
                _createBookingWithPayment('COD');
              },
            ),
            ListTile(
              leading: Image.network(
                'https://khalti.com/favicon.ico',
                height: 24,
                width: 24,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.payment, color: Colors.purple),
              ),
              title: const Text('Khalti'),
              subtitle: const Text('Pay online'),
              onTap: () {
                Navigator.pop(ctx);
                _initiateKhaltiPayment();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _cancelBookingProcess();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // COD BOOKING
  // ==========================================================================
  Future<void> _createBookingWithPayment(String paymentMethod) async {
    if (_tempLockedSlot == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    _showLoadingDialog();

    try {
      final bookingProvider =
          Provider.of<BookingProvider>(context, listen: false);
      final response = await bookingProvider.createBooking({
        'slotId': _tempLockedSlot!['id'],
        'paymentMethod': paymentMethod,
        'duration': _tempSelectedDuration ?? 1,
      }).timeout(
        _Constants.apiTimeout,
        onTimeout: () => throw TimeoutException('Booking timeout'),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (response['status'] == 'success') {
        await _handleBookingSuccess();
        _showSnackBar('Booking confirmed! Please pay at venue.');
      } else {
        await _handleBookingFailure(response['message'] ?? 'Booking failed');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _handleBookingFailure('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ==========================================================================
  // KHALTI PAYMENT
  // ==========================================================================
  Future<void> _initiateKhaltiPayment() async {
    if (_tempLockedSlot == null || _isProcessing) return;

    setState(() => _isProcessing = true);
    _showLoadingDialog();

    try {
      final response = await PaymentService.initiateKhaltiPayment(
        _tempLockedSlot!['id'],
        _tempSelectedDuration ?? 1,
      ).timeout(
        _Constants.apiTimeout,
        onTimeout: () => throw TimeoutException('Payment service timeout'),
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      final paymentUrl = response['paymentUrl'];
      final pidx = response['pidx'];
      _tempBookingId = response['bookingId'];

      if (response['status'] == 'success' &&
          paymentUrl != null &&
          pidx != null) {
        if (kIsWeb) {
          html.window.location.href = paymentUrl;
          return;
        }

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KhaltiPaymentScreen(
              paymentUrl: paymentUrl,
              pidx: pidx,
            ),
          ),
        );

        if (result == true) {
          await _handleBookingSuccess();
          _showSnackBar('Booking confirmed!');
        } else {
          await _cancelBookingOnPaymentFailure();
        }
      } else {
        await _handleBookingFailure(
            response['message'] ?? 'Payment initiation failed');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      await _handleBookingFailure('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ==========================================================================
  // BOOKING SUCCESS/FAILURE HANDLERS
  // ==========================================================================
  Future<void> _handleBookingSuccess() async {
    await _safeUnlockSlot();
    _clearBookingState();
    await _refreshSlots();
  }

  Future<void> _cancelBookingOnPaymentFailure() async {
    if (_tempBookingId != null) {
      try {
        await ApiService.cancelUserBooking(_tempBookingId!);
      } catch (e) {
        debugPrint('Failed to cancel booking: $e');
      }
    }
    await _safeUnlockSlot();
    _clearBookingState();
    await _refreshSlots();
    if (mounted) {
      _showSnackBar('Payment cancelled', isError: true);
    }
  }

  Future<void> _cancelBookingProcess() async {
    setState(() => _isProcessing = true);
    await _safeUnlockSlot();
    _clearBookingState();
    await _refreshSlots();
    setState(() => _isProcessing = false);
  }

  Future<void> _safeUnlockSlot() async {
    if (_tempLockedSlot == null) return;
    try {
      await ApiService.unlockSlot(_tempLockedSlot!['id']);
    } catch (e) {
      debugPrint('Failed to unlock slot: $e');
    } finally {
      setState(() => _tempLockedSlot = null);
    }
  }

  void _clearBookingState() {
    setState(() {
      _tempLockedSlot = null;
      _selectedSlot = null;
      _tempSelectedDuration = null;
      _tempBookingId = null;
    });
  }

  Future<void> _refreshSlots() async {
    await _fetchSlots();
  }

  // ==========================================================================
  // DATE SELECTION
  // ==========================================================================
  Future<void> _selectDate() async {
    if (_isProcessing) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null && picked != _selectedDate && mounted) {
      setState(() {
        _selectedDate = picked;
        _selectedSlot = null;
      });
      await _fetchSlots();
      _showSnackBar(
          'Showing slots for ${DateFormatter.formatDateShort(picked)}');
    }
  }

  // ==========================================================================
  // UI BUILDERS
  // ==========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          _buildHeaderSliver(),
          _buildTabBarSliver(),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAboutTab(),
                _buildSlotsTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          _selectedSlot != null && !_isProcessing ? _buildBookingBar() : null,
    );
  }

  Widget _buildSliverAppBar() {
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
            _buildImageGradient(),
          ],
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed:
              _isProcessing ? null : () => _showSnackBar('Added to favorites'),
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _isProcessing
              ? null
              : () => _showSnackBar('Share feature coming soon'),
        ),
      ],
    );
  }

  Widget _buildImagePageView() {
    return PageView.builder(
      itemCount:
          widget.futsal.images.isNotEmpty ? widget.futsal.images.length : 1,
      onPageChanged: (index) {
        if (mounted) {
          setState(() => _selectedImageIndex = index);
        }
      },
      itemBuilder: (context, index) {
        return widget.futsal.images.isNotEmpty
            ? Image.network(
                widget.futsal.images[index],
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
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
                },
              )
            : Container(
                color: Colors.green.shade200,
                child: Center(
                  child: Icon(
                    Icons.sports_soccer,
                    size: 80,
                    color: Colors.green.shade400,
                  ),
                ),
              );
      },
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
          widget.futsal.images.isNotEmpty ? widget.futsal.images.length : 1,
          (index) => Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedImageIndex == index
                  ? Colors.white
                  : Colors.white.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.futsal.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildRatingBadge(),
              ],
            ),
            const SizedBox(height: 8),
            _buildAddressRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            widget.futsal.averageRating?.toStringAsFixed(1) ?? 'N/A',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Consumer<ReviewProvider>(
            builder: (_, rp, __) => Text(
              ' (${rp.reviews.length})',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow() {
    return Row(
      children: [
        Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.futsal.address,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildTabBarSliver() {
    return SliverToBoxAdapter(
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.green,
        unselectedLabelColor: Colors.grey,
        indicatorColor: Colors.green,
        tabs: const [
          Tab(text: 'About', icon: Icon(Icons.info)),
          Tab(text: 'Slots', icon: Icon(Icons.access_time)),
          Tab(text: 'Reviews', icon: Icon(Icons.star)),
        ],
      ),
    );
  }

  // ==========================================================================
  // ABOUT TAB
  // ==========================================================================
  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.futsal.description?.isNotEmpty ?? false) ...[
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.futsal.description!,
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 20),
        ],
        const Text(
          'Facilities',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildFacilitiesWrap(),
        const SizedBox(height: 20),
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildMapPlaceholder(),
        const SizedBox(height: 20),
        const Text(
          'Operating Hours',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildOperatingHours(),
      ],
    );
  }

  Widget _buildFacilitiesWrap() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _buildFacilityChip(Icons.sports_soccer, '5 Courts'),
        _buildFacilityChip(Icons.local_parking, 'Free Parking'),
        _buildFacilityChip(Icons.local_drink, 'Drinking Water'),
        _buildFacilityChip(Icons.light_mode, 'Floodlights'),
        _buildFacilityChip(Icons.chair, 'Seating Area'),
        _buildFacilityChip(Icons.shower, 'Changing Room'),
      ],
    );
  }

  Widget _buildFacilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Map view coming soon', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatingHours() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monday - Friday'),
              Text('Saturday - Sunday'),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('6:00 AM - 10:00 PM'),
              Text('8:00 AM - 10:00 PM'),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SLOTS TAB
  // ==========================================================================
  Widget _buildSlotsTab() {
    return Column(
      children: [
        _buildDateSelector(),
        Expanded(
          child: _isLoadingSlots
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.green))
              : _slotsError != null
                  ? _buildErrorView()
                  : _slots.isEmpty
                      ? _buildEmptySlotsView()
                      : _buildSlotsContent(),
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              DateFormatter.formatDateFull(_selectedDate),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          TextButton(
            onPressed: _isProcessing ? null : _selectDate,
            style: TextButton.styleFrom(
              foregroundColor: Colors.green,
            ),
            child: const Text('Change Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            _slotsError ?? 'Failed to load slots',
            style: TextStyle(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _isProcessing ? null : _fetchSlots,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlotsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No slots available for this date',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Try selecting another date',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _isProcessing ? null : _selectDate,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Choose Another Date'),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotsContent() {
    return Column(
      children: [
        _buildLegend(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: _buildSlotsByCourt(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          _buildLegendDot(Colors.green.shade300, 'Available'),
          const SizedBox(width: 12),
          _buildLegendDot(Colors.red.shade300, '🔥 Peak'),
          const SizedBox(width: 12),
          _buildLegendDot(Colors.grey.shade400, 'Booked'),
          const SizedBox(width: 12),
          _buildLegendDot(Colors.orange.shade300, 'Locked'),
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  List<Widget> _buildSlotsByCourt() {
    if (_slots.isEmpty) return [];

    // Group slots by court number
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    for (final slot in _slots) {
      // Try multiple possible keys
      dynamic courtValue;

      if (slot.containsKey('court')) {
        courtValue = slot['court'];
      } else if (slot.containsKey('courtNumber')) {
        courtValue = slot['courtNumber'];
      } else if (slot.containsKey('court_no')) {
        courtValue = slot['court_no'];
      } else if (slot.containsKey('courtId')) {
        courtValue = slot['courtId'];
      } else if (slot.containsKey('court_id')) {
        courtValue = slot['court_id'];
      } else {
        courtValue = '1';
      }

      final court = 'Court $courtValue';
      grouped.putIfAbsent(court, () => []);
      grouped[court]!.add(slot);
    }

    final List<Widget> widgets = [];

    grouped.forEach((courtName, slots) {
      widgets.add(_buildCourtHeader(courtName, slots.length));
      widgets.add(_buildCourtSlotsGrid(slots));
      widgets.add(const SizedBox(height: 16));
    });

    return widgets;
  }

  Widget _buildCourtHeader(String courtName, int slotCount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade700,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              courtName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$slotCount slots',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourtSlotsGrid(List<Map<String, dynamic>> slots) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _Constants.slotGridCrossAxisCount,
        childAspectRatio: _Constants.slotAspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: slots.length,
      itemBuilder: (context, index) => _buildSlotCard(slots[index]),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final slotId = slot['id'] as int? ?? 0;
    final isAvailable = _isSlotAvailable(slot);
    final isBooked = _isSlotBooked(slot);
    final isSystemLocked = _isSlotLockedBySystem(slot);
    final isTemporarilyLocked = _isSlotTemporarilyLocked(slotId);
    final isPeak = _isSlotPeak(slot);
    final isSelected = _selectedSlot != null && _selectedSlot!['id'] == slotId;
    final canSelect = _canSelectSlot(slot);

    Color backgroundColor;
    Color textColor;
    Color borderColor;
    String? statusText;

    if (isSelected) {
      backgroundColor = Colors.green;
      textColor = Colors.white;
      borderColor = Colors.green;
    } else if (isBooked) {
      backgroundColor = Colors.grey.shade300;
      textColor = Colors.grey.shade700;
      borderColor = Colors.grey.shade400;
      statusText = 'BOOKED';
    } else if (isSystemLocked || isTemporarilyLocked) {
      backgroundColor = Colors.orange.shade50;
      textColor = Colors.orange.shade700;
      borderColor = Colors.orange.shade300;
      statusText = 'LOCKED';
    } else if (isAvailable && isPeak) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
      borderColor = Colors.red.shade300;
    } else if (isAvailable) {
      backgroundColor = Colors.white;
      textColor = Colors.green.shade700;
      borderColor = Colors.green.shade300;
    } else {
      backgroundColor = Colors.grey.shade100;
      textColor = Colors.grey;
      borderColor = Colors.grey.shade300;
    }

    return GestureDetector(
      onTap: canSelect && !_isProcessing ? () => _selectSlot(slot) : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPeak && isAvailable && !isSelected)
              const Text('🔥', style: TextStyle(fontSize: 10)),
            Text(
              slot['startTime'] ?? '00:00',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getCourtNumber(slot),
              style: TextStyle(
                fontSize: 10,
                color: textColor.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'रू ${slot['price'] ?? 0}',
              style: TextStyle(
                fontSize: 11,
                color: textColor,
              ),
            ),
            if (statusText != null)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isBooked ? Colors.grey.shade400 : Colors.orange.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 8,
                    color: isBooked ? Colors.white : Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // BOOKING BAR
  // ==========================================================================
  Widget _buildBookingBar() {
    final price = _getSlotPrice(_selectedSlot!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Slot',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _selectedSlot!['startTime'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'रू $price',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _isProcessing ? null : _proceedToBooking,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Continue',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // REVIEWS TAB
  // ==========================================================================
  Widget _buildReviewsTab() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        final avgRating = reviewProvider.averageRating;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRatingSummaryCard(avgRating, reviews.length),
            const SizedBox(height: 16),
            if (reviewProvider.canReview && !_isProcessing)
              _buildWriteReviewButton(reviewProvider.eligibleBookingId!),
            const SizedBox(height: 16),
            const Text(
              'Recent Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (reviewProvider.isLoading)
              const Center(
                  child: CircularProgressIndicator(color: Colors.green))
            else if (reviews.isEmpty)
              _buildEmptyReviews()
            else
              ...reviews.map((review) => _buildReviewCard(review)),
          ],
        );
      },
    );
  }

  Widget _buildRatingSummaryCard(double avgRating, int reviewCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < avgRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                Text(
                  '$reviewCount reviews',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  return _buildRatingRow(star);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(int star) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        final count = reviews.where((r) => r.rating.round() == star).length;
        final fraction = reviews.isEmpty ? 0.0 : count / reviews.length;

        return Row(
          children: [
            Text('$star', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
              ),
            ),
            const SizedBox(width: 8),
            Text('$count', style: const TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }

  Widget _buildWriteReviewButton(int bookingId) {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : () => _showWriteReviewDialog(bookingId),
      icon: const Icon(Icons.edit),
      label: const Text('Write a Review'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green,
        side: const BorderSide(color: Colors.green),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.star_border, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('No reviews yet',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnReview = authProvider.user?.id == review.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        DateFormatter.formatDateMedium(review.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
                if (isOwnReview && !_isProcessing)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditReviewDialog(review);
                      } else if (value == 'delete') {
                        _confirmDeleteReview(review);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            if (review.comment?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(review.comment!, style: const TextStyle(fontSize: 14)),
            ],
            if (review.reply?.isNotEmpty ?? false)
              _buildOwnerReply(review.reply!),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerReply(String reply) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner Reply',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(reply, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  // ==========================================================================
  // REVIEW DIALOGS
  // ==========================================================================
  void _showWriteReviewDialog(int bookingId) {
    double selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your experience:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedRating = index + 1.0),
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your experience (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _isProcessing
                  ? null
                  : () => _submitReview(
                        ctx,
                        bookingId,
                        selectedRating,
                        commentController.text.trim(),
                      ),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(
    BuildContext dialogContext,
    int bookingId,
    double rating,
    String comment,
  ) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.submitReview(
        futsalId: widget.futsal.id,
        bookingId: bookingId,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error submitting review: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showEditReviewDialog(Review review) {
    double selectedRating = review.rating;
    final commentController = TextEditingController(text: review.comment ?? '');

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedRating = index + 1.0),
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Your review',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _isProcessing
                  ? null
                  : () => _updateReview(
                        ctx,
                        review.id,
                        selectedRating,
                        commentController.text.trim(),
                      ),
              child:
                  const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReview(
    BuildContext dialogContext,
    int reviewId,
    double rating,
    String comment,
  ) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.updateReview(
        reviewId: reviewId,
        futsalId: widget.futsal.id,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating review: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmDeleteReview(Review review) {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed:
                _isProcessing ? null : () => _deleteReview(ctx, review.id),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(BuildContext dialogContext, int reviewId) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.deleteReview(
        reviewId: reviewId,
        futsalId: widget.futsal.id,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error deleting review: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ==========================================================================
  // UTILITIES
  // ==========================================================================
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: _Constants.snackBarDuration,
      ),
    );
  }

  @override
  void dispose() {
    _lockCleanupTimer?.cancel();
    _tabController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app background/foreground
    if (state == AppLifecycleState.paused) {
      // App going to background - clean up locks
      _safeUnlockSlot();
    }
  }
}
