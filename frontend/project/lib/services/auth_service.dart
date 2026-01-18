import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user.dart';
import 'api_service.dart';

class AuthService {
  // Login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await ApiService.post('/auth/login', {
      'email': email,
      'password': password,
      'role': role,
    });
    
    final data = response['data'] as Map<String, dynamic>?;
    if (data != null && data['token'] != null) {
      await _saveAuthData(data['token'], data['user']);
    }
    
    return response;
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    final response = await ApiService.post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      if (phone != null) 'phone': phone,
    });
    
    final data = response['data'] as Map<String, dynamic>?;
    if (data != null && data['token'] != null) {
      await _saveAuthData(data['token'], data['user']);
    }
    
    return response;
  }

  // Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userKey);
    await prefs.remove(AppConstants.roleKey);
    ApiService.clearToken();
  }

  // Get Current User
  static Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(AppConstants.userKey);
    
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }

  // Check if Logged In
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.tokenKey);
    
    if (token != null) {
      ApiService.setToken(token);
      return true;
    }
    return false;
  }

  // Get Stored Role
  static Future<String?> getStoredRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.roleKey);
  }

  // Update Profile
  static Future<User> updateProfile({
    String? name,
    String? phone,
    String? bio,
    List<String>? cardsOwned,
  }) async {
    final response = await ApiService.put('/auth/profile', {
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (bio != null) 'bio': bio,
      if (cardsOwned != null) 'cardsOwned': cardsOwned,
    });
    
    final data = response['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user']);
    await _saveUser(user);
    return user;
  }

  // Refresh User Data
  static Future<User> refreshUserData() async {
    final response = await ApiService.get('/auth/profile');
    final data = response['data'] as Map<String, dynamic>;
    final user = User.fromJson(data['user']);
    await _saveUser(user);
    return user;
  }

  // Save Auth Data
  static Future<void> _saveAuthData(String token, Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userKey, jsonEncode(userData));
    await prefs.setString(AppConstants.roleKey, userData['role']);
    ApiService.setToken(token);
  }

  // Save User
  static Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }
}
