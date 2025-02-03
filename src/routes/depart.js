const express = require('express');
const router = express.Router();
const { depart} = require('../controllers/departController');

router.post('/depart', depart);

module.exports = router;