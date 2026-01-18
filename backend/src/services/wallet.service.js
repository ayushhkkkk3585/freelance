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
   * Get wallet balance
   */
  async getBalance(userId) {
    const wallet = await this.getWallet(userId);
    return {
      balance: wallet.balance,
      frozenAmount: wallet.frozenAmount,
      availableBalance: wallet.balance - wallet.frozenAmount,
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
  async unfreezePoints(userId, amount, requestId = null) {
    const wallet = await this.getWallet(userId);
    
    wallet.frozenAmount = Math.max(0, wallet.frozenAmount - amount);
    await wallet.save();
    
    // Create transaction record
    const transaction = new Transaction({
      walletId: wallet._id,
      userId,
      type: 'unfreeze',
      amount,
      description: 'Points unfrozen',
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
   * Complete payment (deduct frozen amount)
   */
  async completePayment(clientId, buyerId, amount, requestId) {
    const clientWallet = await this.getWallet(clientId);
    
    // Unfreeze from client
    clientWallet.frozenAmount = Math.max(0, clientWallet.frozenAmount - amount);
    clientWallet.balance -= amount;
    await clientWallet.save();
    
    // Credit to buyer
    await this.creditPoints(buyerId, amount, 'Payment for completed booking', requestId);
    
    // Create debit transaction for client
    const transaction = new Transaction({
      walletId: clientWallet._id,
      userId: clientId,
      type: 'debit',
      amount,
      description: 'Payment for completed booking',
      requestId,
      balanceAfter: clientWallet.balance,
    });
    await transaction.save();
    
    return { clientWallet };
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
