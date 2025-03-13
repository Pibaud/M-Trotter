const express = require('express');
const router = express.Router();
const { postPlaces, bboxPlaces, amenitylist, bestPlaces} = require('../controllers/placesController');

// POST pour envoyer des données
router.post('/places/', postPlaces);

router.post('/placesbbox', bboxPlaces);

router.post('/amenitylist/',amenitylist);

router.post('/bestplaces/',bestPlaces);

module.exports = router;