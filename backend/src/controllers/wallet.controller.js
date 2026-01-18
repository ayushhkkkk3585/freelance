const { walletService } = require('../services');

class WalletController {
  /**
   * Get wallet balance
   */
  async getBalance(req, res) {
    try {
      const balance = await walletService.getBalance(req.userId);
      
      res.json({
        success: true,
        data: balance,
      });
    } catch (error) {
      console.error('Get balance error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get balance',
      });
    }
  }

  /**
   * Get transaction history
   */
  async getTransactions(req, res) {
    try {
      const { page = 1, limit = 20 } = req.query;
      
      const result = await walletService.getTransactions(
        req.userId,
        parseInt(page),
        parseInt(limit)
      );
      
      res.json({
        success: true,
        data: result,
      });
    } catch (error) {
      console.error('Get transactions error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get transactions',
      });
    }
  }

  /**
   * Add points (for testing/admin)
   */
  async addPoints(req, res) {
    try {
      const { amount } = req.body;
      
      if (!amount || amount <= 0) {
        return res.status(400).json({
          success: false,
          message: 'Valid amount is required',
        });
      }
      
      await walletService.creditPoints(
        req.userId,
        amount,
        'Points added'
      );
      
      const balance = await walletService.getBalance(req.userId);
      
      res.json({
        success: true,
        message: `${amount} points added`,
        data: balance,
      });
    } catch (error) {
      console.error('Add points error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to add points',
      });
    }
  }
}

module.exports = new WalletController();
