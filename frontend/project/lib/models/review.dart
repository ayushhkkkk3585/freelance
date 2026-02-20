class Review {
  final String id;
  final String requestId;
  final String? requestEventName;
  final String reviewerId;
  final String? reviewerName;
  final String? reviewerImage;
  final String revieweeId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.requestId,
    this.requestEventName,
    required this.reviewerId,
    this.reviewerName,
    this.reviewerImage,
    required this.revieweeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    // Handle populated requestId (can be string or object)
    String requestId = '';
    String? requestEventName;
    if (json['requestId'] is Map) {
      requestId = json['requestId']['_id']?.toString() ?? '';
      requestEventName = json['requestId']['eventName'];
    } else {
      requestId = json['requestId']?.toString() ?? '';
    }

    // Handle populated reviewerId (can be string or object)
    String reviewerId = '';
    String? reviewerName;
    String? reviewerImage;
    if (json['reviewerId'] is Map) {
      reviewerId = json['reviewerId']['_id']?.toString() ?? '';
      reviewerName = json['reviewerId']['name'];
      reviewerImage = json['reviewerId']['profileImage'];
    } else {
      reviewerId = json['reviewerId']?.toString() ?? '';
    }

    // Handle revieweeId (can be string or object)
    String revieweeId = '';
    if (json['revieweeId'] is Map) {
      revieweeId = json['revieweeId']['_id']?.toString() ?? '';
    } else {
      revieweeId = json['revieweeId']?.toString() ?? '';
    }

    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      requestId: requestId,
      requestEventName: requestEventName,
      reviewerId: reviewerId,
      reviewerName: reviewerName,
      reviewerImage: reviewerImage,
      revieweeId: revieweeId,
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
