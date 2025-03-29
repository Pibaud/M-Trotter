const express = require('express');
const router = express.Router();
const lieuxController = require('../controllers/lieuxController');

router.post('/ajouter', lieuxController.ajouterLieu);
router.post('/supprimer', lieuxController.supprimerLieu);
router.post('/voterajout', lieuxController.voterAjout);
router.post('/votersuppr', lieuxController.voterSuppression);

module.exports = router;