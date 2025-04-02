const express = require('express');
const router = express.Router();
const {getplacesVelos, getplacesPraking} = require('../controllers/tamController');

// POST pour envoyer des données
router.post('/placesvelos', getplacesVelos);
router.post('/placespraking', getplacesPraking);

module.exports = router;