const express = require('express');
const { body } = require('express-validator');
const { requestController } = require('../controllers');
const { auth, requireRole, validate } = require('../middleware');
const { uploadToCloudinary } = require('../config/cloudinary');

const router = express.Router();

// Validation rules
const createRequestValidation = [
  body('eventName')
    .trim()
    .notEmpty()
    .withMessage('Event name is required'),
  body('location')
    .trim()
    .notEmpty()
    .withMessage('Location is required'),
  body('eventDate')
    .notEmpty()
    .withMessage('Event date is required')
    .isISO8601()
    .withMessage('Invalid date format'),
  body('quantity')
    .notEmpty()
    .withMessage('Quantity is required')
    .isInt({ min: 1 })
    .withMessage('Quantity must be at least 1'),
  body('category')
    .notEmpty()
    .withMessage('Category is required')
    .isIn(['Movies', 'Events', 'Sports', 'Live Events', 'Music', 'Shopping', 'Food & Beverages', 'Booking'])
    .withMessage('Invalid category'),
  body('platform')
    .trim()
    .notEmpty()
    .withMessage('Platform is required'),
  body('cardName')
    .trim()
    .notEmpty()
    .withMessage('Card name is required'),
  // Support both new pricing fields and legacy finalAmount
  body('originalPrice')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Original price must be a positive number'),
  body('discountedPrice')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Discounted price must be a positive number'),
  body('finalAmount')
    .optional()
    .isFloat({ min: 0 })
    .withMessage('Final amount must be a positive number'),
  // Custom validation: require either originalPrice or finalAmount
  body().custom((value, { req }) => {
    const { originalPrice, finalAmount } = req.body;
    if (!originalPrice && !finalAmount) {
      throw new Error('Either originalPrice or finalAmount is required');
    }
    return true;
  }),
];

// Routes

// Create request (Client only)
router.post(
  '/',
  auth,
  requireRole('client'),
  createRequestValidation,
  validate,
  requestController.create
);

// Get pending requests (Buyer only)
router.get(
  '/pending',
  auth,
  requireRole('buyer'),
  requestController.getPendingRequests
);

// Get my requests (Client only)
router.get(
  '/my-requests',
  auth,
  requireRole('client'),
  requestController.getMyRequests
);

// Get buyer's accepted requests
router.get(
  '/my-bookings',
  auth,
  requireRole('buyer'),
  requestController.getBuyerRequests
);

// Get request stats
router.get('/stats', auth, requestController.getStats);

// Get single request
router.get('/:id', auth, requestController.getRequest);

// Accept request (Buyer only)
router.post(
  '/:id/accept',
  auth,
  requireRole('buyer'),
  requestController.acceptRequest
);

// Complete request with screenshot (Buyer only)
router.post(
  '/:id/complete',
  auth,
  requireRole('buyer'),
  uploadToCloudinary.single('screenshot'),
  requestController.completeRequest
);

// Cancel request (Client only)
router.post(
  '/:id/cancel',
  auth,
  requireRole('client'),
  requestController.cancelRequest
);

module.exports = router;
