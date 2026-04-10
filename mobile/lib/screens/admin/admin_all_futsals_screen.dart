import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';

class AdminAllFutsalsScreen extends StatefulWidget {
  const AdminAllFutsalsScreen({super.key});

  @override
  State<AdminAllFutsalsScreen> createState() => _AdminAllFutsalsScreenState();
}

class _AdminAllFutsalsScreenState extends State<AdminAllFutsalsScreen> {
  String _searchQuery = '';
  String _statusFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAllFutsals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Futsals'),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Provider.of<AdminProvider>(context, listen: false)
                .loadAllFutsals(),
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.green));
          }

          // Filter
          var futsals = adminProvider.allFutsals.where((f) {
            final matchesSearch = _searchQuery.isEmpty ||
                (f['name'] ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase()) ||
                (f['address'] ?? '')
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase());
            final matchesStatus = _statusFilter == 'All' ||
                (_statusFilter == 'Approved' && (f['isApproved'] == true)) ||
                (_statusFilter == 'Pending' && (f['isApproved'] == false));
            return matchesSearch && matchesStatus;
          }).toList();

          return Column(
            children: [
              // Search + filter
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.white,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name or address...',
                        prefixIcon:
                            const Icon(Icons.search, color: Colors.green),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: ['All', 'Approved', 'Pending']
                          .map((status) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(status),
                                  selected: _statusFilter == status,
                                  onSelected: (_) =>
                                      setState(() => _statusFilter = status),
                                  selectedColor: Colors.green.shade100,
                                  checkmarkColor: Colors.green,
                                ),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

              // Count
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      '${futsals.length} futsals',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: futsals.isEmpty
                    ? const Center(child: Text('No futsals found'))
                    : RefreshIndicator(
                        onRefresh: () => adminProvider.loadAllFutsals(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          itemCount: futsals.length,
                          itemBuilder: (_, index) {
                            return _buildFutsalCard(
                                context, futsals[index], adminProvider);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFutsalCard(BuildContext context, Map<String, dynamic> futsal,
      AdminProvider adminProvider) {
    final isApproved = futsal['isApproved'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFutsalDetailsSheet(context, futsal, adminProvider),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            if (futsal['images'] != null &&
                (futsal['images'] as List).isNotEmpty)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  futsal['images'][0],
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: Colors.green.shade50,
                    child: const Center(
                      child: Icon(Icons.sports_soccer,
                          size: 40, color: Colors.green),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + status badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          futsal['name'] ?? 'Unnamed',
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
                          color: isApproved
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isApproved ? 'Approved' : 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isApproved
                                ? Colors.green.shade800
                                : Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Address
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          futsal['address'] ?? '',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Owner + price row
                  Row(
                    children: [
                      Icon(Icons.person_outline,
                          size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          futsal['owner']?['fullName'] ?? 'Unknown Owner',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ),
                      Icon(Icons.attach_money,
                          size: 14, color: Colors.green.shade600),
                      Text(
                        'Price varies',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Contact buttons
                  _buildContactButtons(context, futsal),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // CONTACT BUTTONS
  // ============================================
  Widget _buildContactButtons(
      BuildContext context, Map<String, dynamic> futsal) {
    final email = futsal['owner']?['email'];
    final phone = futsal['owner']?['phoneNumber'];

    return Row(
      children: [
        if (email != null)
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.email_outlined, size: 16),
              label: const Text('Email', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue,
                side: BorderSide(color: Colors.blue.shade300),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: () => _copyToClipboard(context, email, 'Email'),
            ),
          ),
        if (email != null && phone != null) const SizedBox(width: 8),
        if (phone != null)
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.phone_outlined, size: 16),
              label: const Text('Phone', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.green.shade300),
                padding: const EdgeInsets.symmetric(vertical: 6),
              ),
              onPressed: () => _copyToClipboard(context, phone, 'Phone'),
            ),
          ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied: $value'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================
  // FUTSAL DETAILS BOTTOM SHEET
  // ============================================
  void _showFutsalDetailsSheet(BuildContext context,
      Map<String, dynamic> futsal, AdminProvider adminProvider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              futsal['name'] ?? 'Unnamed Futsal',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              futsal['address'] ?? '',
              style: TextStyle(color: Colors.grey.shade600),
            ),

            if (futsal['description'] != null) ...[
              const SizedBox(height: 12),
              Text(futsal['description'],
                  style: const TextStyle(fontSize: 14, height: 1.5)),
            ],

            const Divider(height: 24),

            // Owner section
            const Text('Owner Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildDetailRow(
                Icons.person, futsal['owner']?['fullName'] ?? 'Unknown'),
            const SizedBox(height: 6),
            if (futsal['owner']?['email'] != null)
              GestureDetector(
                onTap: () => _copyToClipboard(
                    context, futsal['owner']['email'], 'Email'),
                child: _buildDetailRow(Icons.email, futsal['owner']['email'],
                    color: Colors.blue),
              ),
            const SizedBox(height: 6),
            if (futsal['owner']?['phoneNumber'] != null)
              GestureDetector(
                onTap: () => _copyToClipboard(
                    context, futsal['owner']['phoneNumber'], 'Phone'),
                child: _buildDetailRow(
                    Icons.phone, futsal['owner']['phoneNumber'],
                    color: Colors.green),
              ),

            const Divider(height: 24),

// Pricing
            const Text('Pricing',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildDetailRow(
                Icons.attach_money, 'Pricing varies by court and time'),

            // Courts
            if (futsal['courts'] != null &&
                (futsal['courts'] as List).isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Courts (${(futsal['courts'] as List).length})',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...(futsal['courts'] as List).map((court) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.sports_soccer,
                              size: 16, color: Colors.green.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'Court ${court['courtNumber']} • ${court['courtType']}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Text(
                            'रू ${court['basePrice']}',
                            style: TextStyle(
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.bold),
                          ),
                          if (court['peakPrice'] != null)
                            Text(
                              ' / रू ${court['peakPrice']} 🔥',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade700),
                            ),
                        ],
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: 20),

            // Contact buttons in sheet
            const Text('Contact Owner',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildContactButtons(context, futsal),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: color ?? Colors.grey.shade800,
            ),
          ),
        ),
        if (color != null)
          Icon(Icons.copy, size: 14, color: Colors.grey.shade400),
      ],
    );
  }
}
