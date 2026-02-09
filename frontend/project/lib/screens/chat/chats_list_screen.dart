import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import 'offers_feed_screen.dart';
import 'create_offer_screen.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    if (authProvider.isBuyer) {
      await chatProvider.fetchMyOffers();
    } else {
      await chatProvider.fetchOffers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isBuyer = authProvider.isBuyer;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryRed,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          isBuyer ? 'My Offers' : 'Event Offers',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          if (isBuyer)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateOfferScreen(),
                  ),
                ).then((_) => _loadData());
              },
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create New Offer',
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primaryRed,
        onRefresh: _loadData,
        child: const OffersFeedScreen(),
      ),
      floatingActionButton: isBuyer
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateOfferScreen(),
                  ),
                ).then((_) => _loadData());
              },
              backgroundColor: AppTheme.primaryRed,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Post Offer',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }
}
