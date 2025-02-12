const express = require('express');
const router = express.Router();
const { postAvis, getAvisByPlaceId, deleteAvis } = require('../controllers/avisController');

router.post('/postavis', postAvis);
router.post('/getavis', getAvisByPlaceId); // On recherche maintenant par place_id
router.post('/deleteavis', deleteAvis); // Route pour supprimer un avi

module.exports = router;
