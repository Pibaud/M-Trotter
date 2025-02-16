const path = require('path');
const uploadService = require('../services/uploadService');
const { get } = require('http');

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

const getImage = async (req, res) => {
    try {
        const { filename } = req.body; // On récupère le nom du fichier depuis le corps de la requête

        // Vérifier que le nom de fichier est fourni
        if (!filename) {
            return res.status(400).json({ error: "Nom de fichier manquant." });
        }

        // Récupérer l'image depuis le VPS
        const imageStream = await uploadService.fetchImageFromVPS(filename);

        // Envoyer l'image au client
        res.setHeader('Content-Type', imageStream.headers['content-type']);
        imageStream.data.pipe(res);
    } catch (error) {
        console.error('Erreur lors de la récupération de l’image :', error.message);
        res.status(500).json({ error: 'Impossible de récupérer l’image.' });
    }
};

module.exports = {getImage, uploadImage };
