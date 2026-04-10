import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/block_provider.dart';
import '../../providers/futsal_provider.dart';
import '../../models/block.dart';

class BlockedPlayersScreen extends StatefulWidget {
  final int futsalId;
  final String futsalName;

  const BlockedPlayersScreen({
    super.key,
    required this.futsalId,
    required this.futsalName,
  });

  @override
  State<BlockedPlayersScreen> createState() => _BlockedPlayersScreenState();
}

class _BlockedPlayersScreenState extends State<BlockedPlayersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BlockProvider>(context, listen: false)
          .loadBlockedPlayers(widget.futsalId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blocked Players - ${widget.futsalName}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<BlockProvider>(
        builder: (context, blockProvider, child) {
          if (blockProvider.isLoading && blockProvider.blocks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Loading blocked players...'),
                ],
              ),
            );
          }

          if (blockProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    blockProvider.error!,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => blockProvider.loadBlockedPlayers(widget.futsalId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          if (blockProvider.blocks.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No blocked players',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Blocked players will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => blockProvider.loadBlockedPlayers(widget.futsalId),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: blockProvider.blocks.length,
              itemBuilder: (context, index) {
                final block = blockProvider.blocks[index];
                return _buildBlockCard(context, block, blockProvider);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockCard(BuildContext context, Block block, BlockProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text(
                block.playerName[0].toUpperCase(),
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.playerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (block.playerEmail.isNotEmpty)
                    Text(
                      block.playerEmail,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  if (block.reason != null && block.reason!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reason:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            block.reason!,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Unblock',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Unblock Player'),
                    content: Text(
                      'Are you sure you want to unblock ${block.playerName}?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('UNBLOCK'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final result = await provider.unblockPlayer(block.playerId, widget.futsalId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message']),
                        backgroundColor: result['status'] == 'success'
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}