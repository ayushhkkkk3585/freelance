import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/event_offer.dart';
import '../services/chat_service.dart';
import '../services/offer_service.dart';

class ChatProvider with ChangeNotifier {
  List<Message> _messages = [];
  List<Map<String, dynamic>> _chatList = [];
  List<EventOffer> _offers = [];
  List<EventOffer> _myOffers = [];
  bool _isLoading = false;
  String? _error;
  String? _currentRequestId;

  List<Message> get messages => _messages;
  List<Map<String, dynamic>> get chatList => _chatList;
  List<EventOffer> get offers => _offers;
  List<EventOffer> get myOffers => _myOffers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Set Current Request ID
  void setCurrentRequestId(String requestId) {
    _currentRequestId = requestId;
  }

  // Fetch all offers (for clients)
  Future<void> fetchOffers({String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _offers = await OfferService.getAllOffers(category: category);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch my offers (for buyers)
  Future<void> fetchMyOffers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myOffers = await OfferService.getMyOffers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create offer (for buyers)
  Future<bool> createOffer({
    required String eventName,
    required String location,
    required DateTime eventDate,
    required int quantity,
    required String category,
    required String platform,
    String? cardName,
    String? offerDetails,
    required double offerAmount,
    double discountPercent = 30,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final offer = await OfferService.createOffer(
        eventName: eventName,
        location: location,
        eventDate: eventDate,
        quantity: quantity,
        category: category,
        platform: platform,
        cardName: cardName,
        offerDetails: offerDetails,
        offerAmount: offerAmount,
        discountPercent: discountPercent,
      );
      _myOffers.insert(0, offer);
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

  // Accept offer (for clients)
  Future<bool> acceptOffer(String offerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await OfferService.acceptOffer(offerId);
      // Remove from offers list
      _offers.removeWhere((o) => o.id == offerId);
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

  // Reject offer (for clients - hide it)
  Future<void> rejectOffer(String offerId) async {
    try {
      await OfferService.rejectOffer(offerId);
      _offers.removeWhere((o) => o.id == offerId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Cancel offer (for buyers)
  Future<bool> cancelOffer(String offerId) async {
    try {
      await OfferService.cancelOffer(offerId);
      _myOffers.removeWhere((o) => o.id == offerId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
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
    double? discountPercent,
    double? discountedPrice,
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
        discountPercent: discountPercent,
        discountedPrice: discountedPrice,
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
