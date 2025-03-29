const express = require('express');
const router = express.Router();
const { inscription, connexions, getProfil, updateProfil, refreshToken, logout, getOtherProfil} = require('../controllers/comptesController');
const authenticateUser = require('../middleware/authMiddleware');

// Route d'inscription
router.post('/inscription', inscription);

// Route de connexion
router.post('/connexion', connexions);

// Rafraîchissement du token
router.post('/recupAccessToken', refreshToken);

// Déconnexion
router.post('/logout', logout);

// Obtenir le profil utilisateur    
router.post('/getProfil', getProfil);

// Mettre à jour le profil utilisateur
router.post('/updateProfil', updateProfil);

// donner le profil d'un utilisateur
router.post('/getOtherProfil', getOtherProfil)

module.exports = router;