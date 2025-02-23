const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const uploadModel = require('../models/uploadModel'); 

const VPS_URL = 'http://217.182.79.84:3000';

// Fonction pour envoyer une image vers le VPS + l'enregistrer en base
const uploadImageToVPS = async (filePath, id_lieu, id_avis = null) => {
    try {
        if (!filePath.endsWith('.jpg')) {
            throw new Error('Seuls les fichiers .jpg sont autorisés');
        }

        const formData = new FormData();
        formData.append('image', fs.createReadStream(filePath));
        formData.append('id_lieu', id_lieu);
        if (id_avis) {
            formData.append('id_avis', id_avis);
        }

        const response = await axios.post(VPS_URL, formData, {
            headers: {
                ...formData.getHeaders(),
            },
        });

        return response.data;
    } catch (error) {
        console.error('Erreur lors de l’envoi de l’image au VPS :', error.message);
        throw new Error('Impossible d’envoyer l’image.');
    }
};

// Récupérer toutes les images associées à un lieu depuis la BDD
const fetchImagesByPlaceId = async (placeId) => {
    try {
        console.log(`📸 Récupération des images pour le lieu ${placeId}...`);

        let images = await uploadModel.getImagesByPlaceId(placeId);
        console.log('Images récupérées de la BDD :', images);

        if (!images || images.length === 0) {
            console.error('Aucune image trouvée pour ce lieu.');
            return []; // Retourner un tableau vide plutôt que de lever une erreur
        }

        // Transformer le format en tableau d'IDs
        const imageIds = images.map((image) => image.id_photo);
        console.log('📤 Demande des images au VPS pour les IDs :', imageIds);

        // Requête POST au VPS avec les IDs des images
        const response = await axios.post(`${VPS_URL}/images/`, { photo_ids: imageIds });

        console.log('📥 Réponse du VPS :', response.data);

        return response.data; // Retourner les images avec leurs URLs
    } catch (error) {
        console.error('❌ Erreur lors de la récupération des images :', error.message);
        throw new Error('Impossible de récupérer les images.');
    }
};


module.exports = { uploadImageToVPS, fetchImagesByPlaceId};
