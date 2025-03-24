const modificationsModel = require('../models/modificationModel');
const jwt = require('jsonwebtoken');
require('dotenv').config();

exports.proposerModification = async (req, res) => {
    try {
        const { osm_id, champ_modifie, ancienne_valeur, nouvelle_valeur, accesstoken } = req.body;

        let user_id;
        try {
            const decodedToken = jwt.verify(accesstoken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        if (!osm_id || !champ_modifie || !nouvelle_valeur) {
            return res.status(400).json({ error: 'Données manquantes' });
        }

        const modification = await modificationsModel.ajouterModification({ osm_id, champ_modifie, ancienne_valeur, nouvelle_valeur, user_id });

        res.status(201).json({ message: 'Modification proposée avec succès', modification });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Erreur serveur' });
    }
};

exports.lieuxATesterProches = async (req, res) => {
    try {
        const { latitude, longitude, rayon } = req.body;

        if (!latitude || !longitude) {
            return res.status(400).json({ error: 'Latitude et longitude sont requises' });
        }

        const lieux = await modificationsModel.getLieuxProches(latitude, longitude, rayon);
        res.status(200).json({ lieux });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Erreur serveur' });
    }
};