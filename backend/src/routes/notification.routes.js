const express = require('express');
const { notificationController } = require('../controllers');
const { auth } = require('../middleware');

const router = express.Router();

// Routes
router.get('/', auth, notificationController.getNotifications);
router.put('/:id/read', auth, notificationController.markAsRead);
router.put('/read-all', auth, notificationController.markAllAsRead);
router.delete('/:id', auth, notificationController.delete);
router.delete('/', auth, notificationController.deleteAll);

module.exports = router;
