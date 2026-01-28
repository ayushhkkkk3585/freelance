import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_offer.dart';
import '../../models/category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../widgets/buyer_profile_sheet.dart';

class OffersFeedScreen extends StatefulWidget {
  const OffersFeedScreen({super.key});

  @override
  State<OffersFeedScreen> createState() => _OffersFeedScreenState();
}

class _OffersFeedScreenState extends State<OffersFeedScreen> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isBuyer = authProvider.isBuyer;

    return Column(
      children: [
        // Category Filter
        _buildCategoryFilter(),
        
        // Offers List
        Expanded(
          child: Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final offers = isBuyer ? chatProvider.myOffers : chatProvider.offers;
              
              if (chatProvider.isLoading && offers.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryRed),
                );
              }

              if (offers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isBuyer ? Icons.local_offer_outlined : Icons.search_off,
                        size: 80,
                        color: AppTheme.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isBuyer ? 'No Offers Posted Yet' : 'No Offers Available',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isBuyer
                            ? 'Tap the + button to post your first offer'
                            : 'Check back later for new deals from buyers',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.grey.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: offers.length,
                itemBuilder: (context, index) {
                  return _buildOfferCard(offers[index], isBuyer);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: Category.categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip('All', null);
          }
          final category = Category.categories[index - 1];
          return _buildCategoryChip(category.name, category.name);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? value : null;
          });
          // Refresh offers with filter
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          chatProvider.fetchOffers(category: _selectedCategory);
        },
        selectedColor: AppTheme.primaryRed.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryRed,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryRed : AppTheme.grey,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildOfferCard(EventOffer offer, bool isBuyer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buyer Info Header
          InkWell(
            onTap: isBuyer ? null : () => _showBuyerProfile(offer),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                    backgroundImage: offer.buyerPhotoUrl != null
                        ? NetworkImage(offer.buyerPhotoUrl!)
                        : null,
                    child: offer.buyerPhotoUrl == null
                        ? Text(
                            offer.buyerName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryRed,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              offer.buyerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified,
                                    size: 12,
                                    color: AppTheme.success,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.success,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              offer.buyerRating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${offer.buyerBookingsCount} bookings',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${offer.buyerDealsCount} deals',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (!isBuyer)
                    Icon(
                      Icons.chevron_right,
                      color: AppTheme.grey,
                    ),
                ],
              ),
            ),
          ),
          
          const Divider(height: 1),
          
          // Event Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Name
                Text(
                  offer.eventName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Category Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    offer.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Location & Date
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: AppTheme.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        offer.location,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 16, color: AppTheme.grey),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(offer.eventDate),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.grey,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.confirmation_number_outlined, size: 16, color: AppTheme.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${offer.quantity} ticket${offer.quantity > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
                
                // Offer Details
                if (offer.offerDetails != null && offer.offerDetails!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    offer.offerDetails!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.darkGrey,
                    ),
                  ),
                ],
                
                // Card/Platform info
                if (offer.cardName != null && offer.cardName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.credit_card, size: 16, color: AppTheme.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${offer.cardName} • ${offer.platform}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Price & Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer Price',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.grey,
                      ),
                    ),
                    Text(
                      '₹${offer.offerAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                
                // Actions
                if (isBuyer) ...[
                  // Cancel button for buyers
                  OutlinedButton(
                    onPressed: () => _cancelOffer(offer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                    ),
                    child: const Text('Cancel'),
                  ),
                ] else ...[
                  // Reject button for clients
                  OutlinedButton(
                    onPressed: () => _rejectOffer(offer),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.grey,
                    ),
                    child: const Text('Skip'),
                  ),
                  const SizedBox(width: 8),
                  // Accept button for clients
                  ElevatedButton(
                    onPressed: () => _acceptOffer(offer),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ],
              ],
            ),
          ),
          
          // Time posted
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Text(
              'Posted ${_formatTimeAgo(offer.createdAt)}',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBuyerProfile(EventOffer offer) {
    showBuyerProfileSheet(
      context,
      buyerId: offer.buyerId,
      offerAmount: offer.offerAmount,
      eventDetails: offer.eventName,
      onAcceptOffer: () {
        Navigator.pop(context);
        _acceptOffer(offer);
      },
    );
  }

  Future<void> _acceptOffer(EventOffer offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event: ${offer.eventName}'),
            Text('Price: ₹${offer.offerAmount.toStringAsFixed(0)}'),
            const SizedBox(height: 12),
            const Text('Are you sure you want to accept this offer?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
            ),
            child: const Text(
              'Accept',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final success = await chatProvider.acceptOffer(offer.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Offer accepted! The buyer will contact you soon.'
                  : 'Failed to accept offer: ${chatProvider.error}',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _rejectOffer(EventOffer offer) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.rejectOffer(offer.id);
  }

  Future<void> _cancelOffer(EventOffer offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Offer'),
        content: const Text('Are you sure you want to cancel this offer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text(
              'Yes, Cancel',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final success = await chatProvider.cancelOffer(offer.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Offer cancelled' : 'Failed to cancel offer',
            ),
            backgroundColor: success ? AppTheme.success : AppTheme.error,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }
}
