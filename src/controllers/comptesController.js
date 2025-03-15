const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { inscriptionUtilisateur, getUtilisateur, updateUtilisateur } = require('../models/comptesModel');

const ACCESS_TOKEN_SECRET = 'votre_secret_access';
const REFRESH_TOKEN_SECRET = 'votre_secret_refresh';

exports.inscription = async (req, res) => {
    const { email, username, password } = req.body;
    if (!email || !username || !password) {
        return res.status(400).json({ message: "Tous les champs sont obligatoires." });
    }

    try {
        const utilisateur = await inscriptionUtilisateur(email, username, password);
        const accessToken = jwt.sign({ id: utilisateur.id, username: utilisateur.username }, ACCESS_TOKEN_SECRET, { expiresIn: '1h' });
        const refreshToken = jwt.sign({ id: utilisateur.id }, REFRESH_TOKEN_SECRET, { expiresIn: '90d' });
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

        const accessToken = jwt.sign({ id: utilisateur.id, username: utilisateur.username }, ACCESS_TOKEN_SECRET, { expiresIn: '1h' });
        const refreshToken = jwt.sign({ id: utilisateur.id }, REFRESH_TOKEN_SECRET, { expiresIn: '90d' });

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

    jwt.verify(refreshToken, REFRESH_TOKEN_SECRET, (err, user) => {
        if (err) return res.status(403).json({ message: "Token invalide." });

        const newAccessToken = jwt.sign({ id: user.id, username: user.username }, ACCESS_TOKEN_SECRET, { expiresIn: '1h' });
        res.json({ accessToken: newAccessToken });
    });
};

exports.logout = (req, res) => {
    res.json({ message: "Déconnexion réussie." });
};

exports.getProfil = async (req, res) => {
    const { pseudo } = req.body;
    try {
        const utilisateur = await getUtilisateur(pseudo);
        if (!utilisateur) return res.status(404).json({ message: "Utilisateur non trouvé." });
        res.json(utilisateur);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

exports.updateProfil = async (req, res) => {
    const userId = req.user.id; // Récupération de l'ID depuis le middleware
    const updatedFields = req.body;

    if (!updatedFields || Object.keys(updatedFields).length === 0) {
        return res.status(400).json({ message: "Aucune donnée à mettre à jour." });
    }

    try {
        const utilisateurMisAJour = await updateUtilisateur(userId, updatedFields);
        res.json({ message: "Profil mis à jour.", utilisateur: utilisateurMisAJour });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};