const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { inscriptionUtilisateur, getUtilisateurconnect, updateUtilisateur, getUtilisateurById, getUtilisateur } = require('../models/comptesModel');
require('dotenv').config();
const sendEmail = require('../config/email');



exports.inscription = async (req, res) => {
    const { email, username, password } = req.body;
    if (!email || !username || !password) {
        return res.status(400).json({ message: "Tous les champs sont obligatoires." });
    }

    try {
        const utilisateur = await inscriptionUtilisateur(email, username, password);
        const accessToken = jwt.sign({ id: utilisateur.id, username: utilisateur.username }, process.env.ACCESS_TOKEN_SECRET, { expiresIn: '1h' });
        const refreshToken = jwt.sign({ id: utilisateur.id }, process.env.REFRESH_TOKEN_SECRET, { expiresIn: '90d' });

        const subject = "Bienvenue dans la famille M'trotter";
        const text = `Bonjour,   votre guide M'trotter. Bienvenu dans la famille M'trotter !`;
        const html = `<p>Bonjour,</p>
                    <p>Merci de vous être inscrit sur M'trotter !</p>
                    <p>N'hésitez pas à parler de nous sur les reseaux sociaux ou à vos amis</p>`;

        await sendEmail(email, subject, text, html);

        res.json({ success: true, accessToken, refreshToken });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.connexions = async (req, res) => {
    const { EorU, password } = req.body;
    if (!EorU || !password) {
        return res.status(400).json({ message: "Email/Username et mot de passe sont requis." });
    }

    try {
        const utilisateur = await getUtilisateurconnect(EorU);
        if (!utilisateur) {
            return res.status(401).json({ message: "Utilisateur non trouvé." });
        }

        const valide = await bcrypt.compare(password, utilisateur.password_hash);
        if (!valide) {
            return res.status(401).json({ message: "Mot de passe incorrect." });
        }

        const accessToken = jwt.sign({ id: utilisateur.id, username: utilisateur.username }, process.env.ACCESS_TOKEN_SECRET, { expiresIn: '1h' });
        const refreshToken = jwt.sign({ id: utilisateur.id }, process.env.REFRESH_TOKEN_SECRET, { expiresIn: '90d' });

        res.json({ accessToken, refreshToken });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.refreshToken = (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken) {
        return res.status(401).json({ message: "Token manquant." });
    }

    jwt.verify(refreshToken, process.env.REFRESH_TOKEN_SECRET, (err, user) => {
        if (err) return res.status(403).json({ message: "Token invalide." });

        const newAccessToken = jwt.sign({ id: user.id, username: user.username }, process.env.ACCESS_TOKEN_SECRET, { expiresIn: '1h' });
        res.json({ accessToken: newAccessToken });
    });
};

exports.logout = (req, res) => {
    res.json({ message: "Déconnexion réussie." });
};

exports.getProfil = async (req, res) => {
    const { accessToken } = req.body;
    let userId;
    try {
        const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
        userId = decodedToken.id;  // Correction ici
    } catch (err) {
        return res.status(401).json({ error: 'Token invalide ou expiré' });
    }
    try {
        const utilisateur = await getUtilisateur(userId);
        if (!utilisateur) return res.status(404).json({ message: "Utilisateur non trouvé." });
        res.json(utilisateur);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.getOtherProfil = async (req, res) => {
    const { id_user } = req.body;

    if (!id_user) {
        return res.status(400).json({ message: "ID utilisateur manquant." });
    }

    try {
        const utilisateur = await getUtilisateurById(id_user);
        if (!utilisateur) {
            return res.status(404).json({ message: "Utilisateur non trouvé." });
        }
        res.json(utilisateur);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateProfil = async (req, res) => {
    const { accessToken, updatedFields } = req.body;

    if (!accessToken) {
        return res.status(401).json
    }

    let user_id;
    try {
        const decodedToken = jwt.verify(accesstoken, process.env.ACCESS_TOKEN_SECRET);
        user_id = decodedToken.id;
    } catch (err) {
        return res.status(401).json({ error: 'Token invalide ou expiré' });
    }

    if (!updatedFields || Object.keys(updatedFields).length === 0) {
        return res.status(400).json({ message: "Aucune donnée à mettre à jour." });
    }

    try {
        const utilisateurMisAJour = await updateUtilisateur(user_id, updatedFields);
        res.json({ message: "Profil mis à jour.", utilisateur: utilisateurMisAJour });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};