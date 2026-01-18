class EventRequest {
  final String id;
  final String clientId;
  final String? buyerId;
  final String eventName;
  final String location;
  final DateTime eventDate;
  final int quantity;
  final String cardName;
  final String offerDetails;
  final double finalAmount;
  // Pricing fields for profit logic
  final double originalPrice;       // What client pays (e.g., 1000)
  final double discountedPrice;     // What buyer pays using card (e.g., 700)
  final double buyerPayment;        // What app pays buyer (e.g., 800)
  final double clientRefund;        // What client gets back (e.g., 200)
  final double buyerProfit;         // Buyer's profit (e.g., 100)
  final double appProfit;           // App's profit (e.g., 200)
  final String? eventUrl;
  final String category;
  final String platform;
  final String status; // pending, accepted, completed, rejected, timeout, refunded
  final String? screenshotUrl;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;
  // Client review tracking
  final bool clientReviewSubmitted;
  final String? clientReviewId;

  EventRequest({
    required this.id,
    required this.clientId,
    this.buyerId,
    required this.eventName,
    required this.location,
    required this.eventDate,
    required this.quantity,
    required this.cardName,
    required this.offerDetails,
    required this.finalAmount,
    this.originalPrice = 0,
    this.discountedPrice = 0,
    this.buyerPayment = 0,
    this.clientRefund = 0,
    this.buyerProfit = 0,
    this.appProfit = 0,
    this.eventUrl,
    required this.category,
    required this.platform,
    this.status = 'pending',
    this.screenshotUrl,
    this.acceptedAt,
    this.completedAt,
    required this.createdAt,
    this.expiresAt,
    this.clientReviewSubmitted = false,
    this.clientReviewId,
  });

  factory EventRequest.fromJson(Map<String, dynamic> json) {
    // Handle clientId which could be a string or a populated object
    String extractClientId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        return value['_id']?.toString() ?? value['id']?.toString() ?? '';
      }
      return value.toString();
    }
    
    // Handle buyerId which could be null, a string, or a populated object
    String? extractBuyerId(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        return value['_id']?.toString() ?? value['id']?.toString();
      }
      return value.toString();
    }
    
    return EventRequest(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      clientId: extractClientId(json['clientId']),
      buyerId: extractBuyerId(json['buyerId']),
      eventName: json['eventName'] ?? '',
      location: json['location'] ?? '',
      eventDate: json['eventDate'] != null 
          ? DateTime.parse(json['eventDate']) 
          : DateTime.now(),
      quantity: json['quantity'] ?? 1,
      cardName: json['cardName'] ?? '',
      offerDetails: json['offerDetails'] ?? '',
      finalAmount: (json['finalAmount'] ?? 0.0).toDouble(),
      originalPrice: (json['originalPrice'] ?? json['finalAmount'] ?? 0.0).toDouble(),
      discountedPrice: (json['discountedPrice'] ?? 0.0).toDouble(),
      buyerPayment: (json['buyerPayment'] ?? 0.0).toDouble(),
      clientRefund: (json['clientRefund'] ?? 0.0).toDouble(),
      buyerProfit: (json['buyerProfit'] ?? 0.0).toDouble(),
      appProfit: (json['appProfit'] ?? 0.0).toDouble(),
      eventUrl: json['eventUrl'],
      category: json['category'] ?? '',
      platform: json['platform'] ?? '',
      status: json['status'] ?? 'pending',
      screenshotUrl: json['screenshotUrl'],
      acceptedAt: json['acceptedAt'] != null 
          ? DateTime.parse(json['acceptedAt']) 
          : null,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null || json['timerExpiresAt'] != null
          ? DateTime.parse(json['expiresAt'] ?? json['timerExpiresAt']) 
          : null,
      clientReviewSubmitted: json['clientReviewSubmitted'] ?? false,
      clientReviewId: json['clientReviewId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'buyerId': buyerId,
      'eventName': eventName,
      'location': location,
      'eventDate': eventDate.toIso8601String(),
      'quantity': quantity,
      'cardName': cardName,
      'offerDetails': offerDetails,
      'finalAmount': finalAmount,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'buyerPayment': buyerPayment,
      'clientRefund': clientRefund,
      'buyerProfit': buyerProfit,
      'appProfit': appProfit,
      'eventUrl': eventUrl,
      'category': category,
      'platform': platform,
      'status': status,
      'screenshotUrl': screenshotUrl,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'clientReviewSubmitted': clientReviewSubmitted,
      'clientReviewId': clientReviewId,
    };
  }

  EventRequest copyWith({
    String? id,
    String? clientId,
    String? buyerId,
    String? eventName,
    String? location,
    DateTime? eventDate,
    int? quantity,
    String? cardName,
    String? offerDetails,
    double? finalAmount,
    double? originalPrice,
    double? discountedPrice,
    double? buyerPayment,
    double? clientRefund,
    double? buyerProfit,
    double? appProfit,
    String? eventUrl,
    String? category,
    String? platform,
    String? status,
    String? screenshotUrl,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? clientReviewSubmitted,
    String? clientReviewId,
  }) {
    return EventRequest(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      buyerId: buyerId ?? this.buyerId,
      eventName: eventName ?? this.eventName,
      location: location ?? this.location,
      eventDate: eventDate ?? this.eventDate,
      quantity: quantity ?? this.quantity,
      cardName: cardName ?? this.cardName,
      offerDetails: offerDetails ?? this.offerDetails,
      finalAmount: finalAmount ?? this.finalAmount,
      originalPrice: originalPrice ?? this.originalPrice,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      buyerPayment: buyerPayment ?? this.buyerPayment,
      clientRefund: clientRefund ?? this.clientRefund,
      buyerProfit: buyerProfit ?? this.buyerProfit,
      appProfit: appProfit ?? this.appProfit,
      eventUrl: eventUrl ?? this.eventUrl,
      category: category ?? this.category,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      clientReviewSubmitted: clientReviewSubmitted ?? this.clientReviewSubmitted,
      clientReviewId: clientReviewId ?? this.clientReviewId,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  /// Check if client review is pending (request completed but review not submitted)
  bool get isClientReviewPending => status == 'completed' && !clientReviewSubmitted;
  
  /// Get client's net cost after refund
  double get clientNetCost => originalPrice - clientRefund;
  
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
