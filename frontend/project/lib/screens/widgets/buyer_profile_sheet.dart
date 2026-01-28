import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class BuyerProfileSheet extends StatefulWidget {
  final String buyerId;
  final VoidCallback? onAcceptOffer;
  final double? offerAmount;
  final String? eventDetails;

  const BuyerProfileSheet({
    super.key,
    required this.buyerId,
    this.onAcceptOffer,
    this.offerAmount,
    this.eventDetails,
  });

  @override
  State<BuyerProfileSheet> createState() => _BuyerProfileSheetState();
}

class _BuyerProfileSheetState extends State<BuyerProfileSheet> {
  User? _buyer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBuyerProfile();
  }

  Future<void> _loadBuyerProfile() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      final buyer = await UserService.getUser(widget.buyerId);
      setState(() {
        _buyer = buyer;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          const Text(
            'Buyer Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Content
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Failed to load profile',
                    style: TextStyle(color: AppTheme.grey),
                  ),
                ],
              ),
            )
          else if (_buyer != null)
            _buildProfile(),
          
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Avatar and basic info
          Row(
            children: [
              CircleAvatar(
                radius: 35,
                backgroundColor: AppTheme.primaryRed.withOpacity(0.1),
                backgroundImage: _buyer!.photoUrl != null
                    ? NetworkImage(_buyer!.photoUrl!)
                    : null,
                child: _buyer!.photoUrl == null
                    ? Text(
                        _buyer!.name.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryRed,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _buyer!.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                size: 14,
                                color: AppTheme.success,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Buyer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Stats row
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.offWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    value: _buyer!.rating.toStringAsFixed(1),
                    label: 'Rating',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.grey.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.shopping_bag_outlined,
                    iconColor: AppTheme.primaryRed,
                    value: '${_buyer!.totalBookings}',
                    label: 'Bookings',
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppTheme.grey.withOpacity(0.2),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.handshake_outlined,
                    iconColor: AppTheme.success,
                    value: '${_buyer!.dealCount}',
                    label: 'Deals',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Bio if available
          if (_buyer!.bio != null && _buyer!.bio!.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.offWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _buyer!.bio!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Offer details if available
          if (widget.offerAmount != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.success.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.local_offer,
                        color: AppTheme.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Current Offer',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${widget.offerAmount!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.eventDetails != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.eventDetails!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          
          // Accept offer button
          if (widget.onAcceptOffer != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.onAcceptOffer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Accept This Offer',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.grey,
          ),
        ),
      ],
    );
  }
}

// Helper function to show the buyer profile sheet
void showBuyerProfileSheet(
  BuildContext context, {
  required String buyerId,
  VoidCallback? onAcceptOffer,
  double? offerAmount,
  String? eventDetails,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => BuyerProfileSheet(
      buyerId: buyerId,
      onAcceptOffer: onAcceptOffer,
      offerAmount: offerAmount,
      eventDetails: eventDetails,
    ),
  );
}
