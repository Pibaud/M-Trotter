const favorisModel = require('../models/favorisModel');
const jwt = require('jsonwebtoken');

const ACCESS_TOKEN_SECRET = 'votre_secret_access';

exports.addFavorite = async (req, res) => {
    try {
        const { osm_id, accessToken } = req.body;

        if (!osm_id || !accessToken) {
            return res.status(400).json({ error: 'osm_id et accessToken requis' });
        }

        const userId = jwt.verify(accessToken, ACCESS_TOKEN_SECRET).id;

        await favorisModel.addFavorite(userId, osm_id);

        res.status(201).json({ message: 'Lieu ajouté aux favoris' });
    } catch (error) {
        res.status(500).json({ error: 'Erreur lors de l’ajout du favori' });
    }
};

exports.delFavorite = async (req, res) => {
    try {
        const { osm_id, accessToken } = req.body;

        if (!osm_id || !accessToken) {
            return res.status(400).json({ error: 'osm_id et accessToken requis' });
        }

        const userId = jwt.verify(accessToken, ACCESS_TOKEN_SECRET).id;

        await favorisModel.delFavorite(userId, osm_id);

        res.status(200).json({ message: 'Lieu supprimé des favoris' });
    } catch (error) {
        res.status(500).json({ error: 'Erreur lors de la suppression du favori' });
    }
};

exports.getFavorites = async (req, res) => {
    try {
        const {accessToken} = req.body;

        if (!accessToken) {
            return res.status(400).json({ error: 'accessToken requis' });
        }

        const userId = jwt.verify(accessToken, ACCESS_TOKEN_SECRET).id;

        console.log("userId", userId);

        const { rows } = await favorisModel.getFavorites(userId);

        console.log("rows", rows);

        res.status(200).json(rows);
    } catch (error) {
        res.status(500).json({ error: 'Erreur lors de la récupération des favoris', message: error.message });
    }
};
