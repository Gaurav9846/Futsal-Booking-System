import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/settings.dart';

class SettingsProvider extends ChangeNotifier {
  bool isLoading = false;
  bool isSaving = false;
  String? error;
  
  SystemSettings? _settings;
  
  SystemSettings get settings => _settings!;
  
  // Convenience getters
  bool get autoApproveOwners => _settings?.autoApproveOwners ?? false;
  bool get autoApproveFutsals => _settings?.autoApproveFutsals ?? false;
  bool get maintenanceMode => _settings?.maintenanceMode ?? false;
  int get bookingCancellationHours => _settings?.bookingCancellationHours ?? 2;
  int get slotLockMinutes => _settings?.slotLockMinutes ?? 5;
  int get slotGenerationDays => _settings?.slotGenerationDays ?? 30;

  Future<void> loadSettings() async {
    isLoading = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.getSystemSettings();
      if (response['status'] == 'success') {
        _settings = SystemSettings.fromJson(response['data']);
      } else {
        error = response['message'] ?? 'Failed to load settings';
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Load settings error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> saveSettings() async {
    isSaving = true;
    error = null;
    notifyListeners();
    
    try {
      final response = await ApiService.updateSystemSettings({
        'autoApproveOwners': autoApproveOwners,
        'autoApproveFutsals': autoApproveFutsals,
        'maintenanceMode': maintenanceMode,
        'bookingCancellationHours': bookingCancellationHours,
        'slotLockMinutes': slotLockMinutes,
        'slotGenerationDays': slotGenerationDays,
      });
      
      if (response['status'] == 'success') {
        _settings = SystemSettings.fromJson(response['data']);
        return true;
      } else {
        error = response['message'] ?? 'Failed to save settings';
        return false;
      }
    } catch (e) {
      error = e.toString();
      debugPrint('Save settings error: $e');
      return false;
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }
  
  // Update individual settings
  void setAutoApproveOwners(bool value) {
    _settings = _settings?.copyWith(autoApproveOwners: value);
    notifyListeners();
  }
  
  void setAutoApproveFutsals(bool value) {
    _settings = _settings?.copyWith(autoApproveFutsals: value);
    notifyListeners();
  }
  
  void setMaintenanceMode(bool value) {
    _settings = _settings?.copyWith(maintenanceMode: value);
    notifyListeners();
  }
  
  void setBookingCancellationHours(int value) {
    _settings = _settings?.copyWith(bookingCancellationHours: value);
    notifyListeners();
  }
  
  void setSlotLockMinutes(int value) {
    _settings = _settings?.copyWith(slotLockMinutes: value);
    notifyListeners();
  }
  
  void setSlotGenerationDays(int value) {
    _settings = _settings?.copyWith(slotGenerationDays: value);
    notifyListeners();
  }
  
  // Reset to defaults
  void resetToDefaults() {
    _settings = SystemSettings(
      id: _settings?.id ?? 0,
      autoApproveOwners: false,
      autoApproveFutsals: false,
      maintenanceMode: false,
      bookingCancellationHours: 2,
      slotLockMinutes: 5,
      slotGenerationDays: 30,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }
}