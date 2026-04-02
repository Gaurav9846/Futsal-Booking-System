import 'package:flutter/material.dart';
import '../../providers/admin_provider.dart';
import 'package:provider/provider.dart';

class FutsalDetailsModal extends StatelessWidget {
  final Map<String, dynamic> futsal;
  final Future<Map<String, dynamic>> Function() onApprove;
  final Future<Map<String, dynamic>> Function(String reason) onReject;

  const FutsalDetailsModal({
    super.key,
    required this.futsal,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final owner = futsal['owner'] ?? {};
    final courts = futsal['courts'] as List<dynamic>? ?? [];

    return AlertDialog(
      title: Text(futsal['name'] ?? 'Futsal Details'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Owner: ${owner['fullName'] ?? 'N/A'}"),
            Text("Email: ${owner['email'] ?? 'N/A'}"),
            Text("Phone: ${owner['phoneNumber'] ?? 'N/A'}"),
            const SizedBox(height: 12),
            const Text("Courts:", style: TextStyle(fontWeight: FontWeight.bold)),
            ...courts.map((court) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  "Court ${court['courtNumber']}: ${court['courtType']} | Base: Rs ${court['basePrice']} | Peak: Rs ${court['peakPrice']}",
                ),
              );
            }).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
        TextButton(
          onPressed: () async {
            final result = await onReject(await _showRejectReasonDialog(context));
            if (result['status'] == 'success') {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'])),
              );
            }
          },
          child: const Text(
            "Reject",
            style: TextStyle(color: Colors.red),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final result = await onApprove();
            if (result['status'] == 'success') {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(result['message'])),
              );
            }
          },
          child: const Text("Approve"),
        ),
      ],
    );
  }

  Future<String> _showRejectReasonDialog(BuildContext context) async {
    String reason = '';
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Reject Reason"),
          content: TextField(
            autofocus: true,
            onChanged: (value) => reason = value,
            decoration: const InputDecoration(hintText: "Enter reason"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
    return reason;
  }
}