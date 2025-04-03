const express = require('express');
const router = express.Router();
const {getImagesByPlaceId, uploadImage, accessImage} = require('../controllers/uploadController');
const upload = require('../middleware/multerMiddleware'); // Import de Multer
const uploadDir = '/var/www/m-trotter/uploads/';

router.post('/upload', upload.single('file'), uploadImage);
router.post('/image', getImagesByPlaceId);
router.use('/photo', express.static(uploadDir));


module.exports = router;