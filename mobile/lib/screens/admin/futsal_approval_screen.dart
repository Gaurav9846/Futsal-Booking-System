import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import 'package:flutter/services.dart';

class FutsalApprovalScreen extends StatefulWidget {
  const FutsalApprovalScreen({super.key});

  @override
  State<FutsalApprovalScreen> createState() => _FutsalApprovalScreenState();
}

class _FutsalApprovalScreenState extends State<FutsalApprovalScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Futsal Approvals"),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (adminProvider.pendingFutsals.isEmpty) {
            return const Center(
              child: Text(
                "No pending futsals for approval",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await adminProvider.loadDashboardStats();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: adminProvider.pendingFutsals.length,
              itemBuilder: (context, index) {
                final futsal = adminProvider.pendingFutsals[index];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (futsal['images'] != null &&
                          (futsal['images'] as List).isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12)),
                          child: Image.network(
                            futsal['images'][0],
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.green.shade100,
                              child: const Center(
                                child: Icon(Icons.sports_soccer,
                                    size: 50, color: Colors.green),
                              ),
                            ),
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name + pending badge
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    futsal['name'] ?? 'Unnamed Futsal',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Address
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 16, color: Colors.grey.shade500),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    futsal['address'] ?? 'Unknown location',
                                    style:
                                        TextStyle(color: Colors.grey.shade600),
                                  ),
                                ),
                              ],
                            ),

                            if (futsal['description'] != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                futsal['description'],
                                style: TextStyle(
                                    fontSize: 13, color: Colors.grey.shade700),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            const Divider(height: 20),

                            // Owner info
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: Colors.green.shade100,
                                  child: Text(
                                    (futsal['owner']?['fullName'] ?? 'O')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        futsal['owner']?['fullName'] ??
                                            'Unknown Owner',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      if (futsal['owner']?['email'] != null)
                                        Text(
                                          futsal['owner']['email'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      if (futsal['owner']?['phoneNumber'] !=
                                          null)
                                        Text(
                                          futsal['owner']['phoneNumber'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Courts info
                            if (futsal['courts'] != null &&
                                (futsal['courts'] as List).isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Courts (${(futsal['courts'] as List).length})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...(futsal['courts'] as List).map((court) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Icon(Icons.sports_soccer,
                                          size: 14,
                                          color: Colors.green.shade600),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Court ${court['courtNumber']} • ${court['courtType']}',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'रू ${court['basePrice']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      if (court['peakPrice'] != null)
                                        Text(
                                          ' / रू ${court['peakPrice']} peak',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],

                            const SizedBox(height: 12),

                            // Base price
                            Row(
                              children: [
                                Icon(Icons.currency_rupee,
                                    size: 16, color: Colors.green.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  'Base Price: रू ${futsal['basePrice']}/hr',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Contact owner section
                            const SizedBox(height: 8),
                            const Text(
                              'Contact Owner',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (futsal['owner']?['email'] != null)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.email_outlined,
                                          size: 14),
                                      label: Text(
                                        futsal['owner']['email'],
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                        side: BorderSide(
                                            color: Colors.blue.shade200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: futsal['owner']['email']));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Email copied to clipboard'),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                if (futsal['owner']?['email'] != null &&
                                    futsal['owner']?['phoneNumber'] != null)
                                  const SizedBox(width: 8),
                                if (futsal['owner']?['phoneNumber'] != null)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.phone_outlined,
                                          size: 14),
                                      label: Text(
                                        futsal['owner']['phoneNumber'],
                                        style: const TextStyle(fontSize: 11),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.green,
                                        side: BorderSide(
                                            color: Colors.green.shade200),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 4, horizontal: 8),
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: futsal['owner']
                                                ['phoneNumber']));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Phone copied to clipboard'),
                                            backgroundColor: Colors.green,
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                  ),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: const Text('Reject'),
                                  onPressed: () =>
                                      _showRejectDialog(context, futsal['id']),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Approve'),
                                  onPressed: () async {
                                    final result = await adminProvider
                                        .approveFutsal(futsal['id']);
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(result['message'])),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /// =========================
  /// REJECT FUTSAL DIALOG
  /// =========================
  void _showRejectDialog(BuildContext context, int futsalId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Reject Futsal"),
          content: TextField(
            controller: reasonController,
            decoration: const InputDecoration(
              hintText: "Enter rejection reason",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            Consumer<AdminProvider>(
              builder: (context, adminProvider, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text("Reject"),
                  onPressed: () async {
                    final result = await adminProvider.rejectFutsal(
                      futsalId,
                      reasonController.text,
                    );

                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result["message"]),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        );
      },
    );
  }
}
