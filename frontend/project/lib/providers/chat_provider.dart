import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = false;
  String? _error;
  String? _currentRequestId;

  List<Message> get messages => _messages;
  List<Map<String, dynamic>> get chatList => _chatList;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set Current Request ID
  void setCurrentRequestId(String requestId) {
    _currentRequestId = requestId;
  }

  // Fetch Messages
  Future<void> fetchMessages(String requestId) async {
    _currentRequestId = requestId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _messages = await ChatService.getMessages(requestId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send Message
  Future<bool> sendMessage({
    required String requestId,
    required String content,
    bool isOffer = false,
    double? offerAmount,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final message = await ChatService.sendMessage(
        requestId: requestId,
        content: content,
        isOffer: isOffer,
        offerAmount: offerAmount,
      );
      _messages.add(message);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fetch Chat List
  Future<void> fetchChatList() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _chatList = await ChatService.getChatList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add Message (for real-time updates)
  void addMessage(Message message) {
    if (message.requestId == _currentRequestId) {
      _messages.add(message);
      notifyListeners();
    }
  }

  // Clear Messages
  void clearMessages() {
    _messages = [];
    _currentRequestId = null;
    notifyListeners();
  }

  // Clear Error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
