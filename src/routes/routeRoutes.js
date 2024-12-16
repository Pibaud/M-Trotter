const express = require('express');
const router = express.Router();
const routeController = require('../controllers/routeController');

// Définition de la route pour calculer un itinéraire
router.get('/route', routeController.calculateRoute);

module.exports = router;
