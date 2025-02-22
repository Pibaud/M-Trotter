const uploadService = require('../services/uploadService');

const uploadImage = async (req, res) => {
    try {
        // Utilisation de Promisify pour gérer multer correctement
        await new Promise((resolve, reject) => {
            uploadService.upload.single('image')(req, res, (err) => {
                if (err) return reject(err);
                resolve();
            });
        });

        if (!req.file) {
            return res.status(400).json({ error: 'Aucun fichier envoyé.' });
        }

        const { id_lieu, id_avis } = req.body;
        if (!id_lieu) {
            return res.status(400).json({ error: 'id_lieu est requis.' });
        }

        try {
            // Envoyer l’image au VPS et enregistrer en base
            const uploadResult = await uploadService.uploadToVPS(req.file.path, id_lieu, id_avis);

            // Supprimer le fichier local après upload
            require('fs').unlinkSync(req.file.path);

            res.json({
                message: 'Fichier uploadé avec succès',
                id_photo: uploadResult.id_photo,
                created_at: uploadResult.created_at,
                image_url: uploadResult.image_url
            });
        } catch (error) {
            console.error('Erreur lors de l’envoi au VPS :', error);
            return res.status(500).json({ error: 'Erreur lors de l’envoi de l’image au VPS.' });
        }
    } catch (error) {
        console.error('Erreur lors du traitement du fichier :', error);
        return res.status(400).json({ error: error.message });
    }
};

// Récupérer les images par id_lieu
const getImagesByPlaceId = async (req, res) => {
    try {
        const { place_id } = req.params;
        if (!place_id) {
            return res.status(400).json({ error: "L'identifiant du lieu est requis." });
        }

        const photos = await uploadService.fetchImagesByPlaceId(place_id);
        res.json({ photos });
    } catch (error) {
        console.error('Erreur lors de la récupération des images :', error);
        res.status(500).json({ error: 'Impossible de récupérer les images.' });
    }
};

module.exports = { uploadImage, getImagesByPlaceId };
