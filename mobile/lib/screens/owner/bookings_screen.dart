import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking.dart';
import '../../utils/date_formatter.dart';
import '../../services/api_service.dart';
import 'bookings/widgets/booking_card.dart';
import 'bookings/widgets/compact_booking_card.dart';
import 'bookings/widgets/calendar_grid.dart';
import 'bookings/widgets/bookings_empty_state.dart';
import 'bookings/widgets/booking_action_dialog.dart';

class BookingsScreen extends StatefulWidget {
  final int futsalId;
  final String futsalName;

  const BookingsScreen({
    super.key,
    required this.futsalId,
    required this.futsalName,
  });

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  String? _selectedStatus;
  int? _selectedCourtId;
  final Map<int, bool> _blockedPlayers = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    await provider.loadTodayBookings(widget.futsalId);
    await provider.loadOwnerUpcomingBookings(widget.futsalId);
    await provider.loadOwnerMonthBookings(widget.futsalId, _selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.futsalName} - Bookings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'TODAY', icon: Icon(Icons.today)),
            Tab(text: 'UPCOMING', icon: Icon(Icons.calendar_month)),
            Tab(text: 'CALENDAR', icon: Icon(Icons.calendar_view_month)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBookings,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildUpcomingTab(),
          _buildCalendarTab(),
        ],
      ),
    );
  }

  // ============================================
  // TODAY TAB
  // ============================================
  Widget _buildTodayTab() {
    return Consumer<BookingProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading && provider.todayBookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return _buildErrorView(provider.error!);
        }

        if (provider.todayBookings.isEmpty) {
          return BookingsEmptyState.today();
        }

        return Column(
          children: [
            _buildDateHeader(provider),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: provider.todayBookings.length,
                itemBuilder: (ctx, index) {
                  final booking = provider.todayBookings[index];
                  return _buildBookingCard(booking, provider);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================
  // UPCOMING TAB
  // ============================================
  Widget _buildUpcomingTab() {
    return Consumer<BookingProvider>(
      builder: (ctx, provider, _) {
        if (provider.isLoading && provider.upcomingBookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.upcomingBookings.isEmpty) {
          return BookingsEmptyState.upcoming();
        }

        final groupedBookings = <DateTime, List<Booking>>{};
        for (var booking in provider.upcomingBookings) {
          final date =
              DateTime(booking.date.year, booking.date.month, booking.date.day);
          groupedBookings.putIfAbsent(date, () => []).add(booking);
        }

        final sortedDates = groupedBookings.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedDates.length,
          itemBuilder: (ctx, index) {
            final date = sortedDates[index];
            final dayBookings = groupedBookings[date]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSectionHeader(date, dayBookings.length),
                ...dayBookings.map((booking) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 8),
                      child: _buildBookingCard(booking, provider),
                    )),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================
  // CALENDAR TAB
  // ============================================
  Widget _buildCalendarTab() {
    return Consumer<BookingProvider>(
      builder: (ctx, provider, _) {
        return Column(
          children: [
            _buildMonthSelector(provider),
            Expanded(
              child: CalendarGrid(
                selectedDate: _selectedDate,
                getBookingsForDate: provider.getBookingsForDate,
                onDateSelected: (date) {
                  setState(() => _selectedDate = date);
                  provider.selectDate(date);
                },
              ),
            ),
            if (provider.selectedDateBookings.isNotEmpty)
              _buildSelectedDateBookings(provider),
          ],
        );
      },
    );
  }

  // ============================================
  // BUILDERS
  // ============================================
  Widget _buildDateHeader(BookingProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.green.shade50,
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Colors.green.shade700, size: 16),
          const SizedBox(width: 8),
          Text(
            DateFormatter.formatDateFull(_selectedDate),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const Spacer(),
          Text(
            '${provider.todayBookings.length} bookings',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSectionHeader(DateTime date, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Text(
              DateFormatter.formatDay(date),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              DateFormatter.formatDateWithWeekday(date),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count bookings',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BookingProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate =
                    DateTime(_selectedDate.year, _selectedDate.month - 1, 1);
              });
              provider.loadOwnerMonthBookings(widget.futsalId, _selectedDate);
            },
          ),
          Text(
            DateFormatter.formatMonthYear(_selectedDate),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedDate =
                    DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
              });
              provider.loadOwnerMonthBookings(widget.futsalId, _selectedDate);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateBookings(BookingProvider provider) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Text(
                  'Bookings for ${DateFormatter.formatDateShort(_selectedDate)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              itemCount: provider.selectedDateBookings.length,
              itemBuilder: (ctx, index) {
                final booking = provider.selectedDateBookings[index];
                return Container(
                  width: 200,
                  margin: const EdgeInsets.only(right: 8),
                  child: CompactBookingCard(booking: booking),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(error,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: _loadBookings, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BOOKING CARD
  // ============================================
  Widget _buildBookingCard(Booking booking, BookingProvider provider) {
    return BookingCard(
      booking: booking,
      isBlocked: _blockedPlayers[booking.userId] ?? false,
      onCheckIn: () => _checkInCustomer(booking, provider),
      onMarkPaid: () => _markAsPaid(booking, provider),
      onCancel: () => _cancelBooking(booking, provider),
      onBlock: () => _blockPlayer(booking),
      onUnblock: () => _unblockPlayer(booking),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================
  Future<void> _checkInCustomer(
      Booking booking, BookingProvider provider) async {
    final confirmed = await BookingActionDialog.show(
      context: context,
      title: 'Check In Customer',
      message: 'Check in ${booking.customerName ?? 'customer'}?',
      confirmText: 'CHECK IN',
    );
    if (confirmed != true) return;

    _showLoading();
    final response =
        await provider.checkInCustomer(booking.id, widget.futsalId);
    _hideLoadingAndShowResult(response);
  }

  Future<void> _markAsPaid(Booking booking, BookingProvider provider) async {
  final confirmed = await BookingActionDialog.show(
    context: context,
    title: 'Mark as Paid',
    message: 'Confirm cash payment of रू ${booking.totalAmount} received?',
    confirmText: 'CONFIRM PAID',
  );
  if (confirmed != true) return;

  _showLoading();
  final response = await provider.initiateCodPayment(booking.id, widget.futsalId);
  _hideLoadingAndShowResult(response);
  
  // ✅ Force refresh after action
  if (response['status'] == 'success') {
    await _loadBookings();
  }
}

  Future<void> _cancelBooking(Booking booking, BookingProvider provider) async {
    final confirmed = await BookingActionDialog.show(
      context: context,
      title: 'Cancel Booking',
      message: 'Cancel booking for ${booking.customerName ?? 'customer'}?',
      confirmText: 'YES, CANCEL',
      confirmColor: Colors.red,
    );
    if (confirmed != true) return;

    _showLoading();
    final response = await provider.ownerCancelBooking(booking.id);
    _hideLoadingAndShowResult(response);
  }

  Future<void> _blockPlayer(Booking booking) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Block ${booking.customerName ?? 'this player'} from booking at this futsal?'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.post('owner/blocks', {
        'playerId': booking.userId,
        'futsalId': widget.futsalId,
        'reason': reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      });

      if (!mounted) return;
      if (response['status'] == 'success') {
        setState(() => _blockedPlayers[booking.userId] = true);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor:
              response['status'] == 'success' ? Colors.red : Colors.grey,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _unblockPlayer(Booking booking) async {
    final confirmed = await BookingActionDialog.show(
      context: context,
      title: 'Unblock Player',
      message: 'Allow ${booking.customerName ?? 'this player'} to book again?',
      confirmText: 'UNBLOCK',
      confirmColor: Colors.green,
    );
    if (confirmed != true) return;

    try {
      final response = await ApiService.delete(
          'owner/blocks/${booking.userId}?futsalId=${widget.futsalId}');
      if (!mounted) return;
      if (response['status'] == 'success') {
        setState(() => _blockedPlayers[booking.userId] = false);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor:
              response['status'] == 'success' ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoadingAndShowResult(Map<String, dynamic> response) {
    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['status'] == 'success'
            ? response['message']
            : response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
    if (response['status'] == 'success') {
      _loadBookings();
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField(
              value: _selectedStatus,
              hint: const Text('All Status'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Status')),
                DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                DropdownMenuItem(
                    value: 'checked_in', child: Text('Checked In')),
                DropdownMenuItem(value: 'completed', child: Text('Completed')),
                DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value);
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _selectedCourtId,
              hint: const Text('All Courts'),
              items: const [
                DropdownMenuItem(value: null, child: Text('All Courts'))
              ],
              onChanged: (value) {
                setState(() => _selectedCourtId = value);
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}