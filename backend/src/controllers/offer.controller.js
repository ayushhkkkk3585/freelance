const { Offer, User, Request } = require('../models');
const { notificationService, timerService } = require('../services');

class OfferController {
  /**
   * Get all active offers (for clients to browse)
   */
  async getAllOffers(req, res) {
    try {
      const { page = 1, limit = 20, category } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      const query = {
        status: 'active',
        // Don't show offers rejected by this client
        rejectedByClients: { $ne: req.userId },
      };
      
      if (category) {
        query.category = category;
      }
      
      const offers = await Offer.find(query)
        .populate('buyerId', 'name photoUrl profileImage rating totalBookings successfulDeals')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      const total = await Offer.countDocuments(query);
      
      res.json({
        success: true,
        data: {
          offers,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get all offers error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get offers',
      });
    }
  }

  /**
   * Get my offers (for buyers)
   */
  async getMyOffers(req, res) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      const offers = await Offer.find({ buyerId: req.userId })
        .populate('buyerId', 'name photoUrl profileImage rating totalBookings successfulDeals')
        .populate('acceptedByClientId', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      const total = await Offer.countDocuments({ buyerId: req.userId });
      
      res.json({
        success: true,
        data: {
          offers,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get my offers error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get offers',
      });
    }
  }

  /**
   * Create a new offer (buyer only)
   */
  async createOffer(req, res) {
    try {
      const user = await User.findById(req.userId);
      if (!user || user.role !== 'buyer') {
        return res.status(403).json({
          success: false,
          message: 'Only buyers can create offers',
        });
      }

      const {
        eventName,
        location,
        eventDate,
        quantity,
        category,
        platform,
        cardName,
        offerDetails,
        offerAmount,
        discountPercent: discountPercentInput,
      } = req.body;

      // Calculate discount values (same logic as create request)
      const discountPercent = discountPercentInput !== undefined ? discountPercentInput : 30;
      const discountedPrice = Math.round(offerAmount * (100 - discountPercent) / 100);

      const offer = new Offer({
        buyerId: req.userId,
        eventName,
        location,
        eventDate,
        quantity,
        category,
        platform,
        cardName,
        offerDetails,
        offerAmount,
        discountPercent,
        discountedPrice,
      });

      await offer.save();
      
      // Populate buyer info
      await offer.populate('buyerId', 'name photoUrl profileImage rating totalBookings dealCount');

      res.status(201).json({
        success: true,
        message: 'Offer created successfully',
        data: { offer },
      });
    } catch (error) {
      console.error('Create offer error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to create offer',
      });
    }
  }

  /**
   * Accept an offer (client only)
   */
  async acceptOffer(req, res) {
    try {
      const { offerId } = req.params;
      
      const user = await User.findById(req.userId);
      if (!user || user.role !== 'client') {
        return res.status(403).json({
          success: false,
          message: 'Only clients can accept offers',
        });
      }

      const offer = await Offer.findById(offerId).populate('buyerId');
      if (!offer) {
        return res.status(404).json({
          success: false,
          message: 'Offer not found',
        });
      }

      if (offer.status !== 'active') {
        return res.status(400).json({
          success: false,
          message: 'This offer is no longer available',
        });
      }

      // Update offer status
      offer.status = 'accepted';
      offer.acceptedByClientId = req.userId;
      await offer.save();

      // Calculate pricing using the same logic as create request
      const originalPrice = offer.offerAmount;
      const discountPercent = offer.discountPercent || 30;
      const discountedPrice = offer.discountedPrice || Math.round(originalPrice * (100 - discountPercent) / 100);
      
      // Calculate profit breakdown using wallet service
      const { walletService } = require('../services');
      const profitBreakdown = walletService.calculateProfitBreakdown(
        originalPrice,
        discountedPrice
      );

      // Create a request from this offer with full pricing breakdown
      const request = new Request({
        clientId: req.userId,
        buyerId: offer.buyerId._id,
        eventName: offer.eventName,
        location: offer.location,
        eventDate: offer.eventDate,
        quantity: offer.quantity,
        category: offer.category,
        platform: offer.platform,
        cardName: offer.cardName || 'Not specified',
        offerDetails: offer.offerDetails || '',
        finalAmount: originalPrice,
        originalPrice: originalPrice,
        discountedPrice: discountedPrice,
        buyerPayment: profitBreakdown.buyerPayment,
        clientRefund: profitBreakdown.clientRefund,
        buyerProfit: profitBreakdown.buyerProfit,
        appProfit: profitBreakdown.appProfit,
        status: 'accepted',
      });
      await request.save();

      // Start the timer for the buyer to complete the booking
      await timerService.startTimer(request._id);

      // Notify the buyer
      await notificationService.create(
        offer.buyerId._id,
        'offer_accepted',
        'Offer Accepted!',
        `${user.name} has accepted your offer for ${offer.eventName}. Timer started!`,
        { offerId: offer._id.toString(), requestId: request._id.toString() }
      );

      // Fetch the updated request with timer info
      const updatedRequest = await Request.findById(request._id)
        .populate('clientId', 'name profileImage')
        .populate('buyerId', 'name profileImage');

      res.json({
        success: true,
        message: 'Offer accepted successfully. Timer started!',
        data: { 
          offer,
          request: updatedRequest.toJSON(),
        },
      });
    } catch (error) {
      console.error('Accept offer error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to accept offer',
      });
    }
  }

  /**
   * Reject/Skip an offer (client only - hides it for this client)
   */
  async rejectOffer(req, res) {
    try {
      const { offerId } = req.params;
      
      const offer = await Offer.findById(offerId);
      if (!offer) {
        return res.status(404).json({
          success: false,
          message: 'Offer not found',
        });
      }

      // Add client to rejected list
      if (!offer.rejectedByClients.includes(req.userId)) {
        offer.rejectedByClients.push(req.userId);
        await offer.save();
      }

      res.json({
        success: true,
        message: 'Offer skipped',
      });
    } catch (error) {
      console.error('Reject offer error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to reject offer',
      });
    }
  }

  /**
   * Cancel an offer (buyer only)
   */
  async cancelOffer(req, res) {
    try {
      const { offerId } = req.params;
      
      const offer = await Offer.findById(offerId);
      if (!offer) {
        return res.status(404).json({
          success: false,
          message: 'Offer not found',
        });
      }

      if (offer.buyerId.toString() !== req.userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to cancel this offer',
        });
      }

      if (offer.status === 'accepted') {
        return res.status(400).json({
          success: false,
          message: 'Cannot cancel an accepted offer',
        });
      }

      offer.status = 'cancelled';
      await offer.save();

      res.json({
        success: true,
        message: 'Offer cancelled',
      });
    } catch (error) {
      console.error('Cancel offer error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to cancel offer',
      });
    }
  }

  /**
   * Get a single offer
   */
  async getOffer(req, res) {
    try {
      const { offerId } = req.params;
      
      const offer = await Offer.findById(offerId)
        .populate('buyerId', 'name photoUrl profileImage rating totalBookings successfulDeals');
      
      if (!offer) {
        return res.status(404).json({
          success: false,
          message: 'Offer not found',
        });
      }

      res.json({
        success: true,
        data: { offer },
      });
    } catch (error) {
      console.error('Get offer error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get offer',
      });
    }
  }
}

module.exports = new OfferController();
