const express = require('express');
const { body } = require('express-validator');
const { reviewController } = require('../controllers');
const { auth, validate } = require('../middleware');

const router = express.Router();

// Validation rules
const createReviewValidation = [
  body('requestId')
    .notEmpty()
    .withMessage('Request ID is required')
    .isMongoId()
    .withMessage('Invalid request ID'),
  body('rating')
    .notEmpty()
    .withMessage('Rating is required')
    .isInt({ min: 1, max: 5 })
    .withMessage('Rating must be between 1 and 5'),
  body('comment')
    .optional()
    .trim()
    .isLength({ max: 500 })
    .withMessage('Comment cannot exceed 500 characters'),
];

// Routes
router.post('/', auth, createReviewValidation, validate, reviewController.create);
router.get('/my-reviews', auth, reviewController.getMyReviews);
router.get('/user/:userId', auth, reviewController.getUserReviews);

module.exports = router;
