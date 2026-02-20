import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/review.dart';
import '../../services/review_service.dart';

class ReviewsScreen extends StatefulWidget {
  final String userId;
  final String userRole;

  const ReviewsScreen({
    super.key,
    required this.userId,
    required this.userRole,
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Loading reviews for userId: ${widget.userId}, role: ${widget.userRole}');

      List<Review> reviews;
      if (widget.userRole == 'buyer') {
        // For buyer: fetch reviews received by this buyer
        reviews = await ReviewService.getReviewsForUser(widget.userId);
      } else {
        // For client: fetch reviews posted by this client
        reviews = await ReviewService.getMyReviews();
      }

      print('Received ${reviews.length} reviews');

      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading reviews: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        title: Text(
          widget.userRole == 'buyer' ? 'My Reviews' : 'Reviews Posted',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          : _error != null
              ? _buildErrorState()
              : _reviews.isEmpty
                  ? _buildEmptyState()
                  : _buildReviewsList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load reviews',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadReviews,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryRed,
            ),
            child: const Text(
              'Retry',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline,
            size: 64,
            color: AppTheme.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            widget.userRole == 'buyer'
                ? 'No reviews received yet'
                : 'No reviews posted yet',
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userRole == 'buyer'
                ? 'Complete bookings to receive reviews'
                : 'Complete transactions to post reviews',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.grey.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
    return RefreshIndicator(
      onRefresh: _loadReviews,
      color: AppTheme.primaryRed,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _reviews.length,
        itemBuilder: (context, index) {
          final review = _reviews[index];
          return _buildReviewCard(review);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reviewer info
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                backgroundImage: review.reviewerImage != null
                    ? NetworkImage(review.reviewerImage!)
                    : null,
                child: review.reviewerImage == null
                    ? Text(
                        (review.reviewerName ?? 'U').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.primaryRed,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.reviewerName ?? 'Anonymous',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (review.requestEventName != null)
                      Text(
                        review.requestEventName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Text(
                _formatDate(review.createdAt),
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Star ratings
          Row(
            children: [
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    i < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  );
                }),
              ),
              const SizedBox(width: 8),
              Text(
                '${review.rating}/5',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}m ago';
      }
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
