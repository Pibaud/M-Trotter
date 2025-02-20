const express = require('express');
const router = express.Router();
const {getImagesByPlaceId, uploadImage } = require('../controllers/uploadController');

router.post('/upload', uploadImage);
router.post('/image', getImagesByPlaceId);

module.exports = router;