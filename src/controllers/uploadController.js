const uploadService = require('../services/uploadService');

const uploadImage = (req, res) => {
    uploadService.upload.single('image')(req, res, async (err) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        if (!req.file) {
            return res.status(400).json({ error: 'Aucun fichier envoyé.' });
        }

        const { id_lieu, id_avis } = req.body;

        if (!id_lieu) {
            return res.status(400).json({ error: 'id_lieu est requis.' });
        }

        try {
            // Envoyer l'image au VPS et enregistrer en base
            const uploadResult = await uploadService.uploadToVPS(req.file.path, id_lieu, id_avis);

            res.json({
                message: 'Fichier uploadé avec succès',
                id_photo: uploadResult.id_photo,
                created_at: uploadResult.created_at,
                image_url: uploadResult.image_url
            });
        } catch (error) {
            res.status(500).json({ error: 'Erreur lors de l’envoi de l’image au VPS.' });
        }
    });
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
        res.status(500).json({ error: 'Impossible de récupérer les images.' });
    }
};

module.exports = { uploadImage, getImagesByPlaceId };
