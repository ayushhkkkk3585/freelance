import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_request.dart';

class RequestCard extends StatelessWidget {
  final EventRequest request;
  final VoidCallback? onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final bool showActions;
  final bool showTimer;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.onAccept,
    this.onReject,
    this.showActions = false,
    this.showTimer = false,
  });

  Color _getStatusColor() {
    switch (request.status) {
      case 'pending':
        return AppTheme.warning;
      case 'accepted':
        return AppTheme.info;
      case 'completed':
        return AppTheme.success;
      case 'rejected':
      case 'timeout':
        return AppTheme.error;
      default:
        return AppTheme.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(request.category),
                    color: AppTheme.primaryRed,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Event Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.eventName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: AppTheme.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.location,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Info Row
            Row(
              children: [
                _buildInfoChip(
                  Icons.calendar_today_outlined,
                  '${request.eventDate.day}/${request.eventDate.month}',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.confirmation_number_outlined,
                  '${request.quantity} tickets',
                ),
                const SizedBox(width: 12),
                _buildInfoChip(
                  Icons.credit_card_outlined,
                  request.cardName,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Amount and Platform
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        request.platform,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        request.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${request.buyerPayment.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                    Text(
                      'Profit: ₹${request.buyerProfit.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Timer (if showing)
            if (showTimer && request.isAccepted && request.remainingTime != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: AppTheme.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Time remaining: ${request.remainingTime!.inMinutes}:${(request.remainingTime!.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: AppTheme.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons (for buyers)
            if (showActions && request.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onReject,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.grey,
                        side: BorderSide(color: AppTheme.grey.withOpacity(0.5)),
                      ),
                      child: const Text('Ignore'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onAccept,
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.darkGrey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Movies':
        return Icons.movie_outlined;
      case 'Events':
        return Icons.event_outlined;
      case 'Sports':
        return Icons.sports_soccer_outlined;
      case 'Live Events':
        return Icons.live_tv_outlined;
      case 'Music':
        return Icons.music_note_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Food & Beverages':
        return Icons.restaurant_outlined;
      case 'Booking':
        return Icons.flight_outlined;
      default:
        return Icons.category_outlined;
    }
  }
}
