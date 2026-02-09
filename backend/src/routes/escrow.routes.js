const express = require('express');
const router = express.Router();
const escrowController = require('../controllers/escrow.controller');
const { auth } = require('../middleware/auth.middleware');

// All routes require authentication
router.use(auth);

// Get escrow status
router.get('/:id/status', escrowController.getEscrowStatus);

// Client confirms ticket is valid - release payment
router.post('/:id/confirm', escrowController.confirmTicket);

// Client raises dispute
router.post('/:id/dispute', escrowController.raiseDispute);

// Buyer accepts refund (during dispute)
router.post('/:id/accept-refund', escrowController.acceptRefund);

// Buyer rejects dispute (claims dispute is false)
router.post('/:id/reject-dispute', escrowController.rejectDispute);

// Client accepts buyer's response (during dispute)
router.post('/:id/accept-buyer-response', escrowController.acceptBuyerResponse);

module.exports = router;
