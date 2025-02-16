const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');
const multer = require('multer');

const VPS_URL = 'http://217.182.79.84:3000'; // URL du serveur VPS

// Vérifier et créer le dossier 'uploads/' s'il n'existe pas
const uploadDir = path.join(__dirname, '../uploads');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Configuration de Multer pour le stockage local
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        const safeFilename = file.originalname.replace(/\s+/g, '_'); // Remplace les espaces
        cb(null, Date.now() + '-' + safeFilename);
    },
});

const upload = multer({ storage: storage });

// Fonction pour envoyer une image vers le VPS après l'upload local
const uploadToVPS = async (filePath) => {
    try {
        const formData = new FormData();
        formData.append('image', fs.createReadStream(filePath));

        const response = await axios.post(VPS_URL+"/upload", formData, {
            headers: {
                ...formData.getHeaders(),
            },
        });

        return response.data;
    } catch (error) {
        console.error('❌ Erreur lors de l’envoi au VPS :', error.message);
        throw new Error('Impossible d’envoyer l’image au serveur distant.');
    }
};

const fetchImageFromVPS = async (filename) => {
    try {
        const response = await axios({
            method: 'get',
            url: `${VPS_URL+"/image/"}${filename}`,
            responseType: 'stream' // On récupère l’image en flux (stream)
        });

        return response;
    } catch (error) {
        console.error('Erreur lors de la récupération de l’image du VPS :', error.message);
        throw new Error('Impossible de récupérer l’image depuis le serveur distant.');
    }
};

module.exports = {fetchImageFromVPS, uploadToVPS, upload };
