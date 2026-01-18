import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;
  final List<String> platforms;

  const Category({
    required this.name,
    required this.icon,
    required this.platforms,
  });

  static const List<Category> categories = [
    Category(
      name: 'Movies',
      icon: Icons.movie_outlined,
      platforms: ['BookMyShow', 'PVR', 'INOX', 'Cinepolis'],
    ),
    Category(
      name: 'Events',
      icon: Icons.event_outlined,
      platforms: ['BookMyShow', 'Insider', 'Eventbrite'],
    ),
    Category(
      name: 'Sports',
      icon: Icons.sports_soccer_outlined,
      platforms: ['BookMyShow', 'Paytm Insider'],
    ),
    Category(
      name: 'Live Events',
      icon: Icons.live_tv_outlined,
      platforms: ['BookMyShow', 'Insider'],
    ),
    Category(
      name: 'Music',
      icon: Icons.music_note_outlined,
      platforms: ['BookMyShow', 'Spotify', 'Gaana'],
    ),
    Category(
      name: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      platforms: ['Amazon', 'Flipkart', 'Myntra'],
    ),
    Category(
      name: 'Food & Beverages',
      icon: Icons.restaurant_outlined,
      platforms: ['Zomato', 'Swiggy', 'EazyDiner'],
    ),
    Category(
      name: 'Booking',
      icon: Icons.flight_outlined,
      platforms: ['MakeMyTrip', 'Goibibo', 'OYO'],
    ),
  ];

  static Category? getByName(String name) {
    try {
      return categories.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }
}
