class Message {
  final String id;
  final String requestId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isOffer;
  final double? offerAmount;
  final double? discountPercent;
  final double? discountedPrice;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isOffer = false,
    this.offerAmount,
    this.discountPercent,
    this.discountedPrice,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? json['id'] ?? '',
      requestId: json['requestId'] ?? '',
      senderId: json['senderId'] ?? '',
      receiverId: json['receiverId'] ?? '',
      content: json['content'] ?? '',
      isOffer: json['isOffer'] ?? false,
      offerAmount: json['offerAmount']?.toDouble(),
      discountPercent: json['discountPercent']?.toDouble(),
      discountedPrice: json['discountedPrice']?.toDouble(),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requestId': requestId,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'isOffer': isOffer,
      'offerAmount': offerAmount,
      'discountPercent': discountPercent,
      'discountedPrice': discountedPrice,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
