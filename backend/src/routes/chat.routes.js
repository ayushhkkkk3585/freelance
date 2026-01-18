const express = require('express');
const { body } = require('express-validator');
const { chatController } = require('../controllers');
const { auth, validate } = require('../middleware');

const router = express.Router();

// Validation rules
const sendMessageValidation = [
  body('content')
    .trim()
    .notEmpty()
    .withMessage('Message content is required')
    .isLength({ max: 1000 })
    .withMessage('Message cannot exceed 1000 characters'),
];

// Routes
router.get('/unread-count', auth, chatController.getUnreadCount);
router.get('/conversations', auth, chatController.getConversations);
router.get('/:requestId', auth, chatController.getMessages);
router.post(
  '/:requestId',
  auth,
  sendMessageValidation,
  validate,
  chatController.sendMessage
);

module.exports = router;
