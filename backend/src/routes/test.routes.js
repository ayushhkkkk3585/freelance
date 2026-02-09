const express = require('express');
const router = express.Router();
const ticketVerificationService = require('../services/ticketVerification.service');
const upload = require('../middleware/upload.middleware');

/**
 * Test OCR endpoint - for development testing only
 * Upload an image and get OCR extraction results
 */
router.post('/ocr', upload.single('screenshot'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided. Use form-data with key "screenshot"',
      });
    }

    const imagePath = req.file.path;
    console.log('Testing OCR on image:', imagePath);

    const result = await ticketVerificationService.testOCR(imagePath);

    res.json({
      success: true,
      message: 'OCR extraction completed',
      data: {
        imagePath,
        confidence: result.confidence,
        extractedData: result.extracted,
        rawText: result.text?.substring(0, 1000), // First 1000 chars
        fullTextLength: result.text?.length || 0,
      },
    });
  } catch (error) {
    console.error('OCR test error:', error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

/**
 * Test verification against a mock request
 */
router.post('/verify', upload.single('screenshot'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No image file provided',
      });
    }

    // Create mock request from body
    const mockRequest = {
      _id: 'test-request-id',
      originalPrice: parseFloat(req.body.expectedAmount) || 500,
      finalAmount: parseFloat(req.body.expectedAmount) || 500,
      eventName: req.body.eventName || 'Test Event',
    };

    const imagePath = req.file.path;
    console.log('Testing verification with mock request:', mockRequest);

    const result = await ticketVerificationService.verifyTicket(imagePath, mockRequest);

    res.json({
      success: true,
      message: 'Verification completed',
      data: {
        imagePath,
        approved: result.approved,
        autoRejected: result.autoRejected,
        rejectReason: result.rejectReason,
        warnings: result.warnings,
        confidence: result.confidence,
        extractedData: {
          bookingId: result.extractedData.bookingId,
          amount: result.extractedData.amount,
          date: result.extractedData.date,
          time: result.extractedData.time,
          platform: result.extractedData.platform,
        },
      },
    });
  } catch (error) {
    console.error('Verification test error:', error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

/**
 * Check if a booking ID exists in the database
 */
router.get('/check-booking/:bookingId', async (req, res) => {
  try {
    const { bookingId } = req.params;
    const result = await ticketVerificationService.isBookingIdDuplicate(bookingId);

    res.json({
      success: true,
      data: {
        bookingId,
        isDuplicate: result.isDuplicate,
        usedBy: result.usedBy || null,
        usedAt: result.usedAt || null,
      },
    });
  } catch (error) {
    console.error('Check booking error:', error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

// Debug route to check buyer's bookings
const { Request } = require('../models');
router.get('/debug/bookings/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    // Find all requests where this user is the buyer
    const buyerRequests = await Request.find({ buyerId: userId })
      .select('eventName status buyerId clientId createdAt')
      .sort({ createdAt: -1 });
    
    // Find all requests to see total
    const allRequests = await Request.find({})
      .select('eventName status buyerId clientId createdAt')
      .sort({ createdAt: -1 })
      .limit(20);
    
    res.json({
      success: true,
      data: {
        userId,
        buyerRequestsCount: buyerRequests.length,
        buyerRequests,
        recentRequestsSample: allRequests.map(r => ({
          id: r._id,
          eventName: r.eventName,
          status: r.status,
          buyerId: r.buyerId,
          clientId: r.clientId,
        })),
      },
    });
  } catch (error) {
    console.error('Debug bookings error:', error);
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
});

module.exports = router;
