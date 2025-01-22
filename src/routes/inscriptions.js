const express = require('express');
const router = express.Router();
const { inscription} = require('../controllers/comptesController');
// Définition de la route pour calculer un itinéraire
router.post('/inscription', inscription);

module.exports = router;