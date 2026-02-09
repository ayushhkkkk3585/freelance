import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../models/event_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';
import '../../services/review_service.dart';
import '../../services/escrow_service.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  int _selectedRating = 0;
  final _commentController = TextEditingController();
  bool _isSubmittingReview = false;
  bool _isRejectingDispute = false;
  bool _isAcceptingDispute = false;

  @override
  void initState() {
    super.initState();
    print('RequestDetailScreen initialized with requestId: ${widget.requestId}'); // Debug log
    _loadRequest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadRequest() async {
    final provider = Provider.of<RequestProvider>(context, listen: false);
    await provider.fetchRequestById(widget.requestId);
    _startTimer();
  }

  void _startTimer() {
    final provider = Provider.of<RequestProvider>(context, listen: false);
    final request = provider.currentRequest;
    
    // Only start timer if accepted AND screenshot not yet uploaded (not in escrow)
    if (request != null && request.isAccepted && request.expiresAt != null && 
        !request.isInEscrow && request.screenshotUrl == null) {
      _remainingTime = request.remainingTime ?? Duration.zero;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTime.inSeconds > 0) {
          setState(() {
            _remainingTime = _remainingTime - const Duration(seconds: 1);
          });
        } else {
          timer.cancel();
          _loadRequest(); // Refresh to get updated status
        }
      });
    } else {
      // Cancel any existing timer if screenshot was uploaded
      _timer?.cancel();
      _remainingTime = Duration.zero;
    }
  }

  Future<void> _completeWithScreenshot() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) {
      print('No image selected'); // Debug log
      return;
    }

    print('Image selected: ${image.path}'); // Debug log
    
    final provider = Provider.of<RequestProvider>(context, listen: false);
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      ),
    );
    
    bool success;
    
    if (kIsWeb) {
      // Web: Use bytes instead of File
      final bytes = await image.readAsBytes();
      final filename = image.name.isNotEmpty ? image.name : 'screenshot.jpg';
      print('Web upload - bytes: ${bytes.length}, filename: $filename'); // Debug log
      success = await provider.completeRequestWeb(
        widget.requestId,
        bytes,
        filename,
      );
    } else {
      // Mobile: Use File
      success = await provider.completeRequest(
        widget.requestId,
        File(image.path),
      );
    }

    // Hide loading indicator
    if (mounted) Navigator.pop(context);

    if (!mounted) return;

    if (success) {
      // Cancel the timer immediately since screenshot was uploaded
      _timer?.cancel();
      setState(() {
        _remainingTime = Duration.zero;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request completed with screenshot!'),
          backgroundColor: AppTheme.success,
        ),
      );
      // Reload to show updated status
      _loadRequest();
    } else {
      print('Complete request failed: ${provider.error}'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to complete request'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.offWhite,
      appBar: AppBar(
        title: const Text('Request Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Open chat
              final provider = Provider.of<RequestProvider>(context, listen: false);
              final request = provider.currentRequest;
              if (request != null) {
                Navigator.pushNamed(
                  context,
                  AppRoutes.chat,
                  arguments: {
                    'requestId': request.id,
                    'otherUserId': request.clientId,
                  },
                );
              }
            },
            icon: const Icon(Icons.chat_outlined),
          ),
        ],
      ),
      body: Consumer<RequestProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.currentRequest == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryRed),
            );
          }

          // Show error message if there's an error
          if (provider.error != null && provider.currentRequest == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppTheme.error,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load request',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      provider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.grey,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadRequest,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final request = provider.currentRequest;
          if (request == null) {
            return const Center(
              child: Text('Request not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timer Card (only if accepted AND screenshot not yet uploaded)
                if (request.isAccepted && !request.isInEscrow && request.screenshotUrl == null) _buildTimerCard(request),
                
                // Status Badge
                _buildStatusBadge(request),
                const SizedBox(height: 16),

                // Event Details Card
                _buildDetailsCard(request),
                const SizedBox(height: 16),

                // Offer Details Card
                _buildOfferCard(request),
                const SizedBox(height: 16),

                // Client Info Card (only if request is accepted)
                if (request.isAccepted) _buildClientInfoCard(request),
                if (request.isAccepted) const SizedBox(height: 16),

                // Action buttons for pending requests (Accept/Ignore)
                if (_shouldShowActions(request)) _buildActionButtons(request, provider),

                // Screenshot Section (for buyers)
                if (_shouldShowUpload(request)) _buildUploadSection(request),
                
                // Screenshot Preview
                if (request.screenshotUrl != null) _buildScreenshotPreview(request),
                
                // Escrow Verification Card (for clients when escrow is held)
                if (_shouldShowEscrowVerification(request)) _buildEscrowVerificationCard(request),
                
                // Dispute Info Card (when there's an active or resolved dispute)
                if (request.isDisputed || request.dispute?.resolved == true) _buildDisputeInfoCard(request),
                
                // Rating Section (for clients when request is completed)
                if (_shouldShowRating(request)) _buildRatingSection(request),
                
                // Already Reviewed Message
                if (_hasAlreadyReviewed(request)) _buildAlreadyReviewedCard(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerCard(EventRequest request) {
    final isExpired = _remainingTime.inSeconds <= 0;
    final minutes = _remainingTime.inMinutes;
    final seconds = _remainingTime.inSeconds % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [AppTheme.error, AppTheme.error.withOpacity(0.8)]
              : [AppTheme.primaryRed, AppTheme.primaryRedDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            isExpired ? 'Time Expired' : 'Time Remaining',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isExpired ? '00:00' : '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isExpired)
            Text(
              'Upload screenshot before timer ends',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(EventRequest request) {
    Color color;
    String label;
    IconData icon;

    switch (request.status) {
      case 'pending':
        color = AppTheme.warning;
        label = 'Pending';
        icon = Icons.pending_outlined;
        break;
      case 'accepted':
        color = AppTheme.info;
        label = 'Accepted';
        icon = Icons.check_circle_outline;
        break;
      case 'completed':
        color = AppTheme.success;
        label = 'Completed';
        icon = Icons.done_all;
        break;
      case 'rejected':
        color = AppTheme.error;
        label = 'Rejected';
        icon = Icons.cancel_outlined;
        break;
      case 'timeout':
        color = AppTheme.grey;
        label = 'Timed Out';
        icon = Icons.timer_off_outlined;
        break;
      default:
        color = AppTheme.grey;
        label = request.status;
        icon = Icons.info_outline;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(EventRequest request) {
    return Container(
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.event_outlined,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.eventName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${request.category} • ${request.platform}',
                      style: TextStyle(
                        color: AppTheme.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildDetailRow(Icons.location_on_outlined, 'Location', request.location),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today_outlined,
            'Date',
            '${request.eventDate.day}/${request.eventDate.month}/${request.eventDate.year}',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.confirmation_number_outlined,
            'Quantity',
            '${request.quantity} ticket(s)',
          ),
          if (request.eventUrl != null) ...[
            const SizedBox(height: 12),
            _buildDetailRow(Icons.link, 'URL', request.eventUrl!),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.grey),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.grey,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOfferCard(EventRequest request) {
    return Container(
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
            'Offer Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.credit_card_outlined, 'Card', request.cardName),
          const SizedBox(height: 12),
          Text(
            request.offerDetails,
            style: TextStyle(
              color: AppTheme.darkGrey,
              fontSize: 14,
            ),
          ),
          const Divider(height: 24),
          // Price Breakdown Section
          _buildPriceRow('Original Price', request.originalPrice, isSubtle: true),
          const SizedBox(height: 8),
          _buildPriceRow('Your Purchase Price', request.discountedPrice, isSubtle: true),
          const SizedBox(height: 8),
          _buildPriceRow('You Receive (80%)', request.buyerPayment, isHighlight: true),
          if (request.isCompleted) ...[
            const SizedBox(height: 8),
            _buildPriceRow('Your Profit', request.buyerProfit, isProfit: true),
          ],
          const Divider(height: 24),
          // Earnings Summary for Buyer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryRed.withOpacity(0.1),
                  AppTheme.primaryRed.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.isCompleted ? 'You Earned' : 'Potential Earnings',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${request.buyerProfit.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    request.isCompleted ? Icons.check_circle : Icons.trending_up,
                    color: AppTheme.success,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfoCard(EventRequest request) {
    return Container(
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
              const Icon(Icons.person, color: AppTheme.primaryRed),
              const SizedBox(width: 8),
              const Text(
                'Client Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.account_circle, 'Name', request.clientName ?? 'N/A'),
          if (request.clientPhone != null && request.clientPhone!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, color: AppTheme.grey, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        request.clientPhone!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _callClient(request.clientPhone!),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.success),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.phone, size: 16, color: AppTheme.success),
                              SizedBox(width: 4),
                              Text(
                                'Call',
                                style: TextStyle(
                                  color: AppTheme.success,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.info, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contact the client if you have any questions about the request.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.info,
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

  Future<void> _callClient(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not launch phone dialer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPriceRow(String label, double amount, {bool isSubtle = false, bool isHighlight = false, bool isProfit = false}) {
    Color textColor = AppTheme.darkGrey;
    FontWeight fontWeight = FontWeight.w500;
    
    if (isSubtle) {
      textColor = AppTheme.grey;
      fontWeight = FontWeight.normal;
    } else if (isHighlight) {
      textColor = AppTheme.primaryRed;
      fontWeight = FontWeight.w600;
    } else if (isProfit) {
      textColor = AppTheme.success;
      fontWeight = FontWeight.bold;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isSubtle ? AppTheme.grey : AppTheme.darkGrey,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: isProfit ? 18 : 16,
            fontWeight: fontWeight,
            color: textColor,
          ),
        ),
      ],
    );
  }

  bool _shouldShowActions(EventRequest request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isBuyer && request.isPending;
  }

  Widget _buildActionButtons(EventRequest request, RequestProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          const Text(
            'Take Action',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Accept this request to start booking the ticket',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.grey,
                    side: BorderSide(color: AppTheme.grey.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Ignore'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final success = await provider.acceptRequest(request.id);
                    if (!mounted) return;
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Request accepted! Complete the booking before timer ends.'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      // Reload request to get updated status and timer
                      _loadRequest();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(provider.error ?? 'Failed to accept request'),
                          backgroundColor: AppTheme.error,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, color: AppTheme.success, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Potential Profit: ₹${request.buyerProfit.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowUpload(EventRequest request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isBuyer && 
           request.isAccepted && 
           request.screenshotUrl == null &&
           _remainingTime.inSeconds > 0;
  }


  Widget _buildUploadSection(EventRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.upload_file_outlined,
            size: 48,
            color: AppTheme.primaryRed,
          ),
          const SizedBox(height: 12),
          const Text(
            'Upload Ticket Screenshot',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a screenshot of the purchased ticket and upload it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _completeWithScreenshot,
            icon: const Icon(Icons.camera_alt_outlined),
            label: const Text('Upload & Complete'),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotPreview(EventRequest request) {
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
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Ticket Screenshot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            child: Image.network(
              AppConstants.getImageUrl(request.screenshotUrl),
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  color: AppTheme.lightGrey,
                  child: const Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryRed),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  color: AppTheme.lightGrey,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, size: 48),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowRating(EventRequest request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isClient && 
           request.isCompleted && 
           !request.clientReviewSubmitted;
  }

  bool _hasAlreadyReviewed(EventRequest request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isClient && 
           request.isCompleted && 
           request.clientReviewSubmitted;
  }

  Widget _buildRatingSection(EventRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(
          color: AppTheme.primaryRed.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.star_rounded,
                  color: AppTheme.primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate the Buyer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'How was your experience?',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Star Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starNumber = index + 1;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRating = starNumber;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    starNumber <= _selectedRating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 48,
                    color: starNumber <= _selectedRating
                        ? Colors.amber
                        : AppTheme.grey.withOpacity(0.5),
                  ),
                ),
              );
            }),
          ),
          
          // Rating Label
          if (_selectedRating > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  _getRatingLabel(_selectedRating),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.amber,
                  ),
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Comment Field
          TextFormField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Write a comment (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.grey.withOpacity(0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppTheme.grey.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryRed),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRating > 0 && !_isSubmittingReview
                  ? () => _submitReview(request)
                  : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                disabledBackgroundColor: AppTheme.grey.withOpacity(0.3),
              ),
              child: _isSubmittingReview
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit Rating',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Poor 😞';
      case 2:
        return 'Fair 😐';
      case 3:
        return 'Good 🙂';
      case 4:
        return 'Very Good 😊';
      case 5:
        return 'Excellent! 🌟';
      default:
        return '';
    }
  }

  Future<void> _submitReview(EventRequest request) async {
    setState(() {
      _isSubmittingReview = true;
    });

    try {
      await ReviewService.createReview(
        requestId: request.id,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty 
            ? _commentController.text.trim() 
            : null,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your rating!'),
          backgroundColor: AppTheme.success,
        ),
      );

      // Reload request to update the review status
      _loadRequest();
    } catch (e) {
      if (!mounted) return;
      
      final errorMessage = e.toString();
      
      // If already reviewed, still reload to update UI
      if (errorMessage.toLowerCase().contains('already reviewed') ||
          errorMessage.toLowerCase().contains('already submitted')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have already reviewed this request'),
            backgroundColor: AppTheme.warning,
          ),
        );
        // Reload request to hide the rating section
        _loadRequest();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit rating: $errorMessage'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingReview = false;
        });
      }
    }
  }

  Widget _buildAlreadyReviewedCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rating Submitted',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.success,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Thank you for rating the buyer!',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.darkGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowEscrowVerification(EventRequest request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.isClient && request.isInEscrow;
  }

  Widget _buildEscrowVerificationCard(EventRequest request) {
    final remainingTime = request.escrowRemainingTime;
    final isUrgent = remainingTime != null && remainingTime.inHours < 2;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUrgent ? AppTheme.error.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUrgent ? AppTheme.error : AppTheme.warning,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                color: isUrgent ? AppTheme.error : AppTheme.warning,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Ticket Needs Verification',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'The buyer has uploaded a ticket screenshot. Please verify that the ticket is valid and matches your request.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.darkGrey,
            ),
          ),
          if (remainingTime != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUrgent ? AppTheme.error.withOpacity(0.2) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer,
                    color: isUrgent ? AppTheme.error : AppTheme.warning,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Time remaining: ${_formatEscrowTime(remainingTime)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isUrgent ? AppTheme.error : AppTheme.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.ticketVerification,
                  arguments: request.id,
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('View & Verify Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payment will be auto-released if you don\'t respond in time.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.grey,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDisputeInfoCard(EventRequest request) {
    final dispute = request.dispute;
    final isResolved = dispute?.resolved ?? false;
    final resolution = dispute?.resolution;
    
    Color cardColor;
    IconData cardIcon;
    String statusText;
    
    if (isResolved) {
      if (resolution == 'client_wins') {
        cardColor = AppTheme.success;
        cardIcon = Icons.check_circle;
        statusText = 'Dispute resolved in your favor';
      } else if (resolution == 'dispute_rejected') {
        cardColor = AppTheme.error;
        cardIcon = Icons.cancel;
        statusText = 'Dispute was rejected';
      } else {
        cardColor = AppTheme.warning;
        cardIcon = Icons.gavel;
        statusText = 'Dispute resolved';
      }
    } else {
      cardColor = AppTheme.warning;
      cardIcon = Icons.flag;
      statusText = 'Dispute Active';
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(cardIcon, color: cardColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cardColor,
                      ),
                    ),
                    if (dispute?.raisedAt != null)
                      Text(
                        'Raised on ${_formatDisputeDate(dispute!.raisedAt!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (dispute?.reason != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Dispute Reason:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                dispute!.reason!,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
          if (isResolved && dispute?.resolvedAt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Resolved on ${_formatDisputeDate(dispute!.resolvedAt!)}',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          // Show Reject Dispute button for buyer when dispute is active
          if (!isResolved) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildDisputeActions(request),
          ],
        ],
      ),
    );
  }

  Widget _buildDisputeActions(EventRequest request) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isBuyer = authProvider.isBuyer;

    if (!isBuyer) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dispute Actions',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose how to respond to this dispute:',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.grey,
          ),
        ),
        const SizedBox(height: 12),
        // Accept Dispute Button (Refund client)
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isAcceptingDispute ? null : () => _acceptDispute(request),
            icon: _isAcceptingDispute 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check_circle, size: 18),
            label: Text(_isAcceptingDispute ? 'Processing...' : 'Accept Dispute (Refund Client)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Reject Dispute Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isRejectingDispute ? null : () => _rejectDispute(request),
            icon: _isRejectingDispute 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.cancel, size: 18),
            label: Text(_isRejectingDispute ? 'Rejecting...' : 'Reject Dispute (Keep Payment)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _acceptDispute(EventRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Dispute'),
        content: const Text(
          'By accepting the dispute, the client will be refunded and you will not receive payment for this request. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warning,
            ),
            child: const Text('Yes, Accept Dispute'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isAcceptingDispute = true);

    try {
      final result = await EscrowService.acceptRefund(request.id);
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispute accepted. Client has been refunded.'),
              backgroundColor: AppTheme.warning,
            ),
          );
          // Reload request to reflect changes
          await _loadRequest();
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to accept dispute');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAcceptingDispute = false);
      }
    }
  }

  Future<void> _rejectDispute(EventRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Dispute'),
        content: const Text(
          'Are you sure this dispute is false? If approved, the payment will be completed and you will receive your earnings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
            ),
            child: const Text('Yes, Reject Dispute'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isRejectingDispute = true);

    try {
      final result = await EscrowService.rejectDispute(request.id);
      
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dispute rejected successfully! Payment completed.'),
              backgroundColor: AppTheme.success,
            ),
          );
          // Reload request to reflect changes
          await _loadRequest();
        }
      } else {
        throw Exception(result['message'] ?? 'Failed to reject dispute');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRejectingDispute = false);
      }
    }
  }

  String _formatDisputeDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatEscrowTime(Duration duration) {
    if (duration.inSeconds <= 0) return 'Expired';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }
}

