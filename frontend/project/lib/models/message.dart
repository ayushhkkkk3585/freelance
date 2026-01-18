class Message {
  final String id;
  final String requestId;
  final String senderId;
  final String receiverId;
  final String content;
  final bool isOffer;
  final double? offerAmount;
  final DateTime createdAt;

  Message({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.isOffer = false,
    this.offerAmount,
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
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
