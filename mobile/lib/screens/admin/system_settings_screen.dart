import 'package:flutter/material.dart';

class SystemSettingsScreen extends StatefulWidget {
  const SystemSettingsScreen({super.key});

  @override
  State<SystemSettingsScreen> createState() => _SystemSettingsScreenState();
}

class _SystemSettingsScreenState extends State<SystemSettingsScreen> {
  // Settings state
  bool _autoApproveOwners = false;
  bool _autoApproveFutsals = false;
  bool _maintenanceMode = false;
  int _bookingCancellationHours = 2;
  int _slotLockMinutes = 5;
  int _slotGenerationDays = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Info banner
          Container(
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
                    style: TextStyle(
                        fontSize: 13, color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Approval settings
          _buildSectionHeader('Approval Settings'),
          _buildSwitchTile(
            title: 'Auto-approve Owner Registrations',
            subtitle:
                'Owners are approved automatically without admin review',
            value: _autoApproveOwners,
            onChanged: (v) => setState(() => _autoApproveOwners = v),
            icon: Icons.person_add,
            color: Colors.orange,
          ),
          _buildSwitchTile(
            title: 'Auto-approve Futsal Listings',
            subtitle: 'Futsal listings go live without admin review',
            value: _autoApproveFutsals,
            onChanged: (v) => setState(() => _autoApproveFutsals = v),
            icon: Icons.sports_soccer,
            color: Colors.green,
          ),

          const SizedBox(height: 16),

          // Booking settings
          _buildSectionHeader('Booking Settings'),
          _buildStepperTile(
            title: 'Cancellation Window',
            subtitle: 'Hours before slot when cancellation is allowed',
            value: _bookingCancellationHours,
            min: 1,
            max: 24,
            unit: 'hours',
            icon: Icons.cancel_outlined,
            color: Colors.red,
            onChanged: (v) =>
                setState(() => _bookingCancellationHours = v),
          ),
          _buildStepperTile(
            title: 'Slot Lock Duration',
            subtitle:
                'Minutes a slot stays locked during payment process',
            value: _slotLockMinutes,
            min: 1,
            max: 15,
            unit: 'minutes',
            icon: Icons.lock_clock,
            color: Colors.purple,
            onChanged: (v) => setState(() => _slotLockMinutes = v),
          ),

          const SizedBox(height: 16),

          // Slot generation settings
          _buildSectionHeader('Slot Generation'),
          _buildStepperTile(
            title: 'Advance Slot Generation',
            subtitle: 'How many days ahead slots are auto-generated',
            value: _slotGenerationDays,
            min: 7,
            max: 60,
            unit: 'days',
            icon: Icons.calendar_month,
            color: Colors.blue,
            onChanged: (v) => setState(() => _slotGenerationDays = v),
          ),

          const SizedBox(height: 16),

          // Maintenance mode
          _buildSectionHeader('Platform'),
          _buildSwitchTile(
            title: 'Maintenance Mode',
            subtitle:
                'Temporarily disable all bookings for platform maintenance',
            value: _maintenanceMode,
            onChanged: (v) => setState(() => _maintenanceMode = v),
            icon: Icons.build,
            color: Colors.red,
            isDestructive: true,
          ),

          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Save Settings',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _saveSettings,
            ),
          ),

          const SizedBox(height: 40),
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
                      style:
                          const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    subtitle,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: value > min ? color : Colors.grey,
                  onPressed: value > min
                      ? () => onChanged(value - 1)
                      : null,
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
                  onPressed: value < max
                      ? () => onChanged(value + 1)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _saveSettings() {
    // For now show a snackbar — backend integration can be added later
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}