const path = require('path');
const uploadService = require('../services/uploadService');

const uploadImage = (req, res) => {
    uploadService.upload.single('image')(req, res, async (err) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        if (!req.file) {
            return res.status(400).json({ error: 'Aucun fichier envoyé.' });
        }

        try {
            // Envoyer l'image au VPS
            const vpsResponse = await uploadService.uploadToVPS(req.file.path);

            // Répondre avec les infos du VPS
            res.json({
                message: 'Fichier uploadé avec succès',
                localPath: `/uploads/${req.file.filename}`,
                vpsResponse: vpsResponse
            });
        } catch (error) {
            res.status(500).json({ error: 'Erreur lors de l’envoi de l’image au VPS.' });
        }
    });
};

module.exports = { uploadImage };
