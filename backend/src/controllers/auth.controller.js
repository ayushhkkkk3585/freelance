const jwt = require('jsonwebtoken');
const { User } = require('../models');
const { walletService } = require('../services');

class AuthController {
  /**
   * Register new user
   */
  async register(req, res) {
    try {
      const { name, email, password, phone, role } = req.body;
      
      // Check if user already exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({
          success: false,
          message: 'Email already registered',
        });
      }
      
      // Create user
      const user = new User({
        name,
        email,
        password,
        phone,
        role,
      });
      await user.save();
      
      // Create wallet for client
      if (role === 'client') {
        await walletService.createWallet(user._id, 1000);
      } else {
        await walletService.createWallet(user._id, 0);
      }
      
      // Generate token
      const token = jwt.sign(
        { userId: user._id },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );
      
      res.status(201).json({
        success: true,
        message: 'Registration successful',
        data: {
          user: user.toJSON(),
          token,
        },
      });
    } catch (error) {
      console.error('Registration error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Registration failed',
      });
    }
  }

  /**
   * Login user
   */
  async login(req, res) {
    try {
      const { email, password, role } = req.body;
      
      // Find user with password
      const user = await User.findOne({ email }).select('+password');
      
      if (!user) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password',
        });
      }
      
      // Check password
      const isMatch = await user.comparePassword(password);
      if (!isMatch) {
        return res.status(401).json({
          success: false,
          message: 'Invalid email or password',
        });
      }
      
      // Check role if provided
      if (role && user.role !== role) {
        return res.status(401).json({
          success: false,
          message: `This account is registered as ${user.role}`,
        });
      }
      
      if (!user.isActive) {
        return res.status(401).json({
          success: false,
          message: 'Account is deactivated',
        });
      }
      
      // Generate token
      const token = jwt.sign(
        { userId: user._id },
        process.env.JWT_SECRET,
        { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
      );
      
      res.json({
        success: true,
        message: 'Login successful',
        data: {
          user: user.toJSON(),
          token,
        },
      });
    } catch (error) {
      console.error('Login error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Login failed',
      });
    }
  }

  /**
   * Get current user profile
   */
  async getProfile(req, res) {
    try {
      const wallet = await walletService.getBalance(req.userId);
      
      res.json({
        success: true,
        data: {
          user: req.user.toJSON(),
          wallet,
        },
      });
    } catch (error) {
      console.error('Get profile error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get profile',
      });
    }
  }

  /**
   * Update user profile
   */
  async updateProfile(req, res) {
    try {
      const { name, phone, bio, cardsOwned } = req.body;
      
      const updates = {};
      if (name) updates.name = name;
      if (phone) updates.phone = phone;
      if (bio !== undefined) updates.bio = bio;
      if (cardsOwned && req.user.role === 'buyer') updates.cardsOwned = cardsOwned;
      
      const user = await User.findByIdAndUpdate(req.userId, updates, {
        new: true,
        runValidators: true,
      });
      
      res.json({
        success: true,
        message: 'Profile updated',
        data: { user: user.toJSON() },
      });
    } catch (error) {
      console.error('Update profile error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to update profile',
      });
    }
  }

  /**
   * Change password
   */
  async changePassword(req, res) {
    try {
      const { currentPassword, newPassword } = req.body;
      
      const user = await User.findById(req.userId).select('+password');
      
      const isMatch = await user.comparePassword(currentPassword);
      if (!isMatch) {
        return res.status(400).json({
          success: false,
          message: 'Current password is incorrect',
        });
      }
      
      user.password = newPassword;
      await user.save();
      
      res.json({
        success: true,
        message: 'Password changed successfully',
      });
    } catch (error) {
      console.error('Change password error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to change password',
      });
    }
  }
}

module.exports = new AuthController();
