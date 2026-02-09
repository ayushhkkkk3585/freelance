import 'api_service.dart';

class EscrowService {
  /// Client confirms ticket is valid - releases payment to buyer
  static Future<Map<String, dynamic>> confirmTicket(String requestId) async {
    final response = await ApiService.post('/escrow/$requestId/confirm', {});
    return response;
  }

  /// Client raises a dispute
  static Future<Map<String, dynamic>> raiseDispute(
    String requestId,
    String reason,
  ) async {
    final response = await ApiService.post('/escrow/$requestId/dispute', {
      'reason': reason,
    });
    return response;
  }

  /// Buyer accepts refund during dispute
  static Future<Map<String, dynamic>> acceptRefund(String requestId) async {
    final response = await ApiService.post('/escrow/$requestId/accept-refund', {});
    return response;
  }

  /// Buyer rejects dispute (claims dispute is false)
  static Future<Map<String, dynamic>> rejectDispute(String requestId) async {
    final response = await ApiService.post('/escrow/$requestId/reject-dispute', {});
    return response;
  }

  /// Client accepts buyer's response during dispute
  static Future<Map<String, dynamic>> acceptBuyerResponse(String requestId) async {
    final response = await ApiService.post('/escrow/$requestId/accept-buyer-response', {});
    return response;
  }

  /// Get escrow status for a request
  static Future<Map<String, dynamic>> getEscrowStatus(String requestId) async {
    final response = await ApiService.get('/escrow/$requestId/status');
    return response['data'] as Map<String, dynamic>;
  }
}
