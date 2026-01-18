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
  final String? eventUrl;
  final String category;
  final String platform;
  final String status; // pending, accepted, completed, rejected, timeout, refunded
  final String? screenshotUrl;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? expiresAt;

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
    this.eventUrl,
    required this.category,
    required this.platform,
    this.status = 'pending',
    this.screenshotUrl,
    this.acceptedAt,
    this.completedAt,
    required this.createdAt,
    this.expiresAt,
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
      'eventUrl': eventUrl,
      'category': category,
      'platform': platform,
      'status': status,
      'screenshotUrl': screenshotUrl,
      'acceptedAt': acceptedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
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
    String? eventUrl,
    String? category,
    String? platform,
    String? status,
    String? screenshotUrl,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
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
      eventUrl: eventUrl ?? this.eventUrl,
      category: category ?? this.category,
      platform: platform ?? this.platform,
      status: status ?? this.status,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isCompleted => status == 'completed';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
