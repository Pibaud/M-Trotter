const express = require('express');
const router = express.Router();
const { postPlaces, bboxPlaces, amenitylist, bestPlaces, addRecPhoto, delRecPhoto, alreadyRecPhoto, getPlaceById} = require('../controllers/placesController');

// POST pour envoyer des données
router.post('/places/', postPlaces);

router.post('/placesbbox', bboxPlaces);

router.post('/amenitylist/',amenitylist);

router.post('/bestplaces/',bestPlaces);

router.post('/addRecPhoto', addRecPhoto);

router.post('/delRecPhoto', delRecPhoto);

router.post('/alreadyRecPhoto', alreadyRecPhoto);

router.post('/getPlace', getPlaceById);

module.exports = router;