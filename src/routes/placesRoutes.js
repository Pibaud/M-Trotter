const express = require('express');
const router = express.Router();
const { postPlaces, bboxPlaces, amenitylist} = require('../controllers/placesController');

// POST pour envoyer des données
router.post('/places/', postPlaces);

router.post('/placesbbox', bboxPlaces);

router.post('/amenitylist/',amenitylist);

module.exports = router;