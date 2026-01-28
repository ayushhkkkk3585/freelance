const { Message, Request } = require('../models');
const { notificationService } = require('../services');

class ChatController {
  /**
   * Get messages for a request
   */
  async getMessages(req, res) {
    try {
      const { requestId } = req.params;
      const { page = 1, limit = 50 } = req.query;
      const skip = (parseInt(page) - 1) * parseInt(limit);
      
      // Verify user has access to this request
      const request = await Request.findById(requestId);
      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }
      
      const isClient = request.clientId.toString() === req.userId.toString();
      const isBuyer = request.buyerId && request.buyerId.toString() === req.userId.toString();
      
      if (!isClient && !isBuyer) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to view messages',
        });
      }
      
      const messages = await Message.find({ requestId })
        .populate('senderId', 'name profileImage')
        .sort({ createdAt: 1 })
        .skip(skip)
        .limit(parseInt(limit));
      
      // Mark messages as read
      await Message.updateMany(
        { requestId, receiverId: req.userId, isRead: false },
        { isRead: true }
      );
      
      const total = await Message.countDocuments({ requestId });
      
      res.json({
        success: true,
        data: {
          messages,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            total,
            pages: Math.ceil(total / parseInt(limit)),
          },
        },
      });
    } catch (error) {
      console.error('Get messages error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get messages',
      });
    }
  }

  /**
   * Send message (Buyer only can initiate)
   */
  async sendMessage(req, res) {
    try {
      const { requestId } = req.params;
      const { content, isOffer, offerAmount, discountPercent, discountedPrice } = req.body;
      
      const request = await Request.findById(requestId)
        .populate('clientId', 'name')
        .populate('buyerId', 'name');
      
      if (!request) {
        return res.status(404).json({
          success: false,
          message: 'Request not found',
        });
      }
      
      const isClient = request.clientId._id.toString() === req.userId.toString();
      const isBuyer = request.buyerId && request.buyerId._id.toString() === req.userId.toString();
      
      // Only buyer can send messages, or client can reply after buyer sends first message
      if (!isBuyer && !isClient) {
        return res.status(403).json({
          success: false,
          message: 'Not authorized to send messages',
        });
      }
      
      // If client, check if buyer has sent at least one message
      if (isClient) {
        const buyerMessages = await Message.countDocuments({
          requestId,
          senderId: request.buyerId,
        });
        
        if (buyerMessages === 0) {
          return res.status(403).json({
            success: false,
            message: 'Only buyers can initiate chat',
          });
        }
      }
      
      const receiverId = isClient ? request.buyerId._id : request.clientId._id;
      
      // Calculate discountedPrice if not provided but offerAmount and discountPercent are
      let calculatedDiscountedPrice = discountedPrice;
      if (isOffer && offerAmount && discountPercent !== undefined && !discountedPrice) {
        calculatedDiscountedPrice = Math.round(offerAmount * (100 - discountPercent) / 100);
      }
      
      const message = new Message({
        requestId,
        senderId: req.userId,
        receiverId,
        content,
        isOffer: isOffer || false,
        offerAmount: isOffer ? offerAmount : null,
        discountPercent: isOffer ? (discountPercent !== undefined ? discountPercent : 30) : null,
        discountedPrice: isOffer ? calculatedDiscountedPrice : null,
      });
      await message.save();
      
      // Populate sender info
      await message.populate('senderId', 'name profileImage');
      
      // Notify receiver
      const senderName = isClient ? request.clientId.name : request.buyerId.name;
      await notificationService.notifyNewMessage(receiverId, requestId, senderName);
      
      res.status(201).json({
        success: true,
        message: 'Message sent',
        data: { message },
      });
    } catch (error) {
      console.error('Send message error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to send message',
      });
    }
  }

  /**
   * Get unread message count
   */
  async getUnreadCount(req, res) {
    try {
      const count = await Message.countDocuments({
        receiverId: req.userId,
        isRead: false,
      });
      
      res.json({
        success: true,
        data: { unreadCount: count },
      });
    } catch (error) {
      console.error('Get unread count error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get unread count',
      });
    }
  }

  /**
   * Get all conversations for the user
   */
  async getConversations(req, res) {
    try {
      // Find all requests where user is client or buyer
      const requests = await Request.find({
        $or: [
          { clientId: req.userId },
          { buyerId: req.userId },
        ],
        buyerId: { $exists: true, $ne: null },
      })
        .populate('clientId', 'name profileImage')
        .populate('buyerId', 'name profileImage')
        .sort({ updatedAt: -1 });

      // Get last message and unread count for each conversation
      const conversations = await Promise.all(
        requests.map(async (request) => {
          const lastMessage = await Message.findOne({ requestId: request._id })
            .sort({ createdAt: -1 })
            .select('content createdAt senderId');

          const unreadCount = await Message.countDocuments({
            requestId: request._id,
            receiverId: req.userId,
            isRead: false,
          });

          const otherUser = request.clientId._id.toString() === req.userId.toString()
            ? request.buyerId
            : request.clientId;

          return {
            requestId: request._id,
            eventName: request.eventName,
            otherUser: {
              id: otherUser._id,
              name: otherUser.name,
              profileImage: otherUser.profileImage,
            },
            lastMessage: lastMessage ? {
              content: lastMessage.content,
              createdAt: lastMessage.createdAt,
              isFromMe: lastMessage.senderId.toString() === req.userId.toString(),
            } : null,
            unreadCount,
            updatedAt: lastMessage?.createdAt || request.updatedAt,
          };
        })
      );

      // Filter out conversations with no messages and sort by last message
      const activeConversations = conversations
        .filter(c => c.lastMessage)
        .sort((a, b) => new Date(b.updatedAt) - new Date(a.updatedAt));

      res.json({
        success: true,
        data: { conversations: activeConversations },
      });
    } catch (error) {
      console.error('Get conversations error:', error);
      res.status(500).json({
        success: false,
        message: error.message || 'Failed to get conversations',
      });
    }
  }
}

module.exports = new ChatController();
