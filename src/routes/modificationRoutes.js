const express = require('express');
const router = express.Router();
const modificationsController = require('../controllers/modificationsController');

router.post('/', modificationsController.proposerModification);
router.post('/nearby', modificationsController.lieuxATesterProches);


module.exports = router;
