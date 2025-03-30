const express = require('express');
const router = express.Router();
const {getplacesVelos} = require('../controllers/tamController');

// POST pour envoyer des données
router.post('/placesvelos', getplacesVelos);

module.exports = router;