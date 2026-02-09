const { Wallet, Transaction } = require('../models');

class WalletService {
  /**
   * Create wallet for new user
   */
  async createWallet(userId, initialBalance = 1000) {
    const wallet = new Wallet({
      userId,
      balance: initialBalance,
    });
    await wallet.save();
    return wallet;
  }

  /**
   * Get wallet by user ID
   */
  async getWallet(userId) {
    let wallet = await Wallet.findOne({ userId });
    
    if (!wallet) {
      wallet = await this.createWallet(userId);
    }
    
    return wallet;
  }

  /**
   * Get wallet balance with earnings/savings info
   */
  async getBalance(userId) {
    const wallet = await this.getWallet(userId);
    return {
      balance: wallet.balance,
      frozenAmount: wallet.frozenAmount,
      availableBalance: wallet.balance - wallet.frozenAmount,
      // Buyer earnings
      totalEarnings: wallet.totalEarnings,
      totalProfit: wallet.totalProfit,
      // Client savings
      totalSavings: wallet.totalSavings,
      totalRefunds: wallet.totalRefunds,
    };
  }

  /**
   * Get earnings summary for buyers
   */
  async getEarningsSummary(userId) {
    const wallet = await this.getWallet(userId);
    const transactions = await Transaction.find({
      userId,
      type: 'buyer_earning',
    }).sort({ createdAt: -1 }).limit(10);
    
    return {
      totalEarnings: wallet.totalEarnings,
      totalProfit: wallet.totalProfit,
      recentTransactions: transactions,
    };
  }

  /**
   * Get savings summary for clients
   */
  async getSavingsSummary(userId) {
    const wallet = await this.getWallet(userId);
    const transactions = await Transaction.find({
      userId,
      type: 'client_refund',
    }).sort({ createdAt: -1 }).limit(10);
    
    return {
      totalSavings: wallet.totalSavings,
      totalRefunds: wallet.totalRefunds,
      recentTransactions: transactions,
    };
  }

  /**
   * Deduct points from wallet
   */
  async deductPoints(userId, amount, description, requestId = null) {
    const wallet = await this.getWallet(userId);
    
    if (wallet.balance < amount) {
      throw new Error('Insufficient balance');
    }
    
    wallet.balance -= amount;
    await wallet.save();
    
    // Create transaction record
    const transaction = new Transaction({
      walletId: wallet._id,
      userId,
      type: 'debit',
      amount,
      description,
      requestId,
      balanceAfter: wallet.balance,
    });
    await transaction.save();
    
    return wallet;
  }

  /**
   * Credit points to wallet
   */
  async creditPoints(userId, amount, description, requestId = null) {
    const wallet = await this.getWallet(userId);
    
    wallet.balance += amount;
    await wallet.save();
    
    // Create transaction record
    const transaction = new Transaction({
      walletId: wallet._id,
      userId,
      type: 'credit',
      amount,
      description,
      requestId,
      balanceAfter: wallet.balance,
    });
    await transaction.save();
    
    return wallet;
  }

  /**
   * Freeze points (when buyer accepts request)
   */
  async freezePoints(userId, amount, description, requestId = null) {
    const wallet = await this.getWallet(userId);
    
    const availableBalance = wallet.balance - wallet.frozenAmount;
    if (availableBalance < amount) {
      throw new Error('Insufficient available balance');
    }
    
    wallet.frozenAmount += amount;
    await wallet.save();
    
    // Create transaction record
    const transaction = new Transaction({
      walletId: wallet._id,
      userId,
      type: 'freeze',
      amount,
      description,
      requestId,
      balanceAfter: wallet.balance,
    });
    await transaction.save();
    
    return wallet;
  }

  /**
   * Unfreeze points (when booking completes or times out)
   */
  async unfreezePoints(userId, amount, description = 'Points unfrozen', requestId = null) {
    const wallet = await this.getWallet(userId);
    
    wallet.frozenAmount = Math.max(0, wallet.frozenAmount - amount);
    await wallet.save();
    
    // Create transaction record
    const transaction = new Transaction({
      walletId: wallet._id,
      userId,
      type: 'unfreeze',
      amount,
      description,
      requestId,
      balanceAfter: wallet.balance,
    });
    await transaction.save();
    
    return wallet;
  }

  /**
   * Refund points (unfreeze + return to balance)
   */
  async refundPoints(userId, amount, description, requestId = null) {
    const wallet = await this.getWallet(userId);
    
    // First unfreeze
    wallet.frozenAmount = Math.max(0, wallet.frozenAmount - amount);
    await wallet.save();
    
    // Create refund transaction
    const transaction = new Transaction({
      walletId: wallet._id,
      userId,
      type: 'refund',
      amount,
      description,
      requestId,
      balanceAfter: wallet.balance,
    });
    await transaction.save();
    
    return wallet;
  }

  /**
   * Complete payment with profit logic
   * 
   * PROFIT DISTRIBUTION:
   * - Client pays: originalPrice (e.g., 1000 points) → gets frozen
   * - Buyer receives: buyerPayment (e.g., 800 points = 80% of original)
   * - Client refund: clientRefund (e.g., 200 points = 20% of original)
   * - App profit: appProfit (e.g., 200 points = originalPrice - buyerPayment)
   * 
   * BUYER PROFIT:
   * - Buyer earns: buyerPayment - discountedPrice (e.g., 800 - 700 = 100 points)
   */
  async completePayment(clientId, buyerId, request) {
    const { 
      _id: requestId,
      originalPrice, 
      buyerPayment, 
      clientRefund, 
      buyerProfit,
      appProfit,
      eventName 
    } = request;

    const clientWallet = await this.getWallet(clientId);
    const buyerWallet = await this.getWallet(buyerId);
    
    // 1. Unfreeze client's frozen amount
    clientWallet.frozenAmount = Math.max(0, clientWallet.frozenAmount - originalPrice);
    
    // 2. Deduct the actual payment from client (originalPrice - clientRefund = what app keeps + buyer payment)
    const clientDeduction = originalPrice - clientRefund;
    clientWallet.balance -= clientDeduction;
    clientWallet.totalSavings += clientRefund;
    clientWallet.totalRefunds += clientRefund;
    await clientWallet.save();
    
    // 3. Credit refund to client (the 200 points they save)
    const clientRefundTransaction = new Transaction({
      walletId: clientWallet._id,
      userId: clientId,
      type: 'client_refund',
      amount: clientRefund,
      description: `Refund savings for "${eventName}"`,
      requestId,
      balanceAfter: clientWallet.balance + clientRefund,
    });
    await clientRefundTransaction.save();
    
    // Actually add refund to client balance
    clientWallet.balance += clientRefund;
    await clientWallet.save();
    
    // Create debit transaction for client (showing payment made)
    const clientDebitTransaction = new Transaction({
      walletId: clientWallet._id,
      userId: clientId,
      type: 'debit',
      amount: originalPrice - clientRefund,
      description: `Payment for "${eventName}" (saved ₹${clientRefund})`,
      requestId,
      balanceAfter: clientWallet.balance,
    });
    await clientDebitTransaction.save();
    
    // 4. Credit buyer payment (800 points)
    buyerWallet.balance += buyerPayment;
    buyerWallet.totalEarnings += buyerPayment;
    buyerWallet.totalProfit += buyerProfit;
    await buyerWallet.save();
    
    // Create buyer earning transaction
    const buyerEarningTransaction = new Transaction({
      walletId: buyerWallet._id,
      userId: buyerId,
      type: 'buyer_earning',
      amount: buyerPayment,
      description: `Earned for completing "${eventName}" (Profit: ₹${buyerProfit})`,
      requestId,
      balanceAfter: buyerWallet.balance,
    });
    await buyerEarningTransaction.save();
    
    // 5. Record app profit (for analytics - not stored in any wallet)
    const appProfitTransaction = new Transaction({
      walletId: clientWallet._id, // Associate with client for tracking
      userId: clientId,
      type: 'app_profit',
      amount: appProfit,
      description: `App commission for "${eventName}"`,
      requestId,
      balanceAfter: clientWallet.balance,
    });
    await appProfitTransaction.save();
    
    return { 
      clientWallet, 
      buyerWallet,
      profitBreakdown: {
        clientPaid: originalPrice,
        clientRefund,
        clientNetPayment: originalPrice - clientRefund,
        buyerEarned: buyerPayment,
        buyerProfit,
        appProfit,
      }
    };
  }

  /**
   * Calculate profit breakdown for a request
   * @param {Number} originalPrice - Original ticket price (what client pays)
   * @param {Number} discountedPrice - What buyer actually pays for ticket
   * @param {Number} buyerPaymentPercentage - Percentage of original price paid to buyer (default 80%)
   * @param {Number} clientRefundPercentage - Percentage of original price refunded to client (default 20%)
   */
  calculateProfitBreakdown(originalPrice, discountedPrice, buyerPaymentPercentage = 80, clientRefundPercentage = 20) {
    const buyerPayment = Math.round(originalPrice * buyerPaymentPercentage / 100);
    const clientRefund = Math.round(originalPrice * clientRefundPercentage / 100);
    const buyerProfit = buyerPayment - discountedPrice;
    const appProfit = originalPrice - buyerPayment;
    
    return {
      originalPrice,
      discountedPrice,
      buyerPayment,
      clientRefund,
      buyerProfit,
      appProfit,
    };
  }

  /**
   * Get transaction history
   */
  async getTransactions(userId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    
    const transactions = await Transaction.find({ userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .populate('requestId', 'eventName');
    
    const total = await Transaction.countDocuments({ userId });
    
    return {
      transactions,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }
}

module.exports = new WalletService();
