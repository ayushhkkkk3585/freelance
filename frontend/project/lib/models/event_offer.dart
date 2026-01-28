class EventOffer {
  final String id;
  final String buyerId;
  final String buyerName;
  final String? buyerPhotoUrl;
  final double buyerRating;
  final int buyerBookingsCount;
  final int buyerDealsCount;
  final String eventName;
  final String location;
  final DateTime eventDate;
  final int quantity;
  final String category;
  final String platform;
  final String? cardName;
  final String? offerDetails;
  final double offerAmount;
  final double discountPercent;
  final double discountedPrice;
  final String status; // 'active', 'accepted', 'expired', 'cancelled'
  final String? acceptedByClientId;
  final DateTime createdAt;
  final DateTime? expiresAt;

  EventOffer({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    this.buyerPhotoUrl,
    this.buyerRating = 0.0,
    this.buyerBookingsCount = 0,
    this.buyerDealsCount = 0,
    required this.eventName,
    required this.location,
    required this.eventDate,
    required this.quantity,
    required this.category,
    required this.platform,
    this.cardName,
    this.offerDetails,
    required this.offerAmount,
    this.discountPercent = 30,
    this.discountedPrice = 0,
    this.status = 'active',
    this.acceptedByClientId,
    required this.createdAt,
    this.expiresAt,
  });

  factory EventOffer.fromJson(Map<String, dynamic> json) {
    // Handle buyerId which could be a string or a populated object
    String extractBuyerId(dynamic value) {
      if (value == null) return '';
      if (value is String) return value;
      if (value is Map<String, dynamic>) {
        return value['_id']?.toString() ?? value['id']?.toString() ?? '';
      }
      return value.toString();
    }

    String extractBuyerName(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['name']?.toString() ?? 'Buyer';
      }
      return json['buyerName']?.toString() ?? 'Buyer';
    }

    String? extractBuyerPhoto(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['photoUrl'] ?? value['profileImage'];
      }
      return json['buyerPhotoUrl'];
    }

    double extractBuyerRating(dynamic value) {
      if (value is Map<String, dynamic>) {
        return (value['rating'] ?? 0.0).toDouble();
      }
      return (json['buyerRating'] ?? 0.0).toDouble();
    }

    int extractBuyerBookings(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['totalBookings'] ?? 0;
      }
      return json['buyerBookingsCount'] ?? 0;
    }

    int extractBuyerDeals(dynamic value) {
      if (value is Map<String, dynamic>) {
        return value['successfulDeals'] ?? 0;
      }
      return json['buyerDealsCount'] ?? 0;
    }

    final buyerData = json['buyerId'];

    return EventOffer(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      buyerId: extractBuyerId(buyerData),
      buyerName: extractBuyerName(buyerData),
      buyerPhotoUrl: extractBuyerPhoto(buyerData),
      buyerRating: extractBuyerRating(buyerData),
      buyerBookingsCount: extractBuyerBookings(buyerData),
      buyerDealsCount: extractBuyerDeals(buyerData),
      eventName: json['eventName'] ?? '',
      location: json['location'] ?? '',
      eventDate: json['eventDate'] != null
          ? DateTime.parse(json['eventDate'])
          : DateTime.now(),
      quantity: json['quantity'] ?? 1,
      category: json['category'] ?? 'Events',
      platform: json['platform'] ?? '',
      cardName: json['cardName'],
      offerDetails: json['offerDetails'],
      offerAmount: (json['offerAmount'] ?? 0.0).toDouble(),
      discountPercent: (json['discountPercent'] ?? 30.0).toDouble(),
      discountedPrice: (json['discountedPrice'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'active',
      acceptedByClientId: json['acceptedByClientId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'buyerPhotoUrl': buyerPhotoUrl,
      'buyerRating': buyerRating,
      'buyerBookingsCount': buyerBookingsCount,
      'buyerDealsCount': buyerDealsCount,
      'eventName': eventName,
      'location': location,
      'eventDate': eventDate.toIso8601String(),
      'quantity': quantity,
      'category': category,
      'platform': platform,
      'cardName': cardName,
      'offerDetails': offerDetails,
      'offerAmount': offerAmount,
      'discountPercent': discountPercent,
      'discountedPrice': discountedPrice,
      'status': status,
      'acceptedByClientId': acceptedByClientId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
