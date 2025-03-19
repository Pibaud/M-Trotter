const express = require('express');
const router = express.Router();
const favorisController = require('../controllers/favorisController');

router.post('/add', favorisController.addFavorite);
router.post('/delete', favorisController.delFavorite);
router.post('/get', favorisController.getFavorites);

module.exports = router;
