const express = require('express');
const router = express.Router();
const { getPlaces, postPlaces } = require('../controllers/placesController');

// GET pour récupérer des données
router.get('/places/', getPlaces);

// POST pour envoyer des données
router.post('/places/', postPlaces);

module.exports = router;