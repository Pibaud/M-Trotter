const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const uploadModel = require('../models/uploadModel'); 

const VPS_URL = 'http://217.182.79.84:3000';

// Vérifier et créer le dossier 'uploads/' s'il n'existe pas
const uploadDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Configuration de Multer pour le stockage local
const storage = multer.diskStorage({
    destination: (req, file, cb) => cb(null, uploadDir),
    filename: (req, file, cb) => {
        const safeFilename = file.originalname.replace(/\s+/g, '_');
        cb(null, `${Date.now()}-${safeFilename}`);
    },
});

const upload = multer({ storage });

// Fonction pour envoyer une image vers le VPS + l'enregistrer en base
const uploadToVPS = async (filePath, id_lieu, id_avis) => {
    try {
        console.log(`📤 Envoi de l'image ${filePath} vers ${VPS_URL}...`);

        const formData = new FormData();
        formData.append('image', fs.createReadStream(filePath));
        formData.append('id_lieu', id_lieu);
        formData.append('id_avis', id_avis || null);

        const response = await axios.post(`${VPS_URL}/upload`, formData, {
            headers: { ...formData.getHeaders() },
        });

        console.log('✅ Image envoyée avec succès au VPS');

        // Enregistrer en base de données
        const { id_photo, created_at } = await uploadModel.addImage(id_lieu, id_avis);

        // Construire l’URL dynamiquement
        const image_url = `${VPS_URL}/images/${id_photo}.jpg`;

        return { id_photo, image_url, created_at };
    } catch (error) {
        console.error('❌ Erreur lors de l’envoi au VPS :', error.message);
        throw new Error('Impossible d’enregistrer l’image.');
    }
};

// Récupérer toutes les images associées à un lieu depuis la BDD
const fetchImagesByPlaceId = async (placeId) => {
    try {
        console.log(`📸 Récupération des images pour le lieu ${placeId}...`);

        const images = await uploadModel.getImagesByPlaceId(placeId);

        return images.map(image => ({
            id_photo: image.id_photo,
            id_avis: image.id_avis,
            created_at: image.created_at,
            image_url: `${VPS_URL}/images/${image.id_photo}.jpg`
        }));
    } catch (error) {
        console.error('Erreur lors de la récupération des images :', error.message);
        throw new Error('Impossible de récupérer les images.');
    }
};

module.exports = { uploadToVPS, fetchImagesByPlaceId, upload };
