import '../models/event_offer.dart';
import 'api_service.dart';

class OfferService {
  // Get all active offers (for clients to browse)
  static Future<List<EventOffer>> getAllOffers({
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    String endpoint = '/offers?page=$page&limit=$limit';
    if (category != null && category.isNotEmpty) {
      endpoint += '&category=$category';
    }
    final response = await ApiService.get(endpoint);
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> offers = data?['offers'] ?? [];
    return offers.map((json) => EventOffer.fromJson(json)).toList();
  }

  // Get my offers (for buyers)
  static Future<List<EventOffer>> getMyOffers({int page = 1, int limit = 20}) async {
    final response = await ApiService.get('/offers/my-offers?page=$page&limit=$limit');
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> offers = data?['offers'] ?? [];
    return offers.map((json) => EventOffer.fromJson(json)).toList();
  }

  // Create a new offer (buyer only)
  static Future<EventOffer> createOffer({
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
    final response = await ApiService.post('/offers', {
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
    });
    final data = response['data'] as Map<String, dynamic>;
    return EventOffer.fromJson(data['offer']);
  }

  // Accept an offer (client only)
  static Future<Map<String, dynamic>> acceptOffer(String offerId) async {
    final response = await ApiService.post('/offers/$offerId/accept', {});
    return response['data'] as Map<String, dynamic>;
  }

  // Reject/decline an offer (client only - just hides it for them)
  static Future<void> rejectOffer(String offerId) async {
    await ApiService.post('/offers/$offerId/reject', {});
  }

  // Cancel an offer (buyer only)
  static Future<void> cancelOffer(String offerId) async {
    await ApiService.delete('/offers/$offerId');
  }

  // Get offer details
  static Future<EventOffer> getOffer(String offerId) async {
    final response = await ApiService.get('/offers/$offerId');
    final data = response['data'] as Map<String, dynamic>;
    return EventOffer.fromJson(data['offer']);
  }
}
