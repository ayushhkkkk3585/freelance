const express = require('express');
const { walletController } = require('../controllers');
const { auth } = require('../middleware');

const router = express.Router();

// Routes
router.get('/balance', auth, walletController.getBalance);
router.get('/transactions', auth, walletController.getTransactions);
router.post('/add-points', auth, walletController.addPoints);

module.exports = router;
