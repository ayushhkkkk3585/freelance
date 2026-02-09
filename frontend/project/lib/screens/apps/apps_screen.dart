import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'category_detail_screen.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  static const Map<String, Map<String, dynamic>> categoryData = {
    'Movies': {'image': 'images/movie.jpg', 'color': Colors.blue},
    'Events': {'image': 'images/event.jpg', 'color': Colors.purple},
    'Sports': {'image': 'images/sports.jpg', 'color': Colors.green},
    'Live Events': {'image': 'images/live-events.jpg', 'color': Colors.red},
    'Music': {'image': 'images/music.png', 'color': Colors.pink},
    'Shopping': {'image': 'images/shopping.jpg', 'color': Colors.teal},
    'Food & Beverages': {'image': 'images/food.jpg', 'color': Colors.orange},
    'Booking': {'image': 'images/booking.jpg', 'color': Colors.indigo},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Categories',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories headline
            // const Text(
            //   'Categories',
            //   style: TextStyle(
            //     fontSize: 24,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.red,
            //   ),
            // ),
            const SizedBox(height: 16),
            
            // Background image card
            Container(
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('images/back.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: const Center(
                  // child: Text(
                    
                  //   style: TextStyle(
                  //     fontSize: 18,
                  //     fontWeight: FontWeight.bold,
                  //     color: Colors.white,
                  //   ),
                  // ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Category buttons
            Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildCategoryButton(context, '🎬', 'Movies', Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryButton(context, '📅', 'Events', Colors.purple)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCategoryButton(context, '⚽', 'Sports', Colors.green)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryButton(context, '📺', 'Live Events', Colors.red)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCategoryButton(context, '🎵', 'Music', Colors.pink)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryButton(context, '🛍️', 'Shopping', Colors.teal)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildCategoryButton(context, '🍕', 'Food & Beverages', Colors.orange)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildCategoryButton(context, '✈️', 'Booking', Colors.indigo)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton(BuildContext context, String emoji, String title, Color accentColor) {
    return GestureDetector(
      onTap: () {
        final data = categoryData[title];
        if (data != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryDetailScreen(
                categoryName: title,
                imagePath: data['image'] as String,
                accentColor: data['color'] as Color,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: accentColor.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: accentColor.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
