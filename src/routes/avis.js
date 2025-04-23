const express = require('express');
const router = express.Router();
const { postAvis, getAvisByPlaceId, deleteAvis, likeAvis, unlikeAvis, getAvisbyUser } = require('../controllers/avisController');
const upload = require('../middleware/multerMiddleware'); // Import de Multer

router.post('/postavis', upload.single('photo'), postAvis);
router.post('/getavis', getAvisByPlaceId); // On recherche maintenant par place_id
router.post('/mesavis', getAvisbyUser); // On recherche les avis d'un utilisateur
router.post('/deleteavis', deleteAvis); // Route pour supprimer un avi

router.post('/likeavis', likeAvis); // Route pour liker un avis
router.post('/unlikeavis', unlikeAvis); // Route pour unliker un avis

module.exports = router;