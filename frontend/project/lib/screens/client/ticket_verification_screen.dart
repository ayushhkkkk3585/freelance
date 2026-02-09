import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_request.dart';
import '../../services/escrow_service.dart';
import '../../services/request_service.dart';

class TicketVerificationScreen extends StatefulWidget {
  final String requestId;

  const TicketVerificationScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<TicketVerificationScreen> createState() => _TicketVerificationScreenState();
}

class _TicketVerificationScreenState extends State<TicketVerificationScreen> {
  EventRequest? _request;
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _errorMessage;
  Timer? _countdownTimer;
  Duration _remainingTime = Duration.zero;
  final TextEditingController _disputeReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _disputeReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadRequest() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final request = await RequestService.getRequestById(widget.requestId);
      setState(() {
        _request = request;
        _isLoading = false;
      });
      _startCountdown();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading request: $e';
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    if (_request?.escrow?.clientDeadline != null) {
      _updateRemainingTime();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateRemainingTime();
      });
    }
  }

  void _updateRemainingTime() {
    if (_request?.escrow?.clientDeadline != null) {
      final deadline = _request!.escrow!.clientDeadline!;
      final now = DateTime.now();
      if (deadline.isAfter(now)) {
        setState(() {
          _remainingTime = deadline.difference(now);
        });
      } else {
        setState(() {
          _remainingTime = Duration.zero;
        });
        _countdownTimer?.cancel();
      }
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds <= 0) return 'Expired';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  Future<void> _confirmTicket() async {
    try {
      setState(() => _isProcessing = true);

      final response = await EscrowService.confirmTicket(widget.requestId);
      
      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ticket confirmed! Payment released to buyer.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to confirm ticket'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _raiseDispute() async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raise Dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please describe why you believe the ticket is invalid:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _disputeReasonController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'E.g., Wrong booking ID, amount doesn\'t match, wrong event date...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_disputeReasonController.text.trim().isNotEmpty) {
                Navigator.pop(context, _disputeReasonController.text.trim());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
            ),
            child: const Text('Submit Dispute', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        setState(() => _isProcessing = true);

        final response = await EscrowService.raiseDispute(widget.requestId, reason);
        
        if (response['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dispute raised. Buyer has 48 hours to respond.'),
                backgroundColor: Colors.orange,
              ),
            );
            Navigator.of(context).pop(true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response['message'] ?? 'Failed to raise dispute'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isProcessing = false);
        }
      }
    }
    _disputeReasonController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Ticket'),
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRequest,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_request == null) {
      return const Center(child: Text('Request not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Countdown Timer Card
          _buildCountdownCard(),
          const SizedBox(height: 16),

          // Request Details Card
          _buildRequestDetailsCard(),
          const SizedBox(height: 16),

          // Buyer Info Card
          _buildBuyerInfoCard(),
          const SizedBox(height: 16),

          // Screenshot Preview
          _buildScreenshotCard(),
          const SizedBox(height: 16),

          // OCR Extracted Data
          if (_request!.verification != null) ...[
            _buildVerificationCard(),
            const SizedBox(height: 16),
          ],

          // Warnings
          if (_request!.verification?.warnings.isNotEmpty == true) ...[
            _buildWarningsCard(),
            const SizedBox(height: 16),
          ],

          // Auto-release Info
          _buildAutoReleaseInfo(),
          const SizedBox(height: 24),

          // Action Buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCountdownCard() {
    final isExpired = _remainingTime.inSeconds <= 0;
    final isUrgent = _remainingTime.inHours < 2;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isExpired
            ? Colors.grey[200]
            : isUrgent
                ? Colors.red[50]
                : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? Colors.grey
              : isUrgent
                  ? Colors.red
                  : Colors.orange,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            color: isExpired
                ? Colors.grey
                : isUrgent
                    ? Colors.red
                    : Colors.orange,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isExpired ? 'Verification Expired' : 'Time to Verify',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _formatDuration(_remainingTime),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isExpired
                        ? Colors.grey
                        : isUrgent
                            ? Colors.red
                            : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Request Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildDetailRow('Event', _request!.eventName),
            _buildDetailRow('Location', _request!.location),
            _buildDetailRow('Date', _formatDate(_request!.eventDate)),
            _buildDetailRow('Platform', _request!.platform),
            _buildDetailRow('Quantity', '${_request!.quantity} tickets'),
            _buildDetailRow('Amount Paid', '₹${_request!.originalPrice.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBuyerInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                const Text(
                  'Buyer Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            _buildDetailRow('Name', _request!.buyerName ?? 'N/A'),
            if (_request!.buyerPhone != null && _request!.buyerPhone!.isNotEmpty) ...[  
              const SizedBox(height: 8),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      'Phone',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          _request!.buyerPhone!,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _callBuyer(),
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
                      'Contact the buyer if you have any questions about the ticket.',
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
      ),
    );
  }

  Future<void> _callBuyer() async {
    if (_request?.buyerPhone == null) return;
    final url = Uri.parse('tel:${_request!.buyerPhone}');
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

  Widget _buildScreenshotCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Ticket Screenshot',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_request!.screenshotUrl != null)
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 400),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(
                  _request!.screenshotUrl!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          const Text('Failed to load image'),
                        ],
                      ),
                    );
                  },
                ),
              ),
            )
          else
            Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  const Text('No screenshot uploaded'),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Pinch to zoom for a closer look',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard() {
    final verification = _request!.verification!;
    final extracted = verification.extractedData;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  verification.status == 'verified'
                      ? Icons.verified
                      : Icons.info_outline,
                  color: verification.status == 'verified'
                      ? Colors.green
                      : Colors.orange,
                ),
                const SizedBox(width: 8),
                const Text(
                  'OCR Extracted Data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: verification.status == 'verified'
                    ? Colors.green[50]
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Confidence: ${verification.confidence.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: verification.status == 'verified'
                      ? Colors.green[700]
                      : Colors.orange[700],
                ),
              ),
            ),
            const Divider(),
            if (extracted != null) ...[
              if (extracted.bookingId != null)
                _buildDetailRow('Booking ID', extracted.bookingId!, icon: Icons.confirmation_number),
              if (extracted.amount != null)
                _buildDetailRow('Amount', extracted.amount!, icon: Icons.currency_rupee),
              if (extracted.date != null)
                _buildDetailRow('Date', extracted.date!, icon: Icons.calendar_today),
              if (extracted.platform != null)
                _buildDetailRow('Platform', extracted.platform!, icon: Icons.public),
            ] else
              const Text(
                'Could not extract ticket details automatically',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningsCard() {
    final warnings = _request!.verification!.warnings;

    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  'Verification Warnings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...warnings.map((warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            const Text(
              'Please review the screenshot carefully before confirming.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoReleaseInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-Release Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'If you don\'t respond within 24 hours, the payment will be automatically released to the buyer and the ticket will be marked as verified.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_request!.escrow?.status != 'held') {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _request!.escrow?.status == 'released'
                  ? Icons.check_circle
                  : Icons.info_outline,
              color: _request!.escrow?.status == 'released'
                  ? Colors.green
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _request!.escrow?.status == 'released'
                    ? 'Ticket has been verified and payment released.'
                    : _request!.escrow?.status == 'refunded'
                        ? 'This request has been refunded.'
                        : _request!.escrow?.status == 'dispute'
                            ? 'Dispute is in progress.'
                            : 'Verification not available for this request.',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Confirm Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _confirmTicket,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_circle),
            label: const Text(
              'Confirm Ticket is Valid',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Dispute Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _raiseDispute,
            icon: const Icon(Icons.flag),
            label: const Text(
              'Raise Dispute',
              style: TextStyle(fontSize: 16),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.error,
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: icon != null ? 80 : 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
