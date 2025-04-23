const favorisModel = require('../models/favorisModel');
const { fetchImagesByPlaceId } = require('../services/uploadService');  // Ajout de cette importation
const jwt = require('jsonwebtoken');
require('dotenv').config();

exports.addFavorite = async (req, res) => {
    console.log("on est dans le model pour addFavorits");
    try {
        
        const { osm_id, accessToken } = req.body;

        if (!osm_id || !accessToken) {
            return res.status(400).json({ error: 'osm_id et accessToken requis' });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        await favorisModel.addFavorite(user_id, osm_id);

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

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        await favorisModel.delFavorite(user_id, osm_id);

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

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        console.log("userId", user_id);

        const { rows } = await favorisModel.getFavorites(user_id);

        const placesWithPhotos = await Promise.all(rows.map(async (place) => {
            try {
                // Pour chaque lieu, récupérer ses photos
                const photosResult = await fetchImagesByPlaceId(place.id.toString());
                
                // Ajouter les photos au lieu
                return {
                    ...place,
                    photos: photosResult.photos || []
                };
            } catch (error) {
                console.error(`Erreur lors de la récupération des photos pour le lieu ${place.id}:`, error);
                // En cas d'erreur, retourner le lieu sans photos
                return {
                    ...place,
                    photos: []
                };
            }
        }));
        res.status(200).json(placesWithPhotos);
    } catch (error) {
        res.status(500).json({ error: 'Erreur lors de la récupération des favoris', message: error.message });
    }
};
