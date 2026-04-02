import 'package:flutter/material.dart';
import '../models/review.dart';
import '../services/api_service.dart';

class ReviewProvider with ChangeNotifier {
  List<Review> _reviews = [];
  bool isLoading = false;
  String? error;
  double _averageRating = 0;
  bool _canReview = false;
  int? _eligibleBookingId;

  List<Review> get reviews => _reviews;
  double get averageRating => _averageRating;
  bool get canReview => _canReview;
  int? get eligibleBookingId => _eligibleBookingId;

  // Load reviews for a futsal
  Future<void> loadReviews(int futsalId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiService.get('futsals/$futsalId/reviews');
      _reviews = (response['reviews'] as List)
          .map((json) => Review.fromJson(json))
          .toList();
      _averageRating = (response['averageRating'] ?? 0).toDouble();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  // Check if current user can review this futsal
  Future<void> checkCanReview(int futsalId) async {
    try {
      final response = await ApiService.get(
        'futsals/$futsalId/reviews/can-review',
      );
      _canReview = response['canReview'] ?? false;
      _eligibleBookingId = response['bookingId'];
      notifyListeners();
    } catch (e) {
      _canReview = false;
      _eligibleBookingId = null;
    }
  }

  // Submit a new review
  Future<Map<String, dynamic>> submitReview({
    required int futsalId,
    required int bookingId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await ApiService.post('reviews', {
        'futsalId': futsalId,
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
      });

      if (response['status'] == 'success') {
        await loadReviews(futsalId);
        _canReview = false;
        _eligibleBookingId = null;
        notifyListeners();
        return {'status': 'success', 'message': 'Review submitted!'};
      }
      return {'status': 'error', 'message': response['message']};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Edit a review
  Future<Map<String, dynamic>> updateReview({
    required int reviewId,
    required int futsalId,
    required double rating,
    String? comment,
  }) async {
    try {
      final response = await ApiService.put('reviews/$reviewId', {
        'rating': rating,
        'comment': comment,
      });

      if (response['status'] == 'success') {
        await loadReviews(futsalId);
        return {'status': 'success', 'message': 'Review updated!'};
      }
      return {'status': 'error', 'message': response['message']};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Delete a review
  Future<Map<String, dynamic>> deleteReview({
    required int reviewId,
    required int futsalId,
  }) async {
    try {
      final response = await ApiService.delete('reviews/$reviewId');

      if (response['status'] == 'success') {
        await loadReviews(futsalId);
        return {'status': 'success', 'message': 'Review deleted!'};
      }
      return {'status': 'error', 'message': response['message']};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Owner replies to a review
  Future<Map<String, dynamic>> replyToReview({
    required int reviewId,
    required int futsalId,
    required String reply,
  }) async {
    try {
      final response = await ApiService.put('reviews/$reviewId/reply', {
        'reply': reply,
      });

      if (response['status'] == 'success') {
        await loadReviews(futsalId);
        return {'status': 'success', 'message': 'Reply added!'};
      }
      return {'status': 'error', 'message': response['message']};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }

  void clearReviews() {
    _reviews = [];
    _averageRating = 0;
    _canReview = false;
    _eligibleBookingId = null;
    notifyListeners();
  }
}