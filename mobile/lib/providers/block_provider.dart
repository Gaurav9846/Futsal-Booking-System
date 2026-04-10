import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/block.dart';

class BlockProvider extends ChangeNotifier {
  List<Block> _blocks = [];
  bool _isLoading = false;
  String? _error;
  int? _currentFutsalId;

  List<Block> get blocks => _blocks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load blocked players for a specific futsal
  Future<void> loadBlockedPlayers(int futsalId) async {
    _currentFutsalId = futsalId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getBlockedPlayers(futsalId: futsalId);

      if (response['blocks'] != null) {
        _blocks = (response['blocks'] as List)
            .map((json) => Block.fromJson(json))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // ✅ ADD THIS - Check if a player is blocked at a specific futsal
  Future<Map<String, dynamic>> checkIsBlocked({
    required int playerId,
    required int futsalId,
  }) async {
    try {
      final response = await ApiService.checkIsBlocked(
          playerId: playerId, futsalId: futsalId);

      return {
        'status': 'success',
        'isBlocked': response['isBlocked'] ?? false,
        'reason': response['reason'],
      };
    } catch (e) {
      debugPrint('Error checking block status: $e');
      return {
        'status': 'error',
        'isBlocked': false,
        'message': e.toString(),
      };
    }
  }

  // Block a player
  Future<Map<String, dynamic>> blockPlayer({
    required int playerId,
    required int futsalId,
    String? reason,
  }) async {
    try {
      final response = await ApiService.post('owner/blocks', {
        'playerId': playerId,
        'futsalId': futsalId,
        'reason': reason,
      });

      if (response['status'] == 'success') {
        await loadBlockedPlayers(futsalId);
        return {
          'status': 'success',
          'message': response['message'] ?? 'Player blocked successfully',
        };
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to block player',
      };
    } catch (e) {
      debugPrint('Error blocking player: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Unblock a player
  Future<Map<String, dynamic>> unblockPlayer(int playerId, int futsalId) async {
    try {
      final response = await ApiService.unblockPlayer(
          playerId: playerId, futsalId: futsalId);

      if (response['status'] == 'success') {
        _blocks.removeWhere(
            (b) => b.playerId == playerId && b.futsalId == futsalId);
        notifyListeners();
        return {
          'status': 'success',
          'message': response['message'] ?? 'Player unblocked successfully',
        };
      }
      return {
        'status': 'error',
        'message': response['message'] ?? 'Failed to unblock player',
      };
    } catch (e) {
      debugPrint('Error unblocking player: $e');
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // ✅ ADD THIS - Reload blocked players
  Future<void> reloadBlockedPlayers() async {
    if (_currentFutsalId != null) {
      await loadBlockedPlayers(_currentFutsalId!);
    }
  }

  // Check if a player is blocked for a specific futsal (from local list)
  bool isPlayerBlocked(int playerId, int futsalId) {
    return _blocks.any((b) => b.playerId == playerId && b.futsalId == futsalId);
  }

  // ✅ ADD THIS - Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear data
  void clearData() {
    _blocks = [];
    _currentFutsalId = null;
    notifyListeners();
  }
}
