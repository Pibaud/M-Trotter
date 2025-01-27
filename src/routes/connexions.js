const express = require('express');
const router = express.Router();
const { connexions} = require('../controllers/comptesController');

router.get('/connexion', connexions);

router.post('/connexion', connexions);

module.exports = router;