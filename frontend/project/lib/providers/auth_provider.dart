import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;
  bool get isClient => _user?.role == 'client';
  bool get isBuyer => _user?.role == 'buyer';

  // Initialize
  Future<bool> initialize() async {
    try {
      final isLoggedIn = await AuthService.isLoggedIn();
      if (isLoggedIn) {
        _user = await AuthService.getCurrentUser();
        _isAuthenticated = _user != null;
      }
      return _isAuthenticated;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
        role: role,
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && data['user'] != null) {
        _user = User.fromJson(data['user']);
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String role,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await AuthService.register(
        name: name,
        email: email,
        password: password,
        role: role,
        phone: phone,
      );
      final data = response['data'] as Map<String, dynamic>?;
      if (data != null && data['user'] != null) {
        _user = User.fromJson(data['user']);
        _isAuthenticated = true;
      }
      _isLoading = false;
      notifyListeners();
      return _isAuthenticated;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    await AuthService.logout();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  // Update Profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? bio,
    List<String>? cardsOwned,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await AuthService.updateProfile(
        name: name,
        phone: phone,
        bio: bio,
        cardsOwned: cardsOwned,
      );
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

  // Refresh User Data
  Future<void> refreshUser() async {
    try {
      _user = await AuthService.refreshUserData();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  // Clear Error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
