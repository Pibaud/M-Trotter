const express = require('express');
const router = express.Router();
const { inscription, connexions, getProfil, updateProfil, refreshToken, logout } = require('../controllers/comptesController');
const authenticateUser = require('../middlewares/authMiddleware');

// Route d'inscription
router.post('/inscription', inscription);

// Route de connexion
router.post('/connexion', connexions);

// Rafraîchissement du token
router.post('/refresh', refreshToken);

// Déconnexion
router.post('/logout', logout);

// Obtenir le profil utilisateur    
router.post('/getProfil', getProfil);

// Mettre à jour le profil utilisateur
router.post('/updateProfil', authenticateUser, updateProfil);

module.exports = router;