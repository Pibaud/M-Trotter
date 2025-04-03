const express = require('express');
const router = express.Router();
const {getImagesByPlaceId, uploadImage, accessImage} = require('../controllers/uploadController');
const upload = require('../middleware/multerMiddleware'); // Import de Multer


router.post('/upload', upload.single('file'), uploadImage);
router.post('/image', getImagesByPlaceId);


module.exports = router;