const { Review, Request } = require('../models');
const { notificationService } = require('../services');
const mongoose = require('mongoose');

class ReviewController {
  /**
   * Create review
   */
  async create(req, res) {
    try {
      const { requestId, rating, comment } = req.body;
      
      // Get request
      const request = await Request.findById(requestId)
        .populate('clientId', 'name')
        .populate('buyerId', 'name');
      
      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }
      
      if (request.status !== 'completed') {
        return res.status(400).json({
          success: false,
          message: 'Can only review completed requests',
        });
      }
      
      // Determine reviewee
      const isClient = request.clientId._id.toString() === req.userId.toString();
      const isBuyer = request.buyerId._id.toString() === req.userId.toString();
      
      if (!isClient && !isBuyer) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to review this request',
        });
      }
      
      const revieweeId = isClient ? request.buyerId._id : request.clientId._id;
      
      // Check if already reviewed
      const existingReview = await Review.findOne({
        requestId,
        reviewerId: req.userId,
      });
      
      if (existingReview) {
        return res.status(400).json({
          success: false,
          message: 'You have already reviewed this request',
        });
      }
      
      const review = new Review({
        requestId,
        reviewerId: req.userId,
        revieweeId,
        rating,
        comment,
      });
      await review.save();
      
      // Update request to track client review submission
      if (isClient) {
        await Request.findByIdAndUpdate(requestId, {
          clientReviewSubmitted: true,
          clientReviewId: review._id,
        });
      }
      
      // Notify reviewee
      const reviewerName = isClient ? request.clientId.name : request.buyerId.name;
      await notificationService.notifyNewReview(revieweeId, reviewerName, rating);
      
      res.status(201).json({
        success: true,
        message: 'Review submitted',
        data: { review },
      });
    } catch (error) {
      if (error.code === 11000) {
        return res.status(400).json({
          success: false,
          message: 'You have already reviewed this request',
        });
      }
      
      console.error('Create review error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to create review',
      });
    }
  }

  /**
   * Get reviews for a user
   */
  async getUserReviews(req, res) {
    try {
      const { userId } = req.params;
      const { page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      console.log('Fetching reviews for userId:', userId);
      
      // Validate userId format
      if (!mongoose.Types.ObjectId.isValid(userId)) {
        return res.status(400).json({
          success: false,
          message: 'Invalid user ID format',
        });
      }
      
      // Convert userId to ObjectId for proper querying
      const userObjectId = new mongoose.Types.ObjectId(userId);
      console.log('Converted to ObjectId:', userObjectId);
      
      const reviews = await Review.find({ revieweeId: userObjectId })
        .populate('reviewerId', 'name profileImage')
        .populate('requestId', 'eventName')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      console.log('Found reviews count:', reviews.length);
      
      const total = await Review.countDocuments({ revieweeId: userObjectId });
      
      // Calculate average rating
      const stats = await Review.aggregate([
        { $match: { revieweeId: userObjectId } },
        {
          $group: {
            _id: null,
            avgRating: { $avg: '$rating' },
            count: { $sum: 1 },
          },
        },
      ]);
      
      res.json({
        success: true,
        data: {
          reviews,
          stats: stats[0] || { avgRating: 0, count: 0 },
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get user reviews error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get reviews',
      });
    }
  }

  /**
   * Get my reviews (reviews I've written)
   */
  async getMyReviews(req, res) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      const reviews = await Review.find({ reviewerId: req.userId })
        .populate('revieweeId', 'name profileImage')
        .populate('requestId', 'eventName')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      const total = await Review.countDocuments({ reviewerId: req.userId });
      
      res.json({
        success: true,
        data: {
          reviews,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get my reviews error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get reviews',
      });
    }
  }
}

module.exports = new ReviewController();
