const { Request, User } = require('../models');
const { walletService, notificationService } = require('../services');

class EscrowController {
  /**
   * Client confirms ticket is valid - release payment to buyer
   */
  async confirmTicket(req, res) {
    try {
      const { id } = req.params;
      const clientId = req.userId;

      const request = await Request.findById(id)
        .populate('buyerId', 'name');

      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }

      if (request.clientId.toString() !== clientId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized',
        });
      }

      if (request.escrow?.status !== 'held') {
        return res.status(400).json({
          success: false,
          message: 'No payment in escrow to release',
        });
      }

      // Complete the request and release payment
      request.status = 'completed';
      request.completedAt = new Date();
      request.escrow.status = 'released';
      request.escrow.releasedAt = new Date();
      await request.save();

      // Complete payment with profit distribution
      const paymentResult = await walletService.completePayment(
        request.clientId,
        request.buyerId._id,
        request
      );

      // Update buyer's successful deals
      await User.findByIdAndUpdate(request.buyerId._id, {
        $inc: { successfulDeals: 1 },
      });

      // Notify buyer
      await notificationService.create(
        request.buyerId._id,
        'payment_released',
        '🎉 Payment Released!',
        `Client confirmed the ticket! ₹${request.buyerPayment} has been added to your wallet. Your profit: ₹${request.buyerProfit}.`,
        { requestId: request._id.toString() }
      );

      // Notify client about their refund
      await notificationService.create(
        request.clientId,
        'ticket_confirmed',
        'Ticket Confirmed',
        `You confirmed the ticket for "${request.eventName}". You saved ₹${request.clientRefund}!`,
        { requestId: request._id.toString() }
      );

      res.json({
        success: true,
        message: 'Ticket confirmed! Payment released to buyer.',
        data: {
          profitBreakdown: paymentResult.profitBreakdown,
        },
      });
    } catch (error) {
      console.error('Confirm ticket error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to confirm ticket',
      });
    }
  }

  /**
   * Client raises dispute
   */
  async raiseDispute(req, res) {
    try {
      const { id } = req.params;
      const { reason } = req.body;
      const clientId = req.userId;

      const request = await Request.findById(id)
        .populate('buyerId', 'name');

      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }

      if (request.clientId.toString() !== clientId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized',
        });
      }

      if (request.escrow?.status !== 'held') {
        return res.status(400).json({
          success: false,
          message: 'Can only dispute when payment is in escrow',
        });
      }

      // Update escrow status to disputed
      request.escrow.status = 'disputed';
      request.dispute = {
        isDisputed: true,
        raisedBy: clientId,
        raisedAt: new Date(),
        reason: reason,
      };
      await request.save();

      // Notify buyer about dispute
      await notificationService.create(
        request.buyerId._id,
        'dispute_raised',
        '⚠️ Dispute Raised',
        `Client has raised a dispute: "${reason}". You can accept refund or reject the dispute if it's false.`,
        { requestId: request._id.toString() }
      );

      res.json({
        success: true,
        message: 'Dispute raised. The buyer will be notified.',
      });
    } catch (error) {
      console.error('Raise dispute error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to raise dispute',
      });
    }
  }

  /**
   * Buyer rejects dispute (claims dispute is false)
   */
  async rejectDispute(req, res) {
    try {
      const { id } = req.params;
      const buyerId = req.userId;

      const request = await Request.findById(id)
        .populate('clientId', 'name');

      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }

      if (request.buyerId.toString() !== buyerId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized',
        });
      }

      if (!request.dispute?.isDisputed) {
        return res.status(400).json({
          success: false,
          message: 'No active dispute found',
        });
      }

      // Complete request and release payment (dispute rejected)
      request.status = 'completed';
      request.completedAt = new Date();
      request.escrow.status = 'released';
      request.escrow.releasedAt = new Date();
      request.dispute.resolved = true;
      request.dispute.resolution = 'dispute_rejected';
      request.dispute.resolvedAt = new Date();
      await request.save();

      // Complete payment
      const paymentResult = await walletService.completePayment(
        request.clientId._id,
        request.buyerId,
        request
      );

      // Update buyer's successful deals
      await User.findByIdAndUpdate(request.buyerId, {
        $inc: { successfulDeals: 1 },
      });

      // Notify client about dispute rejection
      await notificationService.create(
        request.clientId._id,
        'dispute_lost',
        '❌ Dispute Rejected',
        `The buyer rejected your dispute for "${request.eventName}". Payment has been released to the buyer.`,
        { requestId: request._id.toString() }
      );

      // Notify buyer about successful dispute rejection
      await notificationService.create(
        request.buyerId,
        'dispute_resolved',
        '✅ Dispute Rejected Successfully',
        `You rejected the dispute. ₹${request.buyerPayment} has been added to your wallet.`,
        { requestId: request._id.toString() }
      );

      res.json({
        success: true,
        message: 'Dispute rejected. Payment released to your wallet.',
        data: {
          profitBreakdown: paymentResult.profitBreakdown,
        },
      });
    } catch (error) {
      console.error('Reject dispute error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to reject dispute',
      });
    }
  }

  /**
   * Buyer accepts refund (during dispute)
   */
  async acceptRefund(req, res) {
    try {
      const { id } = req.params;
      const buyerId = req.userId;

      const request = await Request.findById(id)
        .populate('clientId', 'name');

      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }

      if (request.buyerId.toString() !== buyerId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized',
        });
      }

      if (!request.dispute?.isDisputed) {
        return res.status(400).json({
          success: false,
          message: 'No active dispute found',
        });
      }

      // Refund client
      await walletService.unfreezePoints(
        request.clientId._id,
        request.originalPrice,
        `Refund for ${request.eventName} (dispute resolved)`,
        request._id
      );

      // Update request
      request.status = 'cancelled';
      request.escrow.status = 'refunded';
      request.dispute.resolved = true;
      request.dispute.resolution = 'client_wins';
      request.dispute.resolvedAt = new Date();
      request.cancellationReason = 'Dispute resolved - buyer accepted refund';
      await request.save();

      // Notify client
      await notificationService.create(
        request.clientId._id,
        'refund_processed',
        'Refund Processed',
        `₹${request.originalPrice} has been refunded for "${request.eventName}".`,
        { requestId: request._id.toString() }
      );

      res.json({
        success: true,
        message: 'Refund processed. Dispute resolved.',
      });
    } catch (error) {
      console.error('Accept refund error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to process refund',
      });
    }
  }

  /**
   * Client accepts buyer's explanation (releases payment)
   */
  async acceptBuyerResponse(req, res) {
    try {
      const { id } = req.params;
      const clientId = req.userId;

      const request = await Request.findById(id)
        .populate('buyerId', 'name');

      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }

      if (request.clientId.toString() !== clientId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized',
        });
      }

      if (!request.dispute?.isDisputed) {
        return res.status(400).json({
          success: false,
          message: 'No active dispute found',
        });
      }

      // Complete request and release payment
      request.status = 'completed';
      request.completedAt = new Date();
      request.escrow.status = 'released';
      request.escrow.releasedAt = new Date();
      request.dispute.resolved = true;
      request.dispute.resolution = 'buyer_wins';
      request.dispute.resolvedAt = new Date();
      await request.save();

      // Complete payment
      const paymentResult = await walletService.completePayment(
        request.clientId,
        request.buyerId._id,
        request
      );

      // Update buyer's successful deals
      await User.findByIdAndUpdate(request.buyerId._id, {
        $inc: { successfulDeals: 1 },
      });

      // Notify buyer
      await notificationService.create(
        request.buyerId._id,
        'dispute_resolved',
        '✅ Dispute Resolved',
        `Client accepted your response! ₹${request.buyerPayment} has been added to your wallet.`,
        { requestId: request._id.toString() }
      );

      res.json({
        success: true,
        message: 'Dispute resolved. Payment released to buyer.',
        data: {
          profitBreakdown: paymentResult.profitBreakdown,
        },
      });
    } catch (error) {
      console.error('Accept buyer response error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to resolve dispute',
      });
    }
  }

  /**
   * Get escrow status for a request
   */
  async getEscrowStatus(req, res) {
    try {
      const { id } = req.params;

      const request = await Request.findById(id)
        .select('escrow verification dispute status')
        .populate('clientId', 'name')
        .populate('buyerId', 'name');

      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }

      res.json({
        success: true,
        data: {
          status: request.status,
          escrow: request.escrow,
          verification: request.verification,
          dispute: request.dispute,
        },
      });
    } catch (error) {
      console.error('Get escrow status error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get escrow status',
      });
    }
  }
}

module.exports = new EscrowController();
