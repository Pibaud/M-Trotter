const uploadService = require('../services/uploadService');

const uploadImage = async (req, res) => {
    try {
        const { filePath, id_lieu, id_avis } = req.body;

        if (!filePath || !id_lieu) {
            return res.status(400).json({ error: 'Paramètres manquants' });
        }

        const result = await uploadService.uploadImageToVPS(filePath, id_lieu, id_avis);
        res.status(201).json(result);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};


// Récupérer les images par id_lieu
const getImagesByPlaceId = async (req, res) => {
    try {
        const { place_id } = req.body;
        if (!place_id) {
            return res.status(400).json({ error: "L'identifiant du lieu est requis." });
        }

        const photos = await uploadService.fetchImagesByPlaceId(place_id);
        res.json( photos );
    } catch (error) {
        console.error('Erreur lors de la récupération des images :', error);
        res.status(500).json({ error: 'Impossible de récupérer les images.' });
    }
};

module.exports = { uploadImage, getImagesByPlaceId };
