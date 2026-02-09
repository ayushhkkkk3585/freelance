const { Request, User, Review } = require('../models');
const { walletService, notificationService, timerService } = require('../services');
const ticketVerificationService = require('../services/ticketVerification.service');

class RequestController {
  /**
   * Create new request (Client only)
   * 
   * PRICING LOGIC:
   * - Client pays originalPrice (e.g., ₹1000 = 1000 points)
   * - Buyer purchases at discountedPrice (e.g., ₹700) using their discount card
   * - App pays buyer buyerPayment (80% of original = 800 points)
   * - Client gets refund (20% of original = 200 points)
   * - Buyer profit = buyerPayment - discountedPrice (800 - 700 = 100 points)
   * - App profit = originalPrice - buyerPayment (1000 - 800 = 200 points)
   */
  async create(req, res) {
    try {
      console.log('Create Request - Body:', JSON.stringify(req.body, null, 2));
      
      const {
        eventName,
        location,
        eventDate,
        quantity,
        category,
        platform,
        cardName,
        offerDetails,
        originalPrice: originalPriceInput,      // What client pays (e.g., 1000)
        discountedPrice: discountedPriceInput,  // What buyer pays using card (e.g., 700)
        finalAmount,                             // Legacy field for backward compatibility
        eventUrl,
      } = req.body;
      
      console.log('Parsed values:', { originalPriceInput, discountedPriceInput, finalAmount });
      
      // Handle backward compatibility: use finalAmount as originalPrice if not provided
      const originalPrice = originalPriceInput || finalAmount;
      // Default discountedPrice to 70% of originalPrice if not provided (30% discount)
      const discountedPrice = discountedPriceInput || Math.round(originalPrice * 0.7);
      
      console.log('Final prices:', { originalPrice, discountedPrice });
      
      if (!originalPrice || originalPrice <= 0) {
        console.log('Validation failed: originalPrice is invalid');
        return res.status(400).json({
          success: false,
          message: 'Original price is required and must be greater than 0',
        });
      }
      
      // Calculate profit breakdown
      const profitBreakdown = walletService.calculateProfitBreakdown(
        originalPrice,
        discountedPrice
      );
      
      console.log('Profit breakdown:', profitBreakdown);
      
      // Check client has enough balance for original price
      const balance = await walletService.getBalance(req.userId);
      if (balance.availableBalance < originalPrice) {
        return res.status(400).json({
          success: false,
          message: 'Insufficient balance',
        });
      }
      
      const request = new Request({
        clientId: req.userId,
        eventName,
        location,
        eventDate,
        quantity,
        category,
        platform,
        cardName,
        offerDetails,
        finalAmount: originalPrice,
        originalPrice,
        discountedPrice,
        buyerPayment: profitBreakdown.buyerPayment,
        clientRefund: profitBreakdown.clientRefund,
        buyerProfit: profitBreakdown.buyerProfit,
        appProfit: profitBreakdown.appProfit,
        eventUrl,
      });
      await request.save();
      
      // Notify client
      await notificationService.notifyRequestCreated(
        req.userId,
        request._id,
        eventName
      );
      
      // Notify all buyers about the new request
      await notificationService.notifyBuyersNewRequest(
        request._id,
        eventName,
        category
      );
      
      res.status(201).json({
        success: true,
        message: 'Request created successfully',
        data: { 
          request,
          profitBreakdown: {
            clientPays: originalPrice,
            clientRefund: profitBreakdown.clientRefund,
            clientNetCost: originalPrice - profitBreakdown.clientRefund,
            buyerEarns: profitBreakdown.buyerPayment,
            buyerProfit: profitBreakdown.buyerProfit,
          }
        },
      });
    } catch (error) {
      console.error('Create request error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to create request',
      });
    }
  }

  /**
   * Get all pending requests (Buyer only)
   */
  async getPendingRequests(req, res) {
    try {
      const { category, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      const query = { status: 'pending' };
      if (category && category !== 'all') {
        query.category = category;
      }
      
      const requests = await Request.find(query)
        .populate('clientId', 'name rating phone')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      const total = await Request.countDocuments(query);
      
      res.json({
        success: true,
        data: {
          requests,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get pending requests error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get requests',
      });
    }
  }

  /**
   * Get client's requests
   */
  async getMyRequests(req, res) {
    try {
      const { status, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      const query = { clientId: req.userId };
      if (status && status !== 'all') {
        query.status = status;
      }
      
      const requests = await Request.find(query)
        .populate('buyerId', 'name rating profileImage phone')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      const total = await Request.countDocuments(query);
      
      res.json({
        success: true,
        data: {
          requests,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get my requests error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get requests',
      });
    }
  }

  /**
   * Get buyer's accepted requests
   */
  async getBuyerRequests(req, res) {
    try {
      const { status, page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      const query = { buyerId: req.userId };
      if (status && status !== 'all') {
        query.status = status;
      }
      
      console.log('=========== getBuyerRequests DEBUG ===========');
      console.log('userId from token:', req.userId);
      console.log('Query:', JSON.stringify(query));
      
      const requests = await Request.find(query)
        .populate('clientId', 'name rating profileImage phone')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      console.log('Found requests count:', requests.length);
      if (requests.length > 0) {
        console.log('First request:', JSON.stringify({
          id: requests[0]._id,
          eventName: requests[0].eventName,
          status: requests[0].status,
          buyerId: requests[0].buyerId,
        }));
      }
      
      // Also check total requests in DB to compare
      const allRequestsCount = await Request.countDocuments({});
      const requestsWithBuyer = await Request.countDocuments({ buyerId: { $exists: true, $ne: null } });
      console.log('Total requests in DB:', allRequestsCount);
      console.log('Requests with any buyerId:', requestsWithBuyer);
      console.log('==============================================');
      
      const total = await Request.countDocuments(query);
      
      res.json({
        success: true,
        data: {
          requests,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get buyer requests error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get requests',
      });
    }
  }

  /**
   * Get single request
   */
  async getRequest(req, res) {
    try {
      console.log('getRequest called with id:', req.params.id); // Debug log
      const request = await Request.findById(req.params.id)
        .populate('clientId', 'name email phone rating profileImage')
        .populate('buyerId', 'name email phone rating profileImage cardsOwned');
      
      console.log('Request found:', request ? 'yes' : 'no'); // Debug log
      
      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }
      
      // Sync clientReviewSubmitted flag if out of sync
      if (request.status === 'completed' && !request.clientReviewSubmitted) {
        const existingReview = await Review.findOne({
          requestId: request._id,
          reviewerId: request.clientId._id,
        });
        
        if (existingReview) {
          // Update the flag
          request.clientReviewSubmitted = true;
          request.clientReviewId = existingReview._id;
          await request.save();
          console.log('Synced clientReviewSubmitted flag for request:', request._id);
        }
      }
      
      res.json({
        success: true,
        data: { request },
      });
    } catch (error) {
      console.error('Get request error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get request',
      });
    }
  }

  /**
   * Accept request (Buyer only)
   */
  async acceptRequest(req, res) {
    try {
      const request = await Request.findById(req.params.id)
        .populate('clientId', 'name');
      
      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }
      
      if (request.status !== 'pending') {
        return res.status(400).json({
          success: false,
          message: 'Request is no longer available',
        });
      }
      
      // Freeze client's original price amount
      try {
        await walletService.freezePoints(
          request.clientId._id,
          request.originalPrice,
          `Points frozen for ${request.eventName}`,
          request._id
        );
      } catch (error) {
        return res.status(400).json({
          success: false,
          message: 'Client has insufficient balance',
        });
      }
      
      // Update request
      request.status = 'accepted';
      request.buyerId = req.userId;
      await request.save();
      
      // Start timer
      await timerService.startTimer(request._id);
      
      // Get buyer info
      const buyer = await User.findById(req.userId);
      
      // Notify client
      await notificationService.notifyRequestAccepted(
        request.clientId._id,
        request._id,
        request.eventName,
        buyer.name
      );
      
      await notificationService.notifyPointsDeducted(
        request.clientId._id,
        request.originalPrice,
        request._id
      );
      
      // Notify buyer about their acceptance with profit info
      await notificationService.create(
        req.userId,
        'request_accepted',
        'Request Accepted!',
        `You have accepted "${request.eventName}". Complete within 5 minutes to earn ₹${request.buyerPayment} (Profit: ₹${request.buyerProfit}).`,
        { requestId: request._id }
      );
      
      // Update buyer's booking count
      await User.findByIdAndUpdate(req.userId, {
        $inc: { totalBookings: 1 },
      });
      
      // Refetch with populated fields
      const updatedRequest = await Request.findById(request._id)
        .populate('clientId', 'name email phone rating profileImage')
        .populate('buyerId', 'name email phone rating profileImage');
      
      res.json({
        success: true,
        message: 'Request accepted. Timer started.',
        data: { 
          request: updatedRequest,
          profitInfo: {
            buyerWillEarn: request.buyerPayment,
            buyerProfit: request.buyerProfit,
            clientWillPay: request.originalPrice,
            clientWillGetRefund: request.clientRefund,
          }
        },
      });
    } catch (error) {
      console.error('Accept request error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to accept request',
      });
    }
  }

  /**
   * Complete request with screenshot (Buyer only)
   */
  async completeRequest(req, res) {
    try {
      console.log('completeRequest called with id:', req.params.id); // Debug log
      console.log('File received:', req.file ? JSON.stringify({
        fieldname: req.file.fieldname,
        originalname: req.file.originalname,
        path: req.file.path,
        filename: req.file.filename,
      }) : 'No file'); // Debug log
      
      const request = await Request.findById(req.params.id);
      
      if (!request) {
        console.log('Request not found'); // Debug log
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }
      
      if (request.buyerId.toString() !== req.userId.toString()) {
        console.log('Not authorized - buyerId:', request.buyerId, 'userId:', req.userId); // Debug log
        return res.status(403).json({
          success: false,
          message: 'Not authorized',
        });
      }
      
      if (request.status !== 'accepted') {
        console.log('Invalid status:', request.status); // Debug log
        return res.status(400).json({
          success: false,
          message: 'Request cannot be completed',
        });
      }
      
      if (!req.file) {
        console.log('No screenshot file provided'); // Debug log
        return res.status(400).json({
          success: false,
          message: 'Screenshot is required',
        });
      }

      const imagePath = req.file.path;

      // Run OCR verification on the uploaded screenshot
      console.log('Running OCR verification on:', imagePath);
      const verification = await ticketVerificationService.verifyTicket(imagePath, request);
      console.log('OCR Verification result:', {
        approved: verification.approved,
        autoRejected: verification.autoRejected,
        warnings: verification.warnings,
        confidence: verification.confidence,
      });

      // If auto-rejected (duplicate booking ID), reject the upload
      if (verification.autoRejected) {
        return res.status(400).json({
          success: false,
          message: verification.rejectReason,
          verification: {
            status: 'rejected',
            reason: verification.rejectReason,
            extractedData: verification.extractedData,
          },
          canRetry: true, // Buyer can upload a different screenshot
        });
      }
      
      // Cancel timer
      timerService.cancelTimer(request._id);

      // Calculate escrow deadline (24 hours for client to verify)
      const clientDeadline = new Date();
      clientDeadline.setHours(clientDeadline.getHours() + 24);
      
      // Update request with screenshot and verification data
      request.screenshotUrl = imagePath; // Cloudinary URL
      request.screenshotUploadedAt = new Date();
      request.bookingId = verification.extractedData.bookingId?.toUpperCase() || null;
      request.verification = {
        status: 'passed',
        extractedData: verification.extractedData,
        warnings: verification.warnings,
        confidence: verification.confidence,
        verifiedAt: new Date(),
      };
      request.escrow = {
        status: 'held',
        heldAt: new Date(),
        clientDeadline: clientDeadline,
      };
      // Keep status as 'accepted' until client confirms
      await request.save();
      
      console.log('Screenshot uploaded with OCR verification:', imagePath); // Debug log

      // Notify client based on verification results
      const hasWarnings = verification.warnings.length > 0;
      
      await notificationService.create(
        request.clientId,
        hasWarnings ? 'ticket_needs_review' : 'ticket_uploaded',
        hasWarnings ? '⚠️ Ticket Uploaded - Please Review' : '✅ Ticket Uploaded',
        hasWarnings
          ? `Buyer uploaded ticket with ${verification.warnings.length} warning(s). Please verify within 24 hours.`
          : `Buyer has uploaded the ticket for "${request.eventName}". Please confirm within 24 hours.`,
        { 
          requestId: request._id.toString(),
          warnings: verification.warnings,
          extractedData: {
            bookingId: verification.extractedData.bookingId,
            amount: verification.extractedData.amount,
            platform: verification.extractedData.platform,
          },
        }
      );

      // Notify buyer that screenshot is pending verification
      await notificationService.create(
        request.buyerId,
        'screenshot_pending',
        'Screenshot Uploaded',
        `Your ticket screenshot is pending client verification. You'll be notified once confirmed.`,
        { requestId: request._id.toString() }
      );
      
      // Refetch with populated fields
      const updatedRequest = await Request.findById(request._id)
        .populate('clientId', 'name email phone photoUrl rating')
        .populate('buyerId', 'name email phone photoUrl rating');

      res.json({
        success: true,
        message: hasWarnings
          ? 'Screenshot uploaded with warnings. Waiting for client verification.'
          : 'Screenshot uploaded successfully. Waiting for client confirmation.',
        data: { 
          request: updatedRequest,
          screenshotUrl: request.screenshotUrl,
          verification: {
            status: verification.approved ? 'passed' : 'rejected',
            warnings: verification.warnings,
            extractedData: {
              bookingId: verification.extractedData.bookingId,
              amount: verification.extractedData.amount,
              date: verification.extractedData.date,
              platform: verification.extractedData.platform,
            },
            confidence: verification.confidence,
          },
          escrow: {
            status: 'held',
            clientDeadline: clientDeadline,
          },
        },
      });
    } catch (error) {
      console.error('Complete request error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to complete request',
      });
    }
  }

  /**
   * Accept offer from chat (Client only)
   * This is called when a client accepts a buyer's offer from the chat with a negotiated price
   * 
   * Uses the same discount logic as create request:
   * - originalPrice = offerAmount (what client pays)
   * - discountPercent = discount percentage (default 30%)
   * - discountedPrice = originalPrice * (100 - discountPercent) / 100 (what buyer pays with card)
   */
  async acceptOfferFromChat(req, res) {
    try {
      const { offerAmount, discountPercent: discountPercentInput } = req.body;
      
      if (!offerAmount || offerAmount <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Offer amount is required and must be greater than 0',
        });
      }
      
      // Use provided discount percent or default to 30%
      const discountPercent = discountPercentInput !== undefined ? discountPercentInput : 30;
      
      // Validate discount percent
      if (discountPercent < 0 || discountPercent > 100) {
        return res.status(400).json({
          success: false,
          message: 'Discount percent must be between 0 and 100',
        });
      }
      
      const request = await Request.findById(req.params.id)
        .populate('buyerId', 'name');
      
      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }
      
      // Verify the client owns this request
      if (request.clientId.toString() !== req.userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to accept this offer',
        });
      }
      
      // Must have a buyer assigned (from chat)
      if (!request.buyerId) {
        return res.status(400).json({
          success: false,
          message: 'No buyer assigned to this request',
        });
      }
      
      if (request.status !== 'pending') {
        return res.status(400).json({
          success: false,
          message: 'Request is no longer available for acceptance',
        });
      }
      
      // Apply the same discount logic as create request
      // originalPrice = offerAmount (what client pays)
      const originalPrice = offerAmount;
      // discountedPrice = originalPrice * (100 - discountPercent) / 100 (what buyer pays using their discount card)
      const discountedPrice = Math.round(originalPrice * (100 - discountPercent) / 100);
      
      // Calculate new profit breakdown
      const profitBreakdown = walletService.calculateProfitBreakdown(
        originalPrice,
        discountedPrice
      );
      
      // Check client has enough balance for the new offer amount
      const balance = await walletService.getBalance(req.userId);
      if (balance.availableBalance < originalPrice) {
        return res.status(400).json({
          success: false,
          message: 'Insufficient balance for this offer amount',
        });
      }
      
      // Freeze client's points for the new offer amount
      try {
        await walletService.freezePoints(
          req.userId,
          originalPrice,
          `Points frozen for ${request.eventName} (negotiated offer)`,
          request._id
        );
      } catch (error) {
        return res.status(400).json({
          success: false,
          message: 'Failed to freeze points: ' + error.message,
        });
      }
      
      // Update request with new pricing and status
      request.status = 'accepted';
      request.finalAmount = originalPrice;
      request.originalPrice = originalPrice;
      request.discountedPrice = discountedPrice;
      request.buyerPayment = profitBreakdown.buyerPayment;
      request.clientRefund = profitBreakdown.clientRefund;
      request.buyerProfit = profitBreakdown.buyerProfit;
      request.appProfit = profitBreakdown.appProfit;
      await request.save();
      
      // Start timer
      await timerService.startTimer(request._id);
      
      // Get client info
      const client = await User.findById(req.userId);
      
      // Notify buyer that client accepted their offer
      await notificationService.create(
        request.buyerId._id,
        'offer_accepted',
        'Offer Accepted!',
        `${client.name} has accepted your offer of ₹${originalPrice} for "${request.eventName}". Timer started! Complete within 5 minutes to earn ₹${profitBreakdown.buyerPayment}.`,
        { requestId: request._id.toString() }
      );
      
      // Notify client about points frozen
      await notificationService.notifyPointsDeducted(
        req.userId,
        originalPrice,
        request._id
      );
      
      // Refetch with populated fields
      const updatedRequest = await Request.findById(request._id)
        .populate('clientId', 'name email phone rating profileImage')
        .populate('buyerId', 'name email phone rating profileImage');
      
      res.json({
        success: true,
        message: 'Offer accepted successfully. Timer started!',
        data: { 
          request: updatedRequest,
          profitInfo: {
            clientPays: originalPrice,
            clientRefund: profitBreakdown.clientRefund,
            clientNetCost: originalPrice - profitBreakdown.clientRefund,
            buyerWillEarn: profitBreakdown.buyerPayment,
            buyerProfit: profitBreakdown.buyerProfit,
          }
        },
      });
    } catch (error) {
      console.error('Accept offer from chat error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to accept offer',
      });
    }
  }

  /**
   * Cancel request (Client only)
   */
  async cancelRequest(req, res) {
    try {
      const request = await Request.findById(req.params.id);
      
      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }
      
      if (request.clientId.toString() !== req.userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized',
        });
      }
      
      if (!['pending'].includes(request.status)) {
        return res.status(400).json({
          success: false,
          message: 'Only pending requests can be cancelled',
        });
      }
      
      request.status = 'cancelled';
      request.cancellationReason = req.body.reason || 'Cancelled by client';
      await request.save();
      
      res.json({
        success: true,
        message: 'Request cancelled',
        data: { request },
      });
    } catch (error) {
      console.error('Cancel request error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to cancel request',
      });
    }
  }

  /**
   * Get request statistics
   */
  async getStats(req, res) {
    try {
      const userId = req.userId;
      const role = req.user.role;
      
      let stats;
      
      if (role === 'client') {
        const [pending, accepted, completed, rejected] = await Promise.all([
          Request.countDocuments({ clientId: userId, status: 'pending' }),
          Request.countDocuments({ clientId: userId, status: 'accepted' }),
          Request.countDocuments({ clientId: userId, status: 'completed' }),
          Request.countDocuments({ clientId: userId, status: { $in: ['rejected', 'timeout'] } }),
        ]);
        
        stats = { pending, accepted, completed, failed: rejected };
      } else {
        const [available, accepted, completed] = await Promise.all([
          Request.countDocuments({ status: 'pending' }),
          Request.countDocuments({ buyerId: userId, status: 'accepted' }),
          Request.countDocuments({ buyerId: userId, status: 'completed' }),
        ]);
        
        stats = { available, inProgress: accepted, completed };
      }
      
      res.json({
        success: true,
        data: { stats },
      });
    } catch (error) {
      console.error('Get stats error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get stats',
      });
    }
  }
}

module.exports = new RequestController();
