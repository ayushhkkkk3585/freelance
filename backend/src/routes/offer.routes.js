const express = require('express');
const { offerController } = require('../controllers');
const { auth } = require('../middleware');

const router = express.Router();

// Get all active offers (clients browse)
router.get('/', auth, offerController.getAllOffers);

// Get my offers (buyers view their own)
router.get('/my-offers', auth, offerController.getMyOffers);

// Get single offer
router.get('/:offerId', auth, offerController.getOffer);

// Create offer (buyer only)
router.post('/', auth, offerController.createOffer);

// Accept offer (client only)
router.post('/:offerId/accept', auth, offerController.acceptOffer);

// Reject/skip offer (client only)
router.post('/:offerId/reject', auth, offerController.rejectOffer);

// Cancel offer (buyer only)
router.delete('/:offerId', auth, offerController.cancelOffer);

module.exports = router;
