import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/event_request.dart';
import '../services/request_service.dart';

class RequestProvider with ChangeNotifier {
  List<EventRequest> _requests = [];
  List<EventRequest> _myRequests = [];
  List<EventRequest> _acceptedRequests = [];
  EventRequest? _currentRequest;
  bool _isLoading = false;
  String? _error;
  String? _selectedCategory;

  List<EventRequest> get requests => _selectedCategory != null
      ? _requests.where((r) => r.category == _selectedCategory).toList()
      : _requests;
  List<EventRequest> get myRequests => _myRequests;
  List<EventRequest> get acceptedRequests => _acceptedRequests;
  EventRequest? get currentRequest => _currentRequest;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;

  // Set Category Filter
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  // Get Pending Requests (for buyers)
  Future<void> fetchPendingRequests({
    String? category,
    bool refresh = false,
  }) async {
    if (refresh) _requests = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _requests = await RequestService.getPendingRequests(
        category: category,
      );
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get My Requests (for clients)
  Future<void> fetchMyRequests({String? status, bool refresh = false}) async {
    if (refresh) _myRequests = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _myRequests = await RequestService.getMyRequests(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get My Bookings (for buyers)
  Future<void> fetchMyBookings({String? status, bool refresh = false}) async {
    if (refresh) _acceptedRequests = [];
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _acceptedRequests = await RequestService.getMyBookings(status: status);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get Request by ID
  Future<void> fetchRequestById(String id) async {
    _isLoading = true;
    _error = null;
    _currentRequest = null; // Clear previous request
    notifyListeners();

    print('Fetching request by ID: $id'); // Debug log

    try {
      _currentRequest = await RequestService.getRequestById(id);
      print('Request fetched successfully: ${_currentRequest?.id}'); // Debug log
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error fetching request: $e'); // Debug log
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create Request
  Future<EventRequest?> createRequest({
    required String eventName,
    required String location,
    required DateTime eventDate,
    required int quantity,
    required String cardName,
    required String offerDetails,
    required double finalAmount,
    String? eventUrl,
    required String category,
    required String platform,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = await RequestService.createRequest(
        eventName: eventName,
        location: location,
        eventDate: eventDate,
        quantity: quantity,
        cardName: cardName,
        offerDetails: offerDetails,
        finalAmount: finalAmount,
        eventUrl: eventUrl,
        category: category,
        platform: platform,
      );
      _myRequests.insert(0, request);
      _isLoading = false;
      notifyListeners();
      return request;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Accept Request
  Future<bool> acceptRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedRequest = await RequestService.acceptRequest(requestId);
      _updateRequestInLists(updatedRequest);
      _acceptedRequests.insert(0, updatedRequest);
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

  // Complete Request (with screenshot upload)
  Future<bool> completeRequest(String requestId, File screenshot) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('Completing request: $requestId with screenshot: ${screenshot.path}'); // Debug log

    try {
      final updatedRequest = await RequestService.completeRequest(
        requestId,
        screenshot,
      );
      print('Request completed successfully'); // Debug log
      _updateRequestInLists(updatedRequest);
      _currentRequest = updatedRequest;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Complete request error: $e'); // Debug log
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Complete Request for Web (with screenshot bytes)
  Future<bool> completeRequestWeb(String requestId, Uint8List screenshotBytes, String filename) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    print('Completing request (web): $requestId with screenshot bytes: ${screenshotBytes.length}'); // Debug log

    try {
      final updatedRequest = await RequestService.completeRequestWeb(
        requestId,
        screenshotBytes,
        filename,
      );
      print('Request completed successfully'); // Debug log
      _updateRequestInLists(updatedRequest);
      _currentRequest = updatedRequest;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('Complete request error: $e'); // Debug log
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Cancel Request
  Future<bool> cancelRequest(String requestId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedRequest = await RequestService.cancelRequest(requestId);
      _updateRequestInLists(updatedRequest);
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

  // Update request in all lists
  void _updateRequestInLists(EventRequest updatedRequest) {
    final index = _requests.indexWhere((r) => r.id == updatedRequest.id);
    if (index != -1) {
      _requests[index] = updatedRequest;
    }

    final myIndex = _myRequests.indexWhere((r) => r.id == updatedRequest.id);
    if (myIndex != -1) {
      _myRequests[myIndex] = updatedRequest;
    }

    final acceptedIndex = _acceptedRequests.indexWhere((r) => r.id == updatedRequest.id);
    if (acceptedIndex != -1) {
      _acceptedRequests[acceptedIndex] = updatedRequest;
    }

    if (_currentRequest?.id == updatedRequest.id) {
      _currentRequest = updatedRequest;
    }
  }

  // Clear Error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear Current Request
  void clearCurrentRequest() {
    _currentRequest = null;
    notifyListeners();
  }
}
