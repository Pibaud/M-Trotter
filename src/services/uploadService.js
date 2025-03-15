const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const sharp = require('sharp');
const uploadModel = require('../models/uploadModel'); 

const VPS_URL = 'http://217.182.79.84:3000';

const MAX_PIXELS = 2073600; // Limite de 2 073 600 pixels (Full HD)

const processAndUploadImage = async (filePath, id_lieu, id_avis = null) => {
    try {
        console.log(`📸 Traitement de l’image ${filePath} pour le lieu ${id_lieu}...`);
        if (!filePath.endsWith('.jpg')) {
            throw new Error('Seuls les fichiers .jpg sont autorisés');
        }

        // Lire les métadonnées de l'image
        const metadata = await sharp(filePath).metadata();
        let { width, height } = metadata;
        const totalPixels = width * height;

        // Si l'image dépasse 2 073 600 pixels, on la redimensionne
        if (totalPixels > MAX_PIXELS) {
            const scaleFactor = Math.sqrt(MAX_PIXELS / totalPixels);
            width = Math.round(width * scaleFactor);
            height = Math.round(height * scaleFactor);
        }

        // Chemin temporaire pour l'image redimensionnée
        const tempPath = filePath.replace('.jpg', '_resized.jpg');

        // Redimensionner si nécessaire (conserve le ratio)
        await sharp(filePath)
            .resize({ width, height }) // Redimensionner en respectant le ratio
            .toFormat('jpeg')
            .toFile(tempPath);

        // Préparer l’envoi
        const formData = new FormData();
        formData.append('image', fs.createReadStream(tempPath));
        formData.append('id_lieu', id_lieu);
        if (id_avis) {
            formData.append('id_avis', id_avis);
        }

        // Envoyer l’image redimensionnée au VPS
        const response = await axios.post(VPS_URL+'/upload', formData, {
            headers: { ...formData.getHeaders() },
        });

        // Supprimer le fichier temporaire après l’envoi
        fs.unlinkSync(tempPath);

        return response.data;
    } catch (error) {
        console.error('Erreur lors du traitement/envoi de l’image :', error.message);
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


module.exports = {  processAndUploadImage , fetchImagesByPlaceId};
