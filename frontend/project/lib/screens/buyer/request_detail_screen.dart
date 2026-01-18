import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/constants/app_constants.dart';
import '../../models/event_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/request_provider.dart';

class RequestDetailScreen extends StatefulWidget {
  final String requestId;

  const RequestDetailScreen({super.key, required this.requestId});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    print('RequestDetailScreen initialized with requestId: ${widget.requestId}'); // Debug log
    _loadRequest();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
    
    if (request != null && request.isAccepted && request.expiresAt != null) {
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
                // Timer Card (if accepted)
                if (request.isAccepted) _buildTimerCard(request),
                
                // Status Badge
                _buildStatusBadge(request),
                const SizedBox(height: 16),

                // Event Details Card
                _buildDetailsCard(request),
                const SizedBox(height: 16),

                // Offer Details Card
                _buildOfferCard(request),
                const SizedBox(height: 16),

                // Action buttons for pending requests (Accept/Ignore)
                if (_shouldShowActions(request)) _buildActionButtons(request, provider),

                // Screenshot Section (for buyers)
                if (_shouldShowUpload(request)) _buildUploadSection(request),
                
                // Screenshot Preview
                if (request.screenshotUrl != null) _buildScreenshotPreview(request),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Final Amount',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₹${request.finalAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryRed,
                ),
              ),
            ],
          ),
        ],
      ),
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
          Text(
            'Earnings: ₹${request.finalAmount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryRed,
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
}
