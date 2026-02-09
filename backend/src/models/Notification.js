const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    type: {
      type: String,
      enum: [
        // Request types
        'request_created',
        'request_accepted',
        'request_completed',
        'request_cancelled',
        'request_expired',
        'request_timeout',
        'new_request',
        
        // Payment/Wallet types
        'payment_received',
        'payment_sent',
        'wallet_credited',
        'wallet_debited',
        'points_deducted',
        'points_credited',
        'points_refunded',
        
        // Message types
        'message_received',
        'new_message',
        
        // Offer types
        'offer_received',
        'offer_accepted',
        'offer_rejected',
        
        // OCR/Screenshot types
        'screenshot_uploaded',
        'screenshot_pending',
        'screenshot_rejected',
        'ticket_uploaded',
        'ticket_needs_review',
        'ticket_verified',
        'ticket_confirmed',
        
        // Escrow types
        'escrow_held',
        'escrow_released',
        'escrow_auto_released',
        'escrow_verification_required',
        
        // Payment release types
        'payment_released',
        'payment_auto_released',
        
        // Dispute types
        'dispute_raised',
        'dispute_resolved',
        'dispute_auto_resolved',
        'dispute_lost',
        
        // Refund types
        'refund_processed',
        
        // General
        'general',
      ],
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    message: {
      type: String,
      required: true,
    },
    data: {
      type: mongoose.Schema.Types.Mixed,
      default: {},
    },
    isRead: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster queries
notificationSchema.index({ userId: 1, createdAt: -1 });
notificationSchema.index({ userId: 1, isRead: 1 });

module.exports = mongoose.model('Notification', notificationSchema);
