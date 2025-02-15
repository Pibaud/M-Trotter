const express = require('express');
const router = express.Router();
const { postPlaces, bboxPlaces } = require('../controllers/placesController');

// POST pour envoyer des données
router.post('/places/', postPlaces);

router.post('/placesbbox', bboxPlaces);

module.exports = router;