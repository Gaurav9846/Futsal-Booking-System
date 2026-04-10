import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/favorite.dart';

class FavoriteProvider extends ChangeNotifier {
  List<Favorite> _favorites = [];
  bool _isLoading = false;
  String? _error;

  List<Favorite> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load user's favorites
  Future<void> loadFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('favorites');
      
      if (response['favorites'] != null) {
        _favorites = (response['favorites'] as List)
            .map((json) => Favorite.fromJson(json))
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

  // Check if a futsal is favorited
  bool isFavorite(int futsalId) {
    return _favorites.any((f) => f.futsalId == futsalId);
  }

  // Add to favorites
  Future<bool> addFavorite(int futsalId) async {
    try {
      final response = await ApiService.post('favorites', {
        'futsalId': futsalId,
      });

      if (response['status'] == 'success') {
        // Add to local list
        _favorites.add(Favorite.fromJson(response['favorite']));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding favorite: $e');
      return false;
    }
  }

  // Remove from favorites
  Future<bool> removeFavorite(int futsalId) async {
    try {
      final response = await ApiService.delete('favorites/$futsalId');

      if (response['status'] == 'success') {
        // Remove from local list
        _favorites.removeWhere((f) => f.futsalId == futsalId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error removing favorite: $e');
      return false;
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(int futsalId) async {
    if (isFavorite(futsalId)) {
      return await removeFavorite(futsalId);
    } else {
      return await addFavorite(futsalId);
    }
  }
}