import '../models/notification.dart';
import 'api_service.dart';

class NotificationService {
  // Get Notifications
  static Future<List<AppNotification>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await ApiService.get('/notifications?page=$page&limit=$limit');
    final data = response['data'] as Map<String, dynamic>?;
    final List<dynamic> notifications = data?['notifications'] ?? [];
    return notifications.map((json) => AppNotification.fromJson(json)).toList();
  }

  // Get Unread Count
  static Future<int> getUnreadCount() async {
    final response = await ApiService.get('/notifications?limit=1');
    final data = response['data'] as Map<String, dynamic>?;
    return data?['unreadCount'] ?? 0;
  }

  // Mark as Read
  static Future<void> markAsRead(String notificationId) async {
    await ApiService.put('/notifications/$notificationId/read', {});
  }

  // Mark All as Read
  static Future<void> markAllAsRead() async {
    await ApiService.put('/notifications/read-all', {});
  }

  // Delete Notification
  static Future<void> deleteNotification(String notificationId) async {
    await ApiService.delete('/notifications/$notificationId');
  }
}
