const uploadService = require('../services/uploadService');

const uploadImage = async (req, res) => {
    try {
        console.log("Requête reçue :", req.body);  // 🔍 Vérifier ce qui arrive
        console.log("Fichier reçu :", req.file);  // 📸 Vérifier le fichier

        if (!req.file) {
            return res.status(400).json({ error: 'Aucun fichier reçu' });
        }

        const { id_lieu, id_avis } = req.body;
        const filePath = req.file.path;

        if (!id_lieu) {
            return res.status(400).json({ error: 'id_lieu est obligatoire' });
        }

        const id_avi = id_avis==="null" ?  null : id_avis;

        const result = await uploadService.processAndUploadImage(filePath, id_lieu, id_avi);
        res.status(201).json(result);
    } catch (error) {
        console.error("Erreur lors de l'upload :", error);
        res.status(500).json({ error: 'Erreur serveur' });
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
