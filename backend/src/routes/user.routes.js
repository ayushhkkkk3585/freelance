const express = require('express');
const { userController } = require('../controllers');
const { auth } = require('../middleware');

const router = express.Router();

// Routes
router.get('/buyers', auth, userController.getBuyers);
router.get('/:id', auth, userController.getUser);

module.exports = router;
