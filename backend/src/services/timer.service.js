const { Request } = require('../models');
const walletService = require('./wallet.service');
const notificationService = require('./notification.service');

// Store active timers in memory
const activeTimers = new Map();

// Timer duration (5 minutes in milliseconds)
const TIMER_DURATION = parseInt(process.env.BOOKING_TIMER_DURATION) || 5 * 60 * 1000;

class TimerService {
  /**
   * Start timer for a request
   */
  async startTimer(requestId) {
    const request = await Request.findById(requestId)
      .populate('clientId', 'name')
      .populate('buyerId', 'name');
    
    if (!request) {
      throw new Error('Request not found');
    }
    
    const now = new Date();
    const expiresAt = new Date(now.getTime() + TIMER_DURATION);
    
    // Update request with timer info
    request.timerStartedAt = now;
    request.timerExpiresAt = expiresAt;
    await request.save();
    
    // Set timeout
    const timeoutId = setTimeout(async () => {
      await this.handleTimeout(requestId);
    }, TIMER_DURATION);
    
    // Store timer reference
    activeTimers.set(requestId.toString(), {
      timeoutId,
      expiresAt,
    });
    
    console.log(`Timer started for request ${requestId}, expires at ${expiresAt}`);
    
    return request;
  }

  /**
   * Cancel timer for a request
   */
  cancelTimer(requestId) {
    const timer = activeTimers.get(requestId.toString());
    
    if (timer) {
      clearTimeout(timer.timeoutId);
      activeTimers.delete(requestId.toString());
      console.log(`Timer cancelled for request ${requestId}`);
    }
  }

  /**
   * Handle timeout when buyer fails to complete booking
   */
  async handleTimeout(requestId) {
    try {
      const request = await Request.findById(requestId)
        .populate('clientId', 'name email')
        .populate('buyerId', 'name email');
      
      if (!request) {
        console.error(`Request ${requestId} not found during timeout handling`);
        return;
      }
      
      // Only handle timeout if request is still in accepted status
      if (request.status !== 'accepted') {
        console.log(`Request ${requestId} is no longer in accepted status, skipping timeout`);
        activeTimers.delete(requestId.toString());
        return;
      }
      
      console.log(`Handling timeout for request ${requestId}`);
      
      // Update request status
      request.status = 'timeout';
      await request.save();
      
      // Refund full frozen amount (originalPrice) to client on timeout
      await walletService.refundPoints(
        request.clientId._id,
        request.originalPrice,
        `Full refund for timeout - ${request.eventName}`,
        requestId
      );
      
      // Notify client
      await notificationService.notifyRequestTimeout(
        request.clientId._id,
        requestId,
        request.eventName
      );
      
      await notificationService.notifyPointsRefunded(
        request.clientId._id,
        request.originalPrice,
        requestId
      );
      
      // Remove timer from active timers
      activeTimers.delete(requestId.toString());
      
      console.log(`Timeout handled for request ${requestId}, points refunded to client`);
    } catch (error) {
      console.error(`Error handling timeout for request ${requestId}:`, error);
    }
  }

  /**
   * Get remaining time for a request
   */
  getRemainingTime(requestId) {
    const timer = activeTimers.get(requestId.toString());
    
    if (!timer) {
      return null;
    }
    
    const remaining = timer.expiresAt - new Date();
    return Math.max(0, remaining);
  }

  /**
   * Restore active timers on server restart
   */
  async restoreActiveTimers() {
    try {
      const acceptedRequests = await Request.find({
        status: 'accepted',
        timerExpiresAt: { $gt: new Date() },
      });
      
      console.log(`Restoring ${acceptedRequests.length} active timers`);
      
      for (const request of acceptedRequests) {
        const remainingTime = request.timerExpiresAt - new Date();
        
        if (remainingTime > 0) {
          const timeoutId = setTimeout(async () => {
            await this.handleTimeout(request._id);
          }, remainingTime);
          
          activeTimers.set(request._id.toString(), {
            timeoutId,
            expiresAt: request.timerExpiresAt,
          });
          
          console.log(`Restored timer for request ${request._id}, ${Math.round(remainingTime / 1000)}s remaining`);
        } else {
          // Timer already expired, handle immediately
          await this.handleTimeout(request._id);
        }
      }
    } catch (error) {
      console.error('Error restoring active timers:', error);
    }
  }
}

module.exports = new TimerService();
