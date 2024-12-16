const express = require('express');
const router = express.Router();
const { getData, postData } = require('../controllers/dataController');

// GET pour récupérer des données
router.get('/', getData);

// POST pour envoyer des données
router.post('/', postData);

module.exports = router;