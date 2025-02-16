const express = require('express');
const router = express.Router();
const {getImage, uploadImage } = require('../controllers/uploadController');

router.post('/upload', uploadImage);
router.post('/image', getImage);


module.exports = router;