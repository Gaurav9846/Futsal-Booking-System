// lib/screens/player/futsal_details/widgets/reviews_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../models/futsal.dart';
import '../../../../models/review.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/review_provider.dart';
import '../../../../utils/date_formatter.dart';

class ReviewsTab extends StatefulWidget {
  final Futsal futsal;

  const ReviewsTab({
    super.key,
    required this.futsal,
  });

  @override
  State<ReviewsTab> createState() => _ReviewsTabState();
}

class _ReviewsTabState extends State<ReviewsTab> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadReviewData();
  }

  void _loadReviewData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      reviewProvider.loadReviews(widget.futsal.id);
      reviewProvider.checkCanReview(widget.futsal.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        final avgRating = reviewProvider.averageRating;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildRatingSummaryCard(avgRating, reviews.length),
            const SizedBox(height: 16),
            if (reviewProvider.canReview && !_isProcessing)
              _buildWriteReviewButton(reviewProvider.eligibleBookingId!),
            const SizedBox(height: 16),
            const Text(
              'Recent Reviews',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (reviewProvider.isLoading)
              const Center(child: CircularProgressIndicator(color: Colors.green))
            else if (reviews.isEmpty)
              _buildEmptyReviews()
            else
              ...reviews.map((review) => _buildReviewCard(review, reviewProvider)),
          ],
        );
      },
    );
  }

  Widget _buildRatingSummaryCard(double avgRating, int reviewCount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  avgRating > 0 ? avgRating.toStringAsFixed(1) : 'N/A',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < avgRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 16,
                    );
                  }),
                ),
                Text(
                  '$reviewCount reviews',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final star = 5 - index;
                  return _buildRatingRow(star);
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(int star) {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, _) {
        final reviews = reviewProvider.reviews;
        final count = reviews.where((r) => r.rating.round() == star).length;
        final fraction = reviews.isEmpty ? 0.0 : count / reviews.length;

        return Row(
          children: [
            Text('$star', style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 4),
            const Icon(Icons.star, size: 12, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
              ),
            ),
            const SizedBox(width: 8),
            Text('$count', style: const TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }

  Widget _buildWriteReviewButton(int bookingId) {
    return OutlinedButton.icon(
      onPressed: _isProcessing ? null : () => _showWriteReviewDialog(bookingId),
      icon: const Icon(Icons.edit),
      label: const Text('Write a Review'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.green,
        side: const BorderSide(color: Colors.green),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildEmptyReviews() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.star_border, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text('No reviews yet',
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Review review, ReviewProvider reviewProvider) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isOwnReview = authProvider.user?.id == review.userId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.green.shade100,
                  child: Text(
                    review.userName.isNotEmpty
                        ? review.userName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(review.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        DateFormatter.formatDateMedium(review.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 14,
                    );
                  }),
                ),
                if (isOwnReview && !_isProcessing)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 16),
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditReviewDialog(review);
                      } else if (value == 'delete') {
                        _confirmDeleteReview(review);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete', child: Text('Delete')),
                    ],
                  ),
              ],
            ),
            if (review.comment?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(review.comment!, style: const TextStyle(fontSize: 14)),
            ],
            if (review.reply?.isNotEmpty ?? false)
              _buildOwnerReply(review.reply!),
          ],
        ),
      ),
    );
  }

  Widget _buildOwnerReply(String reply) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Owner Reply',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(reply, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  void _showWriteReviewDialog(int bookingId) {
    double selectedRating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Write a Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your experience:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedRating = index + 1.0),
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Share your experience (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _isProcessing
                  ? null
                  : () => _submitReview(
                        ctx,
                        bookingId,
                        selectedRating,
                        commentController.text.trim(),
                      ),
              child:
                  const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReview(
    BuildContext dialogContext,
    int bookingId,
    double rating,
    String comment,
  ) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.submitReview(
        futsalId: widget.futsal.id,
        bookingId: bookingId,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error submitting review: ${e.toString()}',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showEditReviewDialog(Review review) {
    double selectedRating = review.rating;
    final commentController = TextEditingController(text: review.comment ?? '');

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedRating = index + 1.0),
                    child: Icon(
                      index < selectedRating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Your review',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: _isProcessing
                  ? null
                  : () => _updateReview(
                        ctx,
                        review.id,
                        selectedRating,
                        commentController.text.trim(),
                      ),
              child:
                  const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateReview(
    BuildContext dialogContext,
    int reviewId,
    double rating,
    String comment,
  ) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.updateReview(
        reviewId: reviewId,
        futsalId: widget.futsal.id,
        rating: rating,
        comment: comment.isEmpty ? null : comment,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error updating review: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmDeleteReview(Review review) {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete your review?'),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed:
                _isProcessing ? null : () => _deleteReview(ctx, review.id),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(BuildContext dialogContext, int reviewId) async {
    setState(() => _isProcessing = true);
    Navigator.pop(dialogContext);

    try {
      final reviewProvider =
          Provider.of<ReviewProvider>(context, listen: false);
      final result = await reviewProvider.deleteReview(
        reviewId: reviewId,
        futsalId: widget.futsal.id,
      );

      if (mounted) {
        _showSnackBar(
          result['message'],
          isError: result['status'] != 'success',
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error deleting review: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}