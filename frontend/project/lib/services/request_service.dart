import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/event_request.dart';
import 'api_service.dart';

class RequestService {
  // Get Pending Requests (for buyers)
  static Future<List<EventRequest>> getPendingRequests({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    String endpoint = '/requests/pending?page=$page&limit=$limit';
    if (category != null && category != 'all') endpoint += '&category=$category';
    
    final response = await ApiService.get(endpoint);
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> requests = data?['requests'] ?? [];
    return requests.map((json) => EventRequest.fromJson(json)).toList();
  }

  // Get My Requests (for clients)
  static Future<List<EventRequest>> getMyRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    String endpoint = '/requests/my-requests?page=$page&limit=$limit';
    if (status != null) endpoint += '&status=$status';
    
    final response = await ApiService.get(endpoint);
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> requests = data?['requests'] ?? [];
    return requests.map((json) => EventRequest.fromJson(json)).toList();
  }

  // Get Buyer's Bookings
  static Future<List<EventRequest>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    String endpoint = '/requests/my-bookings?page=$page&limit=$limit';
    if (status != null) endpoint += '&status=$status';
    
    final response = await ApiService.get(endpoint);
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> requests = data?['requests'] ?? [];
    return requests.map((json) => EventRequest.fromJson(json)).toList();
  }

  // Get Request by ID
  static Future<EventRequest> getRequestById(String id) async {
    print('RequestService.getRequestById called with id: $id'); // Debug log
    final response = await ApiService.get('/requests/$id');
    print('RequestService.getRequestById response: $response'); // Debug log
    final data = response['data'] as Map<String, dynamic>;
    return EventRequest.fromJson(data['request']);
  }

  // Create Request (for clients)
  static Future<EventRequest> createRequest({
    required String eventName,
    required String location,
    required DateTime eventDate,
    required int quantity,
    required String cardName,
    required String offerDetails,
    required double originalPrice,      // What client pays (e.g., 1000)
    required double discountedPrice,    // What buyer pays using card (e.g., 700)
    String? eventUrl,
    required String category,
    required String platform,
  }) async {
    final response = await ApiService.post('/requests', {
      'eventName': eventName,
      'location': location,
      'eventDate': eventDate.toIso8601String(),
      'quantity': quantity,
      'cardName': cardName,
      'offerDetails': offerDetails,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      if (eventUrl != null) 'eventUrl': eventUrl,
      'category': category,
      'platform': platform,
    });
    final data = response['data'] as Map<String, dynamic>;
    return EventRequest.fromJson(data['request']);
  }

  // Accept Request (for buyers)
  static Future<EventRequest> acceptRequest(String requestId) async {
    final response = await ApiService.post('/requests/$requestId/accept', {});
    final data = response['data'] as Map<String, dynamic>;
    return EventRequest.fromJson(data['request']);
  }

  // Accept Offer from Chat (for clients) - accepts buyer's negotiated offer with discount
  // Uses the same discount logic as create request
  static Future<EventRequest> acceptOfferFromChat(
    String requestId, 
    double offerAmount, 
    {double discountPercent = 30}
  ) async {
    final response = await ApiService.post('/requests/$requestId/accept-offer', {
      'offerAmount': offerAmount,
      'discountPercent': discountPercent,
    });
    final data = response['data'] as Map<String, dynamic>;
    return EventRequest.fromJson(data['request']);
  }

  // Upload Screenshot and Complete (for buyers) - Mobile version
  static Future<EventRequest> completeRequest(
    String requestId,
    File screenshot,
  ) async {
    final response = await ApiService.uploadFile(
      '/requests/$requestId/complete',
      screenshot,
      'screenshot',
    );
    final data = response['data'] as Map<String, dynamic>;
    return EventRequest.fromJson(data['request']);
  }

  // Upload Screenshot and Complete (for buyers) - Web version
  static Future<EventRequest> completeRequestWeb(
    String requestId,
    Uint8List screenshotBytes,
    String filename,
  ) async {
    final response = await ApiService.uploadFileBytes(
      '/requests/$requestId/complete',
      screenshotBytes,
      'screenshot',
      filename,
    );
    final data = response['data'] as Map<String, dynamic>;
    return EventRequest.fromJson(data['request']);
  }

  // Cancel Request (for clients)
  static Future<EventRequest> cancelRequest(String requestId, {String? reason}) async {
    final response = await ApiService.post('/requests/$requestId/cancel', {
      if (reason != null) 'reason': reason,
    });
    final data = response['data'] as Map<String, dynamic>;
    return EventRequest.fromJson(data['request']);
  }

  // Get Stats
  static Future<Map<String, dynamic>> getStats() async {
    final response = await ApiService.get('/requests/stats');
    final data = response['data'] as Map<String, dynamic>;
    return data['stats'] ?? {};
  }
}
