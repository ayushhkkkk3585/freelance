import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppsScreen extends StatelessWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Apps',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apps_outlined,
              size: 80,
              color: AppTheme.grey.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Apps Coming Soon',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Exciting features are on the way!',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.grey.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
