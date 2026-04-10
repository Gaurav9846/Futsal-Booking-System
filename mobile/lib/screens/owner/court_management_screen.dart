import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/court_provider.dart';
import '../../models/court.dart';
import 'court_management/widgets/court_card.dart';
import 'court_management/widgets/court_summary_card.dart';
import 'court_management/widgets/court_dialog.dart';

class CourtManagementScreen extends StatefulWidget {
  final int futsalId;
  final String futsalName;

  const CourtManagementScreen({
    super.key,
    required this.futsalId,
    required this.futsalName,
  });

  @override
  State<CourtManagementScreen> createState() => _CourtManagementScreenState();
}

class _CourtManagementScreenState extends State<CourtManagementScreen> {
  @override
  void initState() {
    super.initState();
    _loadCourts();
  }

  Future<void> _loadCourts() async {
    final provider = Provider.of<CourtProvider>(context, listen: false);
    await provider.loadCourts(widget.futsalId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.futsalName} - Courts'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCourts,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<CourtProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading && provider.courts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading courts...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return _buildErrorView(provider.error!);
          }

          if (provider.courts.isEmpty) {
            return _buildEmptyView();
          }

          return Column(
            children: [
              CourtSummaryCard(
                totalCourts: provider.courts.length,
                activeCourts: provider.courts.where((c) => c.isActive).length,
                maintenanceCourts: provider.courts.where((c) => c.isUnderMaintenance).length,
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.courts.length,
                  itemBuilder: (ctx, index) {
                    final court = provider.courts[index];
                    return CourtCard(
                      court: court,
                      onToggleActive: () => _toggleActive(court, provider),
                      onToggleMaintenance: () => _toggleMaintenance(court, provider),
                      onEdit: () => _showEditCourtDialog(court),
                      onSetPeakPrice: () => _showPeakPriceDialog(court, provider),
                      onDelete: () => _showDeleteDialog(court, provider),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCourtDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Court'),
        backgroundColor: Colors.green,
        tooltip: 'Add new court',
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
            Text(error, style: const TextStyle(fontSize: 16), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadCourts, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No courts added yet', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('Tap the + button to add your first court', style: TextStyle(color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddCourtDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add First Court'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCourtDialog() async {
    final result = await CourtDialog.show(context: context);
    if (result != null) {
      await _addCourt(result);
    }
  }

  Future<void> _showEditCourtDialog(Court court) async {
    final result = await CourtDialog.show(
      context: context,
      initialCourtNumber: court.courtNumber,
      initialCourtType: court.courtType,
      initialBasePrice: court.basePrice.toDouble(),
      initialPeakPrice: court.peakPrice?.toDouble(),
      initialAmenities: court.amenities,
    );
    if (result != null) {
      await _updateCourt(court.id, result);
    }
  }

  Future<void> _addCourt(Map<String, dynamic> courtData) async {
    final provider = Provider.of<CourtProvider>(context, listen: false);
    final data = {
      'futsalId': widget.futsalId,
      ...courtData,
    };

    _showLoading();
    final response = await provider.addCourt(data);
    _hideLoadingAndShowResult(response);
    if (response['status'] == 'success') {
      _loadCourts();
    }
  }

  Future<void> _updateCourt(int courtId, Map<String, dynamic> courtData) async {
    final provider = Provider.of<CourtProvider>(context, listen: false);
    _showLoading();
    final response = await provider.updateCourt(courtId, courtData);
    _hideLoadingAndShowResult(response);
    if (response['status'] == 'success') {
      _loadCourts();
    }
  }

  Future<void> _toggleMaintenance(Court court, CourtProvider provider) async {
    _showLoading();
    final response = await provider.toggleMaintenance(court.id, !court.isUnderMaintenance);
    _hideLoadingAndShowResult(response);
  }

  Future<void> _toggleActive(Court court, CourtProvider provider) async {
    _showLoading();
    final response = await provider.toggleActive(court.id, !court.isActive);
    _hideLoadingAndShowResult(response);
  }

  Future<void> _showPeakPriceDialog(Court court, CourtProvider provider) async {
    final peakPriceController = TextEditingController(text: court.peakPrice?.toString() ?? '');

    final result = await showDialog<double?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Peak Hour Price'),
        content: TextField(
          controller: peakPriceController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Peak Price (per hour)',
            prefixText: 'रू ',
            hintText: 'Leave empty to remove peak pricing',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              final peakPrice = peakPriceController.text.isNotEmpty
                  ? int.parse(peakPriceController.text)
                  : null;
              Navigator.pop(ctx, peakPrice?.toDouble());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (result != null) {
      _showLoading();
      final response = await provider.setPeakPrice(court.id, result.toInt());
      _hideLoadingAndShowResult(response);
    }
  }

  void _showDeleteDialog(Court court, CourtProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Court'),
        content: Text('Are you sure you want to delete Court ${court.courtNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteCourt(court.id, provider);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCourt(int courtId, CourtProvider provider) async {
    _showLoading();
    final response = await provider.deleteCourt(courtId);
    _hideLoadingAndShowResult(response);
    if (response['status'] == 'success') {
      _loadCourts();
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
        content: Text(response['message']),
        backgroundColor: response['status'] == 'success' ? Colors.green : Colors.red,
      ),
    );
  }
}