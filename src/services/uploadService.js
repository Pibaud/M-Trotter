const multer = require('multer');
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const uploadModel = require('../models/uploadModel');

const UPLOAD_DIR = '/var/www/m-trotter/uploads/';

// Créer le dossier s'il n'existe pas
if (!fs.existsSync(UPLOAD_DIR)) {
  console.log("thibaud est un génie");
}

// Configuration de Multer pour la gestion des uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, UPLOAD_DIR);
  },
  filename: (req, file, cb) => {
    const uniqueId = Date.now().toString();
    const ext = path.extname(file.originalname);
    cb(null, `${uniqueId}${ext}`);
  },
});

const upload = multer({ storage });
const MAX_PIXELS = 2073600; // Limite de 2 073 600 pixels (Full HD)

// Fonction pour traiter et enregistrer une image
const processAndUploadImage = async (filePath, id_lieu, id_avis = null) => {
  try {
    console.log(`📸 Traitement de l'image ${filePath} pour le lieu ${id_lieu}...`);
    if (!filePath.endsWith('.jpg') && !filePath.endsWith('.jpeg')) {
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

    // Générer un nom de fichier unique
    const filename = `${Date.now()}.jpg`;
    const outputPath = path.join(UPLOAD_DIR, filename);

    // Redimensionner si nécessaire (conserve le ratio)
    await sharp(filePath)
      .resize({ width, height })
      .toFormat('jpeg')
      .toFile(outputPath);

    // Extraire l'ID de l'image du nom de fichier
    const fileId = path.basename(filename, path.extname(filename));
    
    // Enregistrer l'image dans la base de données via le modèle
    const savedImage = await uploadModel.saveImage({
      id_photo: fileId,
      id_lieu,
      id_avis
    });

    return {
      success: true,
      image_id: fileId,
      filename: filename,
      photo: savedImage
    };
  } catch (error) {
    console.error('Erreur lors du traitement/envoi de l\'image :', error.message);
    throw new Error('Impossible d\'envoyer l\'image.');
  }
};

// Récupérer toutes les images associées à un lieu depuis la BDD
const fetchImagesByPlaceId = async (placeId) => {
  try {
    console.log(`📸 Récupération des images pour le lieu ${placeId}...`);

    // Utiliser le modèle pour récupérer les images
    const images = await uploadModel.getImagesByPlaceId(placeId);
    console.log('Images récupérées de la BDD :', images);

    if (!images || images.length === 0) {
      console.log('Aucune image trouvée pour ce lieu.');
      return { photos: [] };
    }

    // Transformer les résultats pour inclure l'URL complète des images
    const photos = images.map(image => {
      const filePath = path.join(UPLOAD_DIR, `${image.id_photo}.jpg`);
      return fs.existsSync(filePath) 
        ? { 
            id: image.id_photo, 
            url: `/uploads/${image.id_photo}.jpg`,
            id_lieu: image.id_lieu,
            id_avis: image.id_avis 
          } 
        : null;
    }).filter(photo => photo !== null);

    return { photos };
  } catch (error) {
    console.error('❌ Erreur lors de la récupération des images :', error.message);
    throw new Error('Impossible de récupérer les images.');
  }
};

// Exposer les fonctions pour une utilisation externe
module.exports = {
  processAndUploadImage,
  fetchImagesByPlaceId,
  upload
};
