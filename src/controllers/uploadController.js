const { user } = require('pg/lib/defaults');
const uploadService = require('../services/uploadService');
const jwt = require('jsonwebtoken');
require('dotenv').config();

const uploadImage = async (req, res) => {
    console.log("Requête reçue :", req.body);  // 🔍 Vérifier ce qui arrive
    console.log("Fichier reçu :", req.file);  // 📸 Vérifier le fichier
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'Aucun fichier reçu' });
        }

        const { id_lieu, id_avis } = req.body;
        const filePath = req.file.path;

        if (!id_lieu) {
            return res.status(400).json({ error: 'id_lieu est obligatoire' });
        }

        const id_avi = id_avis && id_avis !== "null" ? id_avis : null;


        const result = await uploadService.processAndUploadImage(filePath, id_lieu, id_avi);
        res.status(201).json({ result });
    } catch (error) {
        console.error("Erreur lors de l'upload :", error);
        res.status(500).json({ error: 'Erreur serveur dans uploadController' });
    }
};



// Récupérer les images par id_lieu
const getImagesByPlaceId = async (req, res) => {
    try {
        const { place_id, accessToken } = req.body;
        if (!place_id || isNaN(place_id) || !accessToken) {
            return res.status(400).json({ error: "L'identifiant du lieu est requis et doit être un nombre. ou il n'y a pas d'accessToken" });
        }
        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }
        const photos = await uploadService.fetchImagesByPlaceId(place_id, user_id);
        console.log('Photos récupérées :', photos);
        res.status(200).json({ photos });
    } catch (error) {
        console.error('Erreur lors de la récupération des images :', error);
        res.status(500).json({ error: 'Impossible de récupérer les images.' });
    }
};

// Récupérer les images par id_photo
const getImagesById = async (req, res) => {
    try {
        const { photoIds } = req.body;
        if (!photoIds || photoIds.length === 0) {
            return res.status(400).json({ error: 'Aucun identifiant d\'image fourni.' });
        }

        const photos = await uploadService.fetchImagesByIds(photoIds);
        console.log('Photos récupérées :', photos);
        res.status(200).json({ photos });
    } catch (error) {
        console.error('Erreur lors de la récupération des images :', error);
        res.status(500).json({ error: 'Impossible de récupérer les images.' });
    }
};

module.exports = { uploadImage, getImagesByPlaceId, getImagesById };
