import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.confirmation_number,
                      size: 60,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'BookMy Ticket',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // About Content
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What is BookMy Ticket?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BookMy Ticket is a point-based ticket booking assistance platform that connects Clients who want discounted tickets with Buyers who own eligible bank cards and offers.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // How it works
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How It Works',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'The app enables clients to request tickets for movies, events, sports, concerts, shopping, food, and more. Buyers can accept these requests, purchase tickets and earn profit through the platform\'s point-based transaction system.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Transactions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Digital Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'All transactions happen digitally through wallet points inside the app.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Categories Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildCategoryChip(Icons.movie, 'Movies'),
                      _buildCategoryChip(Icons.event, 'Events'),
                      _buildCategoryChip(Icons.sports_soccer, 'Sports'),
                      _buildCategoryChip(Icons.music_note, 'Concerts'),
                      _buildCategoryChip(Icons.shopping_bag, 'Shopping'),
                      _buildCategoryChip(Icons.restaurant, 'Food'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Theme Info
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.primaryRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.palette,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Designed with a modern Red & White UI for a clean and premium appearance.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryRed),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.primaryRed,
            ),
          ),
        ],
      ),
    );
  }
}
