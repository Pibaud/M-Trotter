const express = require('express');
const router = express.Router();
const {getImagesByPlaceId, uploadImage, getImagesById} = require('../controllers/uploadController');
const upload = require('../middleware/multerMiddleware'); // Import de Multer

router.post('/upload', upload.single('file'), uploadImage);
router.post('/image', getImagesByPlaceId);
router.post('/getImagesByName', getImagesById);

module.exports = router;