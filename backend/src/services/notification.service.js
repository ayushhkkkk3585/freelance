const { Notification } = require('../models');

class NotificationService {
  /**
   * Create a notification
   */
  async create(userId, type, title, message, data = {}) {
    // Ensure requestId is stored as string for proper JSON serialization
    const processedData = { ...data };
    if (processedData.requestId) {
      processedData.requestId = processedData.requestId.toString();
    }
    
    const notification = new Notification({
      userId,
      type,
      title,
      message,
      data: processedData,
    });
    await notification.save();
    return notification;
  }

  /**
   * Get notifications for user
   */
  async getNotifications(userId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    
    const notifications = await Notification.find({ userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);
    
    const total = await Notification.countDocuments({ userId });
    const unreadCount = await Notification.countDocuments({ userId, isRead: false });
    
    return {
      notifications,
      unreadCount,
      pagination: {
        page,
        limit,
        total,
        pages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Mark notification as read
   */
  async markAsRead(notificationId, userId) {
    const notification = await Notification.findOneAndUpdate(
      { _id: notificationId, userId },
      { isRead: true },
      { new: true }
    );
    return notification;
  }

  /**
   * Mark all notifications as read
   */
  async markAllAsRead(userId) {
    await Notification.updateMany({ userId, isRead: false }, { isRead: true });
    return { success: true };
  }

  /**
   * Delete notification
   */
  async delete(notificationId, userId) {
    await Notification.findOneAndDelete({ _id: notificationId, userId });
    return { success: true };
  }

  /**
   * Delete all notifications
   */
  async deleteAll(userId) {
    await Notification.deleteMany({ userId });
    return { success: true };
  }

  // Notification type helpers
  async notifyRequestCreated(clientId, requestId, eventName) {
    return this.create(
      clientId,
      'request_created',
      'Request Created',
      `Your request for "${eventName}" has been created and is visible to buyers.`,
      { requestId }
    );
  }

  // Notify all buyers about new request
  async notifyBuyersNewRequest(requestId, eventName, category) {
    const { User } = require('../models');
    const buyers = await User.find({ role: 'buyer', isActive: true }).select('_id');
    
    const notifications = buyers.map(buyer => 
      this.create(
        buyer._id,
        'new_request',
        'New Request Available!',
        `A new ${category} request for "${eventName}" is available. Accept it now!`,
        { requestId }
      )
    );
    
    return Promise.all(notifications);
  }

  async notifyRequestAccepted(clientId, requestId, eventName, buyerName) {
    return this.create(
      clientId,
      'request_accepted',
      'Request Accepted!',
      `${buyerName} has accepted your request for "${eventName}". Booking in progress.`,
      { requestId }
    );
  }

  async notifyRequestCompleted(clientId, requestId, eventName) {
    return this.create(
      clientId,
      'request_completed',
      'Booking Completed!',
      `Your booking for "${eventName}" has been completed. Check your screenshot.`,
      { requestId }
    );
  }

  async notifyRequestTimeout(clientId, requestId, eventName) {
    return this.create(
      clientId,
      'request_timeout',
      'Booking Timeout',
      `The buyer failed to complete your booking for "${eventName}". Points refunded.`,
      { requestId }
    );
  }

  async notifyPointsDeducted(clientId, amount, requestId) {
    return this.create(
      clientId,
      'points_deducted',
      'Points Reserved',
      `₹${amount} points have been reserved for your booking.`,
      { requestId, amount }
    );
  }

  async notifyPointsCredited(userId, amount, requestId) {
    return this.create(
      userId,
      'points_credited',
      'Points Credited!',
      `₹${amount} points have been credited to your wallet.`,
      { requestId, amount }
    );
  }

  async notifyPointsRefunded(clientId, amount, requestId) {
    return this.create(
      clientId,
      'points_refunded',
      'Points Refunded',
      `₹${amount} points have been refunded to your wallet.`,
      { requestId, amount }
    );
  }

  async notifyNewMessage(userId, requestId, senderName) {
    return this.create(
      userId,
      'new_message',
      'New Message',
      `${senderName} sent you a message.`,
      { requestId }
    );
  }

  async notifyNewReview(userId, reviewerName, rating) {
    return this.create(
      userId,
      'new_review',
      'New Review',
      `${reviewerName} gave you a ${rating}-star rating.`,
      { rating }
    );
  }
}

module.exports = new NotificationService();
