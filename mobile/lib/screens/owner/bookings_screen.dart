import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/booking_provider.dart';
import '../../models/booking.dart';
import '../../utils/date_formatter.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

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
  // Add this map to track blocked players locally
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
    debugPrint(
        '📅 BookingsScreen: Loading bookings for futsal ${widget.futsalId}');
    final provider = Provider.of<BookingProvider>(context, listen: false);

    // Load today's bookings
    await provider.loadTodayBookings(widget.futsalId);

    // Load upcoming bookings (UPDATED method name)
    await provider.loadOwnerUpcomingBookings(widget.futsalId);

    // Load calendar for current month (UPDATED method name)
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
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading today\'s bookings...'),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBookings,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.todayBookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No bookings for today',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check back later or view upcoming bookings',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Date header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      color: Colors.green.shade700, size: 16),
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
            ),

            // Bookings list
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No upcoming bookings',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        // Group bookings by date
        final groupedBookings = <DateTime, List<Booking>>{};
        for (var booking in provider.upcomingBookings) {
          final date =
              DateTime(booking.date.year, booking.date.month, booking.date.day);
          if (!groupedBookings.containsKey(date)) {
            groupedBookings[date] = [];
          }
          groupedBookings[date]!.add(booking);
        }

        // Sort dates
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
                Padding(
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${dayBookings.length} bookings',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
            // Month selector
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month - 1,
                          1,
                        );
                      });
                      // UPDATED method name
                      provider.loadOwnerMonthBookings(
                          widget.futsalId, _selectedDate);
                    },
                  ),
                  Text(
                    DateFormatter.formatMonthYear(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                          1,
                        );
                      });
                      // UPDATED method name
                      provider.loadOwnerMonthBookings(
                          widget.futsalId, _selectedDate);
                    },
                  ),
                ],
              ),
            ),

            // Calendar grid
            Expanded(
              child: _buildCalendarGrid(provider),
            ),

            // Selected date bookings
            if (provider.selectedDateBookings.isNotEmpty)
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
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
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () {
                              // Navigate to full day view
                            },
                            child: const Text('View All'),
                          ),
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
                            child: _buildCompactBookingCard(booking),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCalendarGrid(BookingProvider provider) {
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_selectedDate.year, _selectedDate.month, 1);
    final startingWeekday = firstDayOfMonth.weekday;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: 42, // 6 weeks * 7 days
      itemBuilder: (ctx, index) {
        final day = index - startingWeekday + 2;
        final isCurrentMonth = day >= 1 && day <= daysInMonth;

        if (!isCurrentMonth) {
          return Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        final date = DateTime(_selectedDate.year, _selectedDate.month, day);
        final isToday = _isSameDay(date, DateTime.now());
        final isSelected = _isSameDay(date, _selectedDate);
        final bookingsForDay = provider.getBookingsForDate(date);
        final bookingCount = bookingsForDay.length;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDate = date;
            });
            provider.selectDate(date);
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.green
                  : isToday
                      ? Colors.green.shade50
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade300,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  day.toString(),
                  style: TextStyle(
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
                if (bookingCount > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      bookingCount.toString(),
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? Colors.green : Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // BOOKING CARD
  // ============================================
  Widget _buildBookingCard(Booking booking, BookingProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(booking).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  _getStatusIcon(booking),
                  size: 14,
                  color: _getStatusColor(booking),
                ),
                const SizedBox(width: 4),
                Text(
                  booking.statusText,
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(booking),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (!booking.isCheckedIn &&
                    !booking.isCancelled &&
                    booking.isToday)
                  Row(
                    children: [
                      if (!booking.isPaid)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'UNPAID',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NOT CHECKED IN',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                // Replace the PopupMenuButton with:
                SizedBox(
                  height: 28,
                  width: 28,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert,
                        size: 16, color: Colors.grey),
                    onSelected: (value) {
                      if (value == 'block') _blockPlayer(booking);
                      if (value == 'unblock') _unblockPlayer(booking);
                    },
                    itemBuilder: (_) {
                      final isBlocked = _blockedPlayers[booking.userId] ??
                          false; // ✅ userId not booking.id
                      return [
                        if (!isBlocked)
                          const PopupMenuItem(
                            value: 'block',
                            child: Row(
                              children: [
                                Icon(Icons.block, color: Colors.red, size: 18),
                                SizedBox(width: 8),
                                Text('Block Player'),
                              ],
                            ),
                          ),
                        if (isBlocked)
                          const PopupMenuItem(
                            value: 'unblock',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 18),
                                SizedBox(width: 8),
                                Text('Unblock Player'),
                              ],
                            ),
                          ),
                      ];
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time column
                Container(
                  width: 60,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        booking.startTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'to',
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                      Text(
                        booking.endTime,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Customer details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customerName ?? 'Guest Customer',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (booking.customerPhone != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              booking.customerPhone!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Court ${booking.courtNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              booking.duration,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Price and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'रू ${booking.totalAmount}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: booking.isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ✅ Not checked in yet — show Check In + Cancel
                    if (!booking.isCheckedIn &&
                        !booking.isCancelled &&
                        !booking.isCompleted)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.login,
                                color: Colors.green, size: 20),
                            onPressed: () =>
                                _checkInCustomer(booking, provider),
                            tooltip: 'Check In',
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel,
                                color: Colors.red, size: 20),
                            onPressed: () => _cancelBooking(booking, provider),
                            tooltip: 'Cancel',
                          ),
                        ],
                      ),

                    // ✅ Checked in — show Mark Paid + Complete
                    if (booking.isCheckedIn &&
                        !booking.isCompleted &&
                        !booking.isCancelled)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!booking.isPaid)
                            IconButton(
                              icon: const Icon(Icons.payments,
                                  color: Colors.orange, size: 20),
                              onPressed: () => _markAsPaid(booking, provider),
                              tooltip: 'Mark as Paid',
                            ),
                          IconButton(
                            icon: const Icon(Icons.check_circle,
                                color: Colors.green, size: 20),
                            onPressed: () =>
                                _completeBooking(booking, provider),
                            tooltip: 'Complete',
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${booking.startTime} - ${booking.endTime}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              booking.customerName ?? 'Guest',
              style: const TextStyle(fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Court ${booking.courtNumber}',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ACTIONS
  // ============================================
  Future<void> _checkInCustomer(
      Booking booking, BookingProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Check In Customer'),
        content: Text('Check in ${booking.customerName ?? 'customer'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('CHECK IN'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    final response =
        await provider.checkInCustomer(booking.id, widget.futsalId);

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _markAsPaid(Booking booking, BookingProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Paid'),
        content:
            Text('Confirm cash payment of रू ${booking.totalAmount} received?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRM PAID'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final response = await provider.updatePaymentStatus(
      booking.id,
      'PAID',
      widget.futsalId,
    );

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['status'] == 'success'
            ? 'Payment confirmed!'
            : response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _completeBooking(
      Booking booking, BookingProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Booking'),
        content: Text(
            'Mark booking for ${booking.customerName ?? 'customer'} as completed?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('COMPLETE'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final response =
        await provider.completeBooking(booking.id, widget.futsalId);

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['status'] == 'success'
            ? 'Booking completed!'
            : response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _cancelBooking(Booking booking, BookingProvider provider) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking'),
        content:
            Text('Cancel booking for ${booking.customerName ?? 'customer'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('NO'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    // Use provider method instead of direct ApiService call
    final response = await provider.ownerCancelBooking(booking.id);

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['message']),
        backgroundColor:
            response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
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
                setState(() {
                  _selectedStatus = value;
                });
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _selectedCourtId,
              hint: const Text('All Courts'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Courts')),
                // Add court list here
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCourtId = value;
                });
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HELPERS
  // ============================================
  Color _getStatusColor(Booking booking) {
    if (booking.isCancelled) return Colors.red;
    if (booking.isCompleted) return Colors.green;
    if (booking.isCheckedIn) return Colors.blue;
    if (booking.isPending) return Colors.orange;
    return Colors.grey;
  }

  IconData _getStatusIcon(Booking booking) {
    if (booking.isCancelled) return Icons.cancel;
    if (booking.isCompleted) return Icons.check_circle;
    if (booking.isCheckedIn) return Icons.login;
    if (booking.isPending) return Icons.hourglass_empty;
    return Icons.check_circle_outline;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _blockPlayer(Booking booking) async {
    final reasonController = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Block Player'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Block ${booking.customerName ?? 'this player'} from booking at this futsal?',
            ),
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await ApiService.post('owner/blocks', {
        'playerId': booking.userId, // ❌ wrong — need userId
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unblock Player'),
        content: Text(
            'Allow ${booking.customerName ?? 'this player'} to book again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Unblock', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Need userId not bookingId — see note below
      final response = await ApiService.delete(
        'owner/blocks/${booking.userId}?futsalId=${widget.futsalId}',
      );
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
}
