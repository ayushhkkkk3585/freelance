import '../models/user.dart';
import 'api_service.dart';

class UserService {
  // Get user by ID
  static Future<User> getUser(String userId) async {
    final response = await ApiService.get('/users/$userId');
    final data = response['data'] as Map<String, dynamic>;
    return User.fromJson(data['user']);
  }

  // Get all buyers
  static Future<List<User>> getBuyers({int page = 1, int limit = 20}) async {
    final response = await ApiService.get('/users/buyers?page=$page&limit=$limit');
    final data = response['data'] as Map<String, dynamic>;
    final List<dynamic> buyers = data['buyers'] ?? [];
    return buyers.map((json) => User.fromJson(json)).toList();
  }
}
