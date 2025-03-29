const lieuxModel = require('../models/lieuxModel');
const jwt = require('jsonwebtoken');

exports.ajouterLieu = async (req, res) => {
    const { accessToken, nom, amenity, latitude, longitude } = req.body;

    let userId;
    try {
        const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
        userId = decodedToken.id;  // Correction ici
    } catch (err) {
        return res.status(401).json({ error: 'Token invalide ou expiré' });
    }
    try {
        const lieu = await lieuxModel.ajouterLieu(userId, nom, amenity, latitude, longitude);
        res.status(201).json({ success: true, lieu });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.supprimerLieu = async (req, res) => {
    const { accessToken, osm_id } = req.body;
    let userId;
    try {
        const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
        userId = decodedToken.id;  // Correction ici
    } catch (err) {
        return res.status(401).json({ error: 'Token invalide ou expiré' });
    }
    try {
        const suppression = await lieuxModel.supprimerLieu(userId, osm_id);
        res.status(201).json({ success: true, suppression });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.voterAjout = async (req, res) => {
    const { accessToken, id_lieux, vote } = req.body;
    let userId;
    try {
        const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
        userId = decodedToken.id;  // Correction ici
    } catch (err) {
        return res.status(401).json({ error: 'Token invalide ou expiré' });
    }
    try {
        await lieuxModel.voterAjout(userId, id_lieux, vote);
        res.status(200).json({ success: true, message: 'Vote enregistré' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};

exports.voterSuppression = async (req, res) => {
    const { accessToken, id_lieux, vote } = req.body;
    let userId;
    try {
        const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
        userId = decodedToken.id;  // Correction ici
    } catch (err) {
        return res.status(401).json({ error: 'Token invalide ou expiré' });
    }
    try {
        await lieuxModel.voterSuppression(userId, id_lieux, vote);
        res.status(200).json({ success: true, message: 'Vote enregistré' });
    } catch (error) {
        res.status(500).json({ success: false, message: error.message });
    }
};
