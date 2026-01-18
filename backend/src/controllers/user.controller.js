const { User } = require('../models');

class UserController {
  /**
   * Get user by ID
   */
  async getUser(req, res) {
    try {
      const user = await User.findById(req.params.id);
      
      if (!user) {
        return res.status(404).json({
          success: false,
          message: 'User not found',
        });
      }
      
      res.json({
        success: true,
        data: { user: user.toJSON() },
      });
    } catch (error) {
      console.error('Get user error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get user',
      });
    }
  }

  /**
   * Get all buyers (for admin/testing)
   */
  async getBuyers(req, res) {
    try {
      const { page = 1, limit = 20 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      const buyers = await User.find({ role: 'buyer', isActive: true })
        .sort({ rating: -1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      const total = await User.countDocuments({ role: 'buyer', isActive: true });
      
      res.json({
        success: true,
        data: {
          buyers,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get buyers error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get buyers',
      });
    }
  }

  /**
   * Update profile image
   */
  async updateProfileImage(req, res) {
    try {
      if (!req.file) {
        return res.status(400).json({
          success: false,
          message: 'No image file provided',
        });
      }
      
      const imageUrl = `/uploads/profiles/${req.file.filename}`;
      
      const user = await User.findByIdAndUpdate(
        req.userId,
        { profileImage: imageUrl },
        { new: true }
      );
      
      res.json({
        success: true,
        message: 'Profile image updated',
        data: { user: user.toJSON() },
      });
    } catch (error) {
      console.error('Update profile image error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to update profile image',
      });
    }
  }
}

module.exports = new UserController();
