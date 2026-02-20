import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        title: const Text(
          'Help & Support',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
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
                      Icons.support_agent,
                      size: 60,
                      color: AppTheme.primaryRed,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Need Help?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our support team is here to assist you',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Contact Section Title
            const Text(
              'Contact Us',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Contact Cards
            _buildContactCard(
              context,
              name: 'Keval',
              phone: '8591810869',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              name: 'Dhruv Shah',
              phone: '9820653808',
              icon: Icons.person,
            ),
            const SizedBox(height: 12),
            _buildContactCard(
              context,
              name: 'Jay',
              phone: '7715909911',
              icon: Icons.person,
            ),
            const SizedBox(height: 32),

            // FAQ Section
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
                  Row(
                    children: [
                      Icon(
                        Icons.help_outline,
                        color: AppTheme.primaryRed,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFAQItem(
                    question: 'How do I create a ticket request?',
                    answer: 'Go to the home screen and tap on the category you want. Fill in the event details and submit your request.',
                  ),
                  _buildFAQItem(
                    question: 'How do wallet points work?',
                    answer: 'Wallet points are used for all transactions within the app. You can add points to your wallet and use them to pay for tickets.',
                  ),
                  _buildFAQItem(
                    question: 'What happens if there is a dispute?',
                    answer: 'Our support team will review the dispute and work with both parties to resolve it fairly.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Support Hours
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryRed, AppTheme.primaryRedDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
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
                      Icons.access_time,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Support Hours',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Available 24/7 for your assistance',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
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

  Widget _buildContactCard(
    BuildContext context, {
    required String name,
    required String phone,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.grey,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Call button
              IconButton(
                onPressed: () => _makePhoneCall(phone),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.call,
                    color: AppTheme.success,
                    size: 20,
                  ),
                ),
              ),
              // WhatsApp button
              IconButton(
                onPressed: () => _openWhatsApp(phone),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat,
                    color: Color(0xFF25D366),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            answer,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    }
  }

  Future<void> _openWhatsApp(String phone) async {
    final Uri whatsappUri = Uri.parse('https://wa.me/91$phone');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }
  }
}
