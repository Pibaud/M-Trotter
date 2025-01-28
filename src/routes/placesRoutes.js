const express = require('express');
const router = express.Router();
const { getPlaces, postPlaces, bboxPlaces } = require('../controllers/placesController');

// GET pour récupérer des données
router.get('/places', postPlaces);

// POST pour envoyer des données
router.post('/places/', postPlaces);

router.get('/placesbbox', bboxPlaces);

module.exports = router;