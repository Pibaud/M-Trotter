const path = require('path');
const multer = require('multer');

// 📂 Définition du dossier de destination
const UPLOADS_FOLDER = path.join(__dirname, '..', 'uploads');

const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        cb(null, UPLOADS_FOLDER); // 📌 Multer va stocker ici
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + '-' + file.originalname);
    }
});

// 🔎 Vérification du format (JPG, PNG uniquement)
const fileFilter = (req, file, cb) => {
    const extname = path.extname(file.originalname);
    if (extname === '.jpg' || extname === '.png') {
        console.log('Extension du fichier:', extname);
        cb(null, true);
    } else {
        console.log('Extension du fichier:', path.extname(file.originalname));
        cb(new Error('Seuls les fichiers .jpg et .png sont autorisés'), false);
    }
};

const upload = multer({ storage, fileFilter });

module.exports = upload;
