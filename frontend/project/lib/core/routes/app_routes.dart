import 'package:flutter/material.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/client/client_dashboard.dart';
import '../../screens/client/create_request_screen.dart';
import '../../screens/buyer/buyer_dashboard.dart';
import '../../screens/buyer/request_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/chat/chat_screen.dart';
import '../../screens/chat/chats_list_screen.dart';
import '../../screens/apps/apps_screen.dart';
import '../../screens/notifications/notifications_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String clientDashboard = '/client-dashboard';
  static const String createRequest = '/create-request';
  static const String buyerDashboard = '/buyer-dashboard';
  static const String requestDetail = '/request-detail';
  static const String profile = '/profile';
  static const String chat = '/chat';
  static const String chatsList = '/chats-list';
  static const String apps = '/apps';
  static const String notifications = '/notifications';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());
      case login:
        return _buildRoute(const LoginScreen());
      case register:
        return _buildRoute(const RegisterScreen());
      case home:
        return _buildRoute(const HomeScreen());
      case clientDashboard:
        return _buildRoute(const ClientDashboard());
      case createRequest:
        return _buildRoute(const CreateRequestScreen());
      case buyerDashboard:
        return _buildRoute(const BuyerDashboard());
      case requestDetail:
        final requestId = settings.arguments as String;
        return _buildRoute(RequestDetailScreen(requestId: requestId));
      case profile:
        return _buildRoute(const ProfileScreen());
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return _buildRoute(ChatScreen(
          requestId: args['requestId'],
          otherUserId: args['otherUserId'],
        ));
      case notifications:
        return _buildRoute(const NotificationsScreen());
      case chatsList:
        return _buildRoute(const ChatsListScreen());
      case apps:
        return _buildRoute(const AppsScreen());
      default:
        return _buildRoute(const SplashScreen());
    }
  }

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(position: offsetAnimation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
