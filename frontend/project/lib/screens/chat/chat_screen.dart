import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/request_provider.dart';
import '../widgets/buyer_profile_sheet.dart';

class ChatScreen extends StatefulWidget {
  final String requestId;
  final String otherUserId;

  const ChatScreen({
    super.key,
    required this.requestId,
    required this.otherUserId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isOffer = false;
  final _offerAmountController = TextEditingController();
  final _discountPercentController = TextEditingController(text: '30');
  double _discountedPrice = 0;
  double? _latestOfferAmount;
  double? _latestDiscountPercent;
  String? _latestOfferContent;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _offerAmountController.dispose();
    _discountPercentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateDiscountedPrice() {
    final offerText = _offerAmountController.text;
    final discountText = _discountPercentController.text;
    
    if (offerText.isNotEmpty && discountText.isNotEmpty) {
      final offerAmount = double.tryParse(offerText);
      final discountPercent = double.tryParse(discountText);
      
      if (offerAmount != null && discountPercent != null && discountPercent >= 0 && discountPercent <= 100) {
        setState(() {
          _discountedPrice = (offerAmount * (100 - discountPercent) / 100);
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    await provider.fetchMessages(widget.requestId);
    _updateLatestOffer();
    _scrollToBottom();
  }

  void _updateLatestOffer() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    // Find the latest offer message from buyer
    for (int i = chatProvider.messages.length - 1; i >= 0; i--) {
      final msg = chatProvider.messages[i];
      if (msg.isOffer && msg.offerAmount != null) {
        setState(() {
          _latestOfferAmount = msg.offerAmount;
          _latestDiscountPercent = msg.discountPercent ?? 30;
          _latestOfferContent = msg.content;
        });
        break;
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Only buyers can send messages
    if (!authProvider.isBuyer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only buyers can send messages'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    double? offerAmount;
    double? discountPercent;
    double? discountedPrice;
    
    if (_isOffer && _offerAmountController.text.isNotEmpty) {
      offerAmount = double.tryParse(_offerAmountController.text);
      discountPercent = double.tryParse(_discountPercentController.text) ?? 30;
      if (offerAmount != null) {
        discountedPrice = (offerAmount * (100 - discountPercent) / 100);
      }
    }

    final success = await chatProvider.sendMessage(
      requestId: widget.requestId,
      content: content,
      isOffer: _isOffer,
      offerAmount: offerAmount,
      discountPercent: discountPercent,
      discountedPrice: discountedPrice,
    );

    if (success) {
      _messageController.clear();
      _offerAmountController.clear();
      _discountPercentController.text = '30';
      setState(() {
        _isOffer = false;
        _discountedPrice = 0;
        if (offerAmount != null) {
          _latestOfferAmount = offerAmount;
          _latestDiscountPercent = discountPercent;
          _latestOfferContent = content;
        }
      });
      _scrollToBottom();
    }
  }

  void _showBuyerProfile() {
    showBuyerProfileSheet(
      context,
      buyerId: widget.otherUserId,
      offerAmount: _latestOfferAmount,
      eventDetails: _latestOfferContent,
      onAcceptOffer: _latestOfferAmount != null ? _acceptOffer : null,
    );
  }

  Future<void> _acceptOffer() async {
    Navigator.pop(context); // Close the bottom sheet
    
    final offerAmount = _latestOfferAmount;
    if (offerAmount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No offer amount available'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }
    
    // Show accept offer dialog with discount settings (same logic as create request)
    final result = await _showAcceptOfferDialog(offerAmount);
    
    if (result != null) {
      try {
        final requestProvider = Provider.of<RequestProvider>(context, listen: false);
        // Use acceptOfferFromChat to properly apply the discount with the negotiated offer amount
        final success = await requestProvider.acceptOfferFromChat(
          widget.requestId, 
          offerAmount,
          discountPercent: result['discountPercent'],
        );
        
        if (mounted) {
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Offer accepted successfully! Timer started.'),
                backgroundColor: AppTheme.success,
              ),
            );
            Navigator.pop(context); // Go back after accepting
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to accept offer: ${requestProvider.error}'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept offer: $e'),
              backgroundColor: AppTheme.error,
            ),
          );
        }
      }
    }
  }

  /// Shows a dialog to accept offer with discount settings (same logic as create request)
  /// Uses the discount percent from the buyer's offer if available
  Future<Map<String, dynamic>?> _showAcceptOfferDialog(double offerAmount) async {
    // Use the discount percent from the buyer's offer, or default to 30%
    final initialDiscountPercent = _latestDiscountPercent ?? 30;
    final discountController = TextEditingController(text: initialDiscountPercent.toStringAsFixed(0));
    double discountPercent = initialDiscountPercent;
    double discountedPrice = (offerAmount * (100 - discountPercent) / 100);
    double clientRefund = (offerAmount * 0.2); // 20% refund
    double netCost = offerAmount - clientRefund;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          void updateCalculations() {
            final discount = double.tryParse(discountController.text) ?? 30;
            if (discount >= 0 && discount <= 100) {
              discountPercent = discount;
              discountedPrice = (offerAmount * (100 - discountPercent) / 100);
              clientRefund = (offerAmount * 0.2); // 20% refund (fixed)
              netCost = offerAmount - clientRefund;
              setDialogState(() {});
            }
          }

          return AlertDialog(
            title: const Text('Accept Offer'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offer Amount Display
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.local_offer, color: AppTheme.primaryRed),
                        const SizedBox(width: 8),
                        Text(
                          'Offer Amount: ₹${offerAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Discount Percent Input
                  const Text(
                    'Discount Percentage',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'The discount the buyer gets using their card',
                    style: TextStyle(fontSize: 12, color: AppTheme.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: discountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter discount %',
                      suffixText: '%',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => updateCalculations(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Price Breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Price Breakdown',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _buildPriceRow('You Pay', '₹${offerAmount.toStringAsFixed(0)}'),
                        _buildPriceRow('Buyer Pays (with card)', '₹${discountedPrice.toStringAsFixed(0)}'),
                        _buildPriceRow('Your Refund (20%)', '₹${clientRefund.toStringAsFixed(0)}', isGreen: true),
                        const Divider(),
                        _buildPriceRow('Your Net Cost', '₹${netCost.toStringAsFixed(0)}', isBold: true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'discountPercent': discountPercent,
                }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                ),
                child: const Text(
                  'Accept Offer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isGreen = false, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isGreen ? AppTheme.success : null,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? '';
    final isClient = authProvider.isClient;

    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Chat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Show buyer profile button for clients
          if (isClient)
            IconButton(
              onPressed: _showBuyerProfile,
              icon: const Icon(Icons.person_outline),
              tooltip: 'View Buyer Profile',
            ),
        ],
      ),
      body: Column(
        children: [
          // Client info banner showing buyer can send offers
          if (isClient)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppTheme.primaryRed.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: AppTheme.primaryRed,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Only buyers can send messages. Tap the profile icon to view buyer details and accept offers.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                if (chatProvider.isLoading && chatProvider.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryRed),
                  );
                }

                if (chatProvider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppTheme.grey.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            color: AppTheme.grey,
                            fontSize: 16,
                          ),
                        ),
                        if (authProvider.isBuyer)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Start the conversation by sending an offer',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final message = chatProvider.messages[index];
                    final isMe = message.senderId == currentUserId;

                    return _buildMessageBubble(message, isMe, isClient);
                  },
                );
              },
            ),
          ),

          // Accept offer section for clients
          if (isClient && _latestOfferAmount != null) _buildClientOfferSection(),
          
          // Input Section (only for buyers)
          if (authProvider.isBuyer) _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildClientOfferSection() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Latest offer info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.success.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_offer,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Latest Offer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                      Text(
                        '₹${_latestOfferAmount!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _showBuyerProfile,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('View & Accept'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(message, bool isMe, bool isClient) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: isClient && message.isOffer ? _showBuyerProfile : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isMe ? AppTheme.primaryRed : AppTheme.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isMe ? 16 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 16),
                  ),
                boxShadow: AppTheme.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.isOffer) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.white.withOpacity(0.2)
                            : AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 14,
                            color: isMe ? Colors.white : AppTheme.success,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offer: ₹${message.offerAmount?.toStringAsFixed(0) ?? '0'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isMe ? Colors.white : AppTheme.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppTheme.black,
                      fontSize: 15,
                    ),
                  ),
                  // Tap hint for clients on offer messages
                  if (isClient && message.isOffer && !isMe) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.touch_app_outlined,
                          size: 12,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to view profile & accept',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              style: TextStyle(
                color: AppTheme.grey,
                fontSize: 11,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Offer Toggle
          Row(
            children: [
              Checkbox(
                value: _isOffer,
                activeColor: AppTheme.primaryRed,
                onChanged: (value) {
                  setState(() {
                    _isOffer = value ?? false;
                    if (!_isOffer) {
                      _discountedPrice = 0;
                    }
                  });
                },
              ),
              const Text('Send as offer'),
            ],
          ),
          // Offer fields (similar to create request)
          if (_isOffer) ...[
            const SizedBox(height: 8),
            // Offer Amount and Discount Row
            Row(
              children: [
                // Offer Amount
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _offerAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Offer Amount',
                      hintText: 'Amount',
                      prefixText: '₹ ',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _calculateDiscountedPrice(),
                  ),
                ),
                const SizedBox(width: 8),
                // Discount Percent
                Expanded(
                  child: TextField(
                    controller: _discountPercentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Discount',
                      hintText: '%',
                      suffixText: '%',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (_) => _calculateDiscountedPrice(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Price Breakdown
            if (_offerAmountController.text.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.lightGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Breakdown',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Client Pays:', style: TextStyle(fontSize: 12)),
                        Text('₹${_offerAmountController.text}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('You Pay (with card):', style: TextStyle(fontSize: 12)),
                        Text(
                          '₹${_discountedPrice.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.success),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Client Refund (20%):', style: TextStyle(fontSize: 12)),
                        Builder(builder: (context) {
                          final offerAmount = double.tryParse(_offerAmountController.text) ?? 0;
                          final clientRefund = (offerAmount * 0.2);
                          return Text(
                            '₹${clientRefund.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.success),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
          // Message Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppTheme.lightGrey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  return Container(
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryRed,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed:
                          chatProvider.isLoading ? null : _sendMessage,
                      icon: chatProvider.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
