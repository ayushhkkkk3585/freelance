const mongoose = require('mongoose');

const walletSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    balance: {
      type: Number,
      default: 1000, // Client starts with 1000 points
      min: 0,
    },
    frozenAmount: {
      type: Number,
      default: 0,
      min: 0,
    },
    // Buyer earnings tracking
    totalEarnings: {
      type: Number,
      default: 0,
      min: 0,
    },
    totalProfit: {
      type: Number,
      default: 0,
      min: 0,
    },
    // Client savings tracking
    totalSavings: {
      type: Number,
      default: 0,
      min: 0,
    },
    totalRefunds: {
      type: Number,
      default: 0,
      min: 0,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Wallet', walletSchema);
