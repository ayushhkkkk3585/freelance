import '../models/message.dart';
import 'api_service.dart';

class ChatService {
  // Get Messages for a Request
  static Future<List<Message>> getMessages(String requestId) async {
    final response = await ApiService.get('/chat/$requestId');
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> messages = data?['messages'] ?? [];
    return messages.map((json) => Message.fromJson(json)).toList();
  }

  // Send Message (only buyers can send)
  static Future<Message> sendMessage({
    required String requestId,
    required String content,
    bool isOffer = false,
    double? offerAmount,
    double? discountPercent,
    double? discountedPrice,
  }) async {
    final response = await ApiService.post('/chat/$requestId', {
      'content': content,
      'isOffer': isOffer,
      if (offerAmount != null) 'offerAmount': offerAmount,
      if (discountPercent != null) 'discountPercent': discountPercent,
      if (discountedPrice != null) 'discountedPrice': discountedPrice,
    });
    final data = response['data'] as Map<String, dynamic>;
    return Message.fromJson(data['message']);
  }

  // Get Unread Count
  static Future<int> getUnreadCount() async {
    final response = await ApiService.get('/chat/unread-count');
    final data = response['data'] as Map<String, dynamic>?;
    return data?['unreadCount'] ?? 0;
  }

  // Get Chat List (all conversations)
  static Future<List<Map<String, dynamic>>> getChatList() async {
    final response = await ApiService.get('/chat/conversations');
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> chats = data?['conversations'] ?? [];
    return chats.map((c) => c as Map<String, dynamic>).toList();
  }
}
