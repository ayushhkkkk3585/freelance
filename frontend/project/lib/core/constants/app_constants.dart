import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class AppConstants {
  // API Configuration
  // For Android emulator use 10.0.2.2, for iOS simulator use localhost
  // For physical devices, use your machine's actual IP address
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (Platform.isAndroid) {
      // 10.0.2.2 is the special IP for Android emulator to access host machine
      return 'http://10.0.2.2:3000/api';
    }
    // iOS simulator and other platforms
    return 'http://localhost:3000/api';
  }
  
  // Server base URL (without /api) for static files
  static String get serverUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }
  
  // Helper to get full image URL from relative path
  static String getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) {
      return '';
    }
    // If it's already a full URL, return as-is
    if (relativePath.startsWith('http://') || relativePath.startsWith('https://')) {
      return relativePath;
    }
    // Prepend server URL
    return '$serverUrl$relativePath';
  }
  
  // App Info
  static const String appName = 'BookMyTicket';
  static const String appVersion = '1.0.0';
  
  // Point System
  static const int initialPoints = 1000;
  static const double pointToRupeeRatio = 1.0; // 1 point = ₹1
  
  // Timer Configuration
  static const int bookingTimerMinutes = 5;
  
  // Categories
  static const List<String> categories = [
    'Movies',
    'Events',
    'Sports',
    'Live Events',
    'Music',
    'Shopping',
    'Food & Beverages',
    'Booking',
  ];
  
  // Platform Icons by Category
  static const Map<String, List<String>> platformsByCategory = {
    'Movies': ['BookMyShow', 'PVR', 'INOX', 'Cinepolis'],
    'Events': ['BookMyShow', 'Insider', 'Eventbrite'],
    'Sports': ['BookMyShow', 'Paytm Insider'],
    'Live Events': ['BookMyShow', 'Insider'],
    'Music': ['BookMyShow', 'Spotify', 'Gaana'],
    'Shopping': ['Amazon', 'Flipkart', 'Myntra'],
    'Food & Beverages': ['Zomato', 'Swiggy', 'EazyDiner'],
    'Booking': ['MakeMyTrip', 'Goibibo', 'OYO'],
  };
  
  // Request Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusCompleted = 'completed';
  static const String statusRejected = 'rejected';
  static const String statusTimeout = 'timeout';
  static const String statusRefunded = 'refunded';
  
  // User Roles
  static const String roleClient = 'client';
  static const String roleBuyer = 'buyer';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String roleKey = 'user_role';
}
