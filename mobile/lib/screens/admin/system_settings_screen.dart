import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SettingsProvider>(context, listen: false).loadSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                Provider.of<SettingsProvider>(context, listen: false)
                    .loadSettings(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<SettingsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.green),
                  SizedBox(height: 16),
                  Text('Loading settings...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 48, color: Colors.red.shade300),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadSettings(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoBanner(),
              const SizedBox(height: 20),
              _buildApprovalSettings(provider),
              const SizedBox(height: 16),
              _buildBookingSettings(provider),
              const SizedBox(height: 16),
              _buildSlotGenerationSettings(provider),
              const SizedBox(height: 16),
              _buildPlatformSettings(provider),
              const SizedBox(height: 24),
              _buildSaveButton(provider),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'These settings control platform-wide behavior. Changes take effect immediately.',
              style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalSettings(SettingsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Approval Settings'),
        _buildSwitchTile(
          title: 'Auto-approve Owner Registrations',
          subtitle: 'Owners are approved automatically without admin review',
          value: provider.autoApproveOwners,
          onChanged: (v) => provider.setAutoApproveOwners(v),
          icon: Icons.person_add,
          color: Colors.orange,
        ),
        _buildSwitchTile(
          title: 'Auto-approve Futsal Listings',
          subtitle: 'Futsal listings go live without admin review',
          value: provider.autoApproveFutsals,
          onChanged: (v) => provider.setAutoApproveFutsals(v),
          icon: Icons.sports_soccer,
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildBookingSettings(SettingsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Booking Settings'),
        _buildStepperTile(
          title: 'Cancellation Window',
          subtitle: 'Hours before slot when cancellation is allowed',
          value: provider.bookingCancellationHours,
          min: 1,
          max: 24,
          unit: 'hours',
          icon: Icons.cancel_outlined,
          color: Colors.red,
          onChanged: (v) => provider.setBookingCancellationHours(v), // ✅ Fixed
        ),
        _buildStepperTile(
          title: 'Slot Lock Duration',
          subtitle: 'Minutes a slot stays locked during payment process',
          value: provider.slotLockMinutes,
          min: 1,
          max: 15,
          unit: 'minutes',
          icon: Icons.lock_clock,
          color: Colors.purple,
          onChanged: (v) => provider.setSlotLockMinutes(v), // ✅ Fixed
        ),
      ],
    );
  }

  Widget _buildSlotGenerationSettings(SettingsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Slot Generation'),
        _buildStepperTile(
          title: 'Advance Slot Generation',
          subtitle: 'How many days ahead slots are auto-generated',
          value: provider.slotGenerationDays,
          min: 7,
          max: 60,
          unit: 'days',
          icon: Icons.calendar_month,
          color: Colors.blue,
          onChanged: (v) => provider.setSlotGenerationDays(v), // ✅ Fixed
        ),
      ],
    );
  }

  Widget _buildPlatformSettings(SettingsProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Platform'),
        _buildSwitchTile(
          title: 'Maintenance Mode',
          subtitle: 'Temporarily disable all bookings for platform maintenance',
          value: provider.maintenanceMode,
          onChanged: (v) => provider.setMaintenanceMode(v), // ✅ Fixed
          icon: Icons.build,
          color: Colors.red,
          isDestructive: true,
        ),
      ],
    );
  }

  Widget _buildSaveButton(SettingsProvider provider) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: provider.isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(
          provider.isSaving ? 'Saving...' : 'Save Settings',
          style: const TextStyle(fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: provider.isSaving ? null : () => _saveSettings(provider),
      ),
    );
  }

  Future<void> _saveSettings(SettingsProvider provider) async {
    final success = await provider.saveSettings();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Settings saved successfully'
              : 'Failed to save settings'),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      if (success) {
        // Optional: Show restart required message if maintenance mode changed
        if (provider.maintenanceMode) {
          _showMaintenanceModeDialog();
        }
      }
    }
  }

  void _showMaintenanceModeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Maintenance Mode Active'),
        content: const Text(
          'Maintenance mode is now active. Users will not be able to make new bookings until you disable this setting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
    bool isDestructive = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDestructive && value ? Colors.red : null,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDestructive ? Colors.red : Colors.green,
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildStepperTile({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required String unit,
    required IconData icon,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: value > min ? color : Colors.grey,
                  onPressed: value > min ? () => onChanged(value - 1) : null,
                ),
                Text(
                  '$value $unit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: value < max ? color : Colors.grey,
                  onPressed: value < max ? () => onChanged(value + 1) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
