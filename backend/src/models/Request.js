const mongoose = require('mongoose');

const requestSchema = new mongoose.Schema(
  {
    clientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    buyerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    eventName: {
      type: String,
      required: [true, 'Event name is required'],
      trim: true,
    },
    location: {
      type: String,
      required: [true, 'Location is required'],
      trim: true,
    },
    eventDate: {
      type: Date,
      required: [true, 'Event date is required'],
    },
    quantity: {
      type: Number,
      required: [true, 'Quantity is required'],
      min: 1,
    },
    category: {
      type: String,
      enum: ['Movies', 'Events', 'Sports', 'Live Events', 'Music', 'Shopping', 'Food & Beverages', 'Booking'],
      required: [true, 'Category is required'],
    },
    platform: {
      type: String,
      required: [true, 'Platform is required'],
      trim: true,
    },
    cardName: {
      type: String,
      required: [true, 'Card name is required'],
      trim: true,
    },
    offerDetails: {
      type: String,
      trim: true,
      default: '',
    },
    finalAmount: {
      type: Number,
      required: [true, 'Final amount is required'],
      min: 0,
    },
    // Pricing breakdown for profit logic
    originalPrice: {
      type: Number,
      required: [true, 'Original price is required'],
      min: 0,
    },
    discountedPrice: {
      type: Number,
      required: [true, 'Discounted price is required'],
      min: 0,
    },
    buyerPayment: {
      type: Number,
      default: 0, // Calculated: 80% of originalPrice
    },
    clientRefund: {
      type: Number,
      default: 0, // Calculated: 20% of originalPrice
    },
    buyerProfit: {
      type: Number,
      default: 0, // Calculated: buyerPayment - discountedPrice
    },
    appProfit: {
      type: Number,
      default: 0, // Calculated: originalPrice - buyerPayment
    },
    eventUrl: {
      type: String,
      trim: true,
      default: '',
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'completed', 'rejected', 'timeout', 'cancelled'],
      default: 'pending',
    },
    // Client review tracking
    clientReviewSubmitted: {
      type: Boolean,
      default: false,
    },
    clientReviewId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Review',
      default: null,
    },
    screenshotUrl: {
      type: String,
      default: null,
    },
    timerStartedAt: {
      type: Date,
      default: null,
    },
    timerExpiresAt: {
      type: Date,
      default: null,
    },
    completedAt: {
      type: Date,
      default: null,
    },
    cancellationReason: {
      type: String,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for faster queries
requestSchema.index({ clientId: 1, status: 1 });
requestSchema.index({ buyerId: 1, status: 1 });
requestSchema.index({ status: 1, category: 1 });
requestSchema.index({ timerExpiresAt: 1 }, { sparse: true });

// Virtual for checking if timer is active
requestSchema.virtual('isTimerActive').get(function () {
  if (!this.timerExpiresAt) return false;
  return new Date() < this.timerExpiresAt;
});

// Virtual for remaining time in seconds
requestSchema.virtual('remainingSeconds').get(function () {
  if (!this.timerExpiresAt) return 0;
  const remaining = this.timerExpiresAt - new Date();
  return Math.max(0, Math.floor(remaining / 1000));
});

requestSchema.set('toJSON', { virtuals: true });
requestSchema.set('toObject', { virtuals: true });

module.exports = mongoose.model('Request', requestSchema);
