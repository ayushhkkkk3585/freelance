// Helper class for extracted verification data
class ExtractedData {
  final String? bookingId;
  final String? amount;
  final String? date;
  final String? platform;

  ExtractedData({
    this.bookingId,
    this.amount,
    this.date,
    this.platform,
  });

  factory ExtractedData.fromJson(Map<String, dynamic> json) {
    return ExtractedData(
      bookingId: json['bookingId']?.toString(),
      amount: json['amount']?.toString(),
      date: json['date']?.toString(),
      platform: json['platform']?.toString(),
    );
  }
}

// Helper class for verification info
class VerificationInfo {
  final String status; // pending, verified, failed, manual_review
  final ExtractedData? extractedData;
  final List<String> warnings;
  final double confidence;

  VerificationInfo({
    required this.status,
    this.extractedData,
    this.warnings = const [],
    this.confidence = 0,
  });

  factory VerificationInfo.fromJson(Map<String, dynamic> json) {
    return VerificationInfo(
      status: json['status'] ?? 'pending',
      extractedData: json['extractedData'] != null
          ? ExtractedData.fromJson(json['extractedData'])
          : null,
      warnings: List<String>.from(json['warnings'] ?? []),
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

// Helper class for escrow info
class EscrowInfo {
  final String status; // none, held, released, refunded, dispute
  final DateTime? heldAt;
  final DateTime? clientDeadline;
  final DateTime? releasedAt;
  final String? disputeReason;
  final String? resolution;

  EscrowInfo({
    required this.status,
    this.heldAt,
    this.clientDeadline,
    this.releasedAt,
    this.disputeReason,
    this.resolution,
  });

  factory EscrowInfo.fromJson(Map<String, dynamic> json) {
    return EscrowInfo(
      status: json['status'] ?? 'none',
      heldAt: json['heldAt'] != null ? DateTime.parse(json['heldAt']) : null,
      clientDeadline: json['clientDeadline'] != null
          ? DateTime.parse(json['clientDeadline'])
          : null,
      releasedAt: json['releasedAt'] != null
          ? DateTime.parse(json['releasedAt'])
          : null,
      disputeReason: json['disputeReason'],
      resolution: json['resolution'],
    );
  }

  Duration? get remainingTime {
    if (clientDeadline == null) return null;
    final diff = clientDeadline!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

// Helper class for dispute info
class DisputeInfo {
  final bool isDisputed;
  final String? raisedBy;
  final DateTime? raisedAt;
  final String? reason;
  final bool resolved;
  final String? resolution; // client_wins, buyer_wins, dispute_rejected
  final DateTime? resolvedAt;

  DisputeInfo({
    this.isDisputed = false,
    this.raisedBy,
    this.raisedAt,
    this.reason,
    this.resolved = false,
    this.resolution,
    this.resolvedAt,
  });

  factory DisputeInfo.fromJson(Map<String, dynamic> json) {
    return DisputeInfo(
      isDisputed: json['isDisputed'] ?? false,
      raisedBy: json['raisedBy']?.toString(),
      raisedAt: json['raisedAt'] != null ? DateTime.parse(json['raisedAt']) : null,
      reason: json['reason'],
      resolved: json['resolved'] ?? false,
      resolution: json['resolution'],
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
    );
  }
}

class EventRequest {
  final String id;
  final String clientId;
  final String? buyerId;
  // Client info (from populated object)
  final String? clientName;
  final String? clientPhone;
  final String? clientEmail;
  // Buyer info (from populated object)
  final String? buyerName;
  final String? buyerPhone;
  final String? buyerEmail;
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
  // Escrow fields
  final EscrowInfo? escrow;
  final VerificationInfo? verification;
  // Dispute fields
  final DisputeInfo? dispute;

  EventRequest({
    required this.id,
    required this.clientId,
    this.buyerId,
    this.clientName,
    this.clientPhone,
    this.clientEmail,
    this.buyerName,
    this.buyerPhone,
    this.buyerEmail,
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
    this.escrow,
    this.verification,
    this.dispute,
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
    
    // Extract user details from populated objects
    String? extractUserField(dynamic value, String field) {
      if (value == null) return null;
      if (value is Map<String, dynamic>) {
        return value[field]?.toString();
      }
      return null;
    }
    
    return EventRequest(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      clientId: extractClientId(json['clientId']),
      buyerId: extractBuyerId(json['buyerId']),
      clientName: extractUserField(json['clientId'], 'name'),
      clientPhone: extractUserField(json['clientId'], 'phone'),
      clientEmail: extractUserField(json['clientId'], 'email'),
      buyerName: extractUserField(json['buyerId'], 'name'),
      buyerPhone: extractUserField(json['buyerId'], 'phone'),
      buyerEmail: extractUserField(json['buyerId'], 'email'),
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
      escrow: json['escrow'] != null ? EscrowInfo.fromJson(json['escrow']) : null,
      verification: json['verification'] != null ? VerificationInfo.fromJson(json['verification']) : null,
      dispute: json['dispute'] != null ? DisputeInfo.fromJson(json['dispute']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'buyerId': buyerId,
      'clientName': clientName,
      'clientPhone': clientPhone,
      'clientEmail': clientEmail,
      'buyerName': buyerName,
      'buyerPhone': buyerPhone,
      'buyerEmail': buyerEmail,
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
      'escrow': escrow != null ? {
        'status': escrow!.status,
        'heldAt': escrow!.heldAt?.toIso8601String(),
        'clientDeadline': escrow!.clientDeadline?.toIso8601String(),
        'releasedAt': escrow!.releasedAt?.toIso8601String(),
        'disputeReason': escrow!.disputeReason,
        'resolution': escrow!.resolution,
      } : null,
      'verification': verification != null ? {
        'status': verification!.status,
        'confidence': verification!.confidence,
        'warnings': verification!.warnings,
      } : null,
      'dispute': dispute != null ? {
        'isDisputed': dispute!.isDisputed,
        'raisedBy': dispute!.raisedBy,
        'raisedAt': dispute!.raisedAt?.toIso8601String(),
        'reason': dispute!.reason,
        'resolved': dispute!.resolved,
        'resolution': dispute!.resolution,
        'resolvedAt': dispute!.resolvedAt?.toIso8601String(),
      } : null,
    };
  }

  EventRequest copyWith({
    String? id,
    String? clientId,
    String? buyerId,
    String? clientName,
    String? clientPhone,
    String? clientEmail,
    String? buyerName,
    String? buyerPhone,
    String? buyerEmail,
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
    EscrowInfo? escrow,
    VerificationInfo? verification,
    DisputeInfo? dispute,
  }) {
    return EventRequest(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      buyerId: buyerId ?? this.buyerId,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerEmail: buyerEmail ?? this.buyerEmail,
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
      escrow: escrow ?? this.escrow,
      verification: verification ?? this.verification,
      dispute: dispute ?? this.dispute,
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
  
  /// Check if ticket is in escrow (waiting for client verification)
  bool get isInEscrow => escrow?.status == 'held';
  
  /// Check if ticket needs verification (buyer uploaded, client needs to confirm)
  bool get needsVerification => status == 'completed' && escrow?.status == 'held';
  
  /// Check if there's a dispute
  bool get isDisputed => dispute?.isDisputed ?? escrow?.status == 'disputed';
  
  /// Get escrow deadline remaining time
  Duration? get escrowRemainingTime => escrow?.remainingTime;
  
  Duration? get remainingTime {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}
