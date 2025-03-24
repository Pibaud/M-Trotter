const express = require('express');
const router = express.Router();
const modificationsController = require('../controllers/modificationsController');

router.post('/', modificationsController.proposerModification);
router.post('/nearby', modificationsController.lieuxATesterProches);
router.post('/vote', modificationsController.voterModification);


module.exports = router;
