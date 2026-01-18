const { notificationService } = require('../services');

class NotificationController {
  /**
   * Get notifications
   */
  async getNotifications(req, res) {
    try {
      const { page = 1, limit = 20 } = req.query;
      
      const result = await notificationService.getNotifications(
        req.userId,
        parseInt(page),
        parseInt(limit)
      );
      
      res.json({
        success: true,
        data: result,
      });
    } catch (error) {
      console.error('Get notifications error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get notifications',
      });
    }
  }

  /**
   * Mark notification as read
   */
  async markAsRead(req, res) {
    try {
      const notification = await notificationService.markAsRead(
        req.params.id,
        req.userId
      );
      
      if (!notification) {
        return res.status(404).json({
          success: false,
          message: 'Notification not found',
        });
      }
      
      res.json({
        success: true,
        message: 'Notification marked as read',
        data: { notification },
      });
    } catch (error) {
      console.error('Mark as read error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to mark as read',
      });
    }
  }

  /**
   * Mark all as read
   */
  async markAllAsRead(req, res) {
    try {
      await notificationService.markAllAsRead(req.userId);
      
      res.json({
        success: true,
        message: 'All notifications marked as read',
      });
    } catch (error) {
      console.error('Mark all as read error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to mark all as read',
      });
    }
  }

  /**
   * Delete notification
   */
  async delete(req, res) {
    try {
      await notificationService.delete(req.params.id, req.userId);
      
      res.json({
        success: true,
        message: 'Notification deleted',
      });
    } catch (error) {
      console.error('Delete notification error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to delete notification',
      });
    }
  }

  /**
   * Delete all notifications
   */
  async deleteAll(req, res) {
    try {
      await notificationService.deleteAll(req.userId);
      
      res.json({
        success: true,
        message: 'All notifications deleted',
      });
    } catch (error) {
      console.error('Delete all notifications error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to delete all notifications',
      });
    }
  }
}

module.exports = new NotificationController();
