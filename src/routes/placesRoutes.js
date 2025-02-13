const express = require('express');
const router = express.Router();
const { getPlaces, postPlaces, bboxPlaces } = require('../controllers/placesController');

// POST pour envoyer des données
router.post('/places/', postPlaces);

router.post('/placesbbox', bboxPlaces);

module.exports = router;