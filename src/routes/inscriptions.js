const express = require('express');
const router = express.Router();
const { inscription} = require('../controllers/comptesController');

router.get('/inscription', inscription);

router.post('/inscription', inscription);

module.exports = router;