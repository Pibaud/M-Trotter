const express = require('express');
const router = express.Router();
const { calculateRoute } = require('../controllers/routeController');

// Endpoint pour les itinéraires
router.get('/route', calculateRoute);

module.exports = router;
