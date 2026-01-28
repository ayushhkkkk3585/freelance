const mongoose = require('mongoose');

const offerSchema = new mongoose.Schema(
  {
    buyerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
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
      default: 1,
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
      trim: true,
      default: null,
    },
    offerDetails: {
      type: String,
      trim: true,
      default: null,
    },
    offerAmount: {
      type: Number,
      required: [true, 'Offer amount is required'],
      min: 0,
    },
    discountPercent: {
      type: Number,
      default: 30,
      min: 0,
      max: 100,
    },
    discountedPrice: {
      type: Number,
      default: null,
      min: 0,
    },
    status: {
      type: String,
      enum: ['active', 'accepted', 'expired', 'cancelled'],
      default: 'active',
    },
    acceptedByClientId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    // Track clients who rejected/skipped this offer
    rejectedByClients: [{
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
    }],
    expiresAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Index for faster queries
offerSchema.index({ buyerId: 1, status: 1 });
offerSchema.index({ status: 1, category: 1 });
offerSchema.index({ status: 1, createdAt: -1 });

module.exports = mongoose.model('Offer', offerSchema);
