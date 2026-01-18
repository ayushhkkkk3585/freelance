class AppNotification {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type; // request_accepted, request_rejected, timeout, points_deducted, ticket_purchased, refund_processed, new_request
  final String? requestId;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.requestId,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    
    // Handle requestId which could be at root level or in data object
    String? extractedRequestId;
    if (json['requestId'] != null) {
      extractedRequestId = json['requestId'].toString();
    } else if (data['requestId'] != null) {
      extractedRequestId = data['requestId'].toString();
    }
    
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      requestId: extractedRequestId,
      data: data,
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'requestId': requestId,
      'data': data,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  AppNotification copyWith({
    String? id,
    String? userId,
    String? title,
    String? message,
    String? type,
    String? requestId,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AppNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      requestId: requestId ?? this.requestId,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if this notification is for a new request that can be accepted
  bool get isNewRequest => type == 'new_request';

  /// Check if this notification has a related request
  bool get hasRequest => requestId != null && requestId!.isNotEmpty;
}
