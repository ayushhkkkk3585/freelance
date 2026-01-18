import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  // Get Reviews for User
  static Future<List<Review>> getReviewsForUser(String userId) async {
    final response = await ApiService.get('/reviews/user/$userId');
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> reviews = data?['reviews'] ?? [];
    return reviews.map((json) => Review.fromJson(json)).toList();
  }

  // Create Review
  static Future<Review> createReview({
    required String requestId,
    required int rating,
    String? comment,
  }) async {
    final response = await ApiService.post('/reviews', {
      'requestId': requestId,
      'rating': rating,
      if (comment != null) 'comment': comment,
    });
    final data = response['data'] as Map<String, dynamic>;
    return Review.fromJson(data['review']);
  }
}
