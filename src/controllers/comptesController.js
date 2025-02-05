const jwt = require('jsonwebtoken');
const { inscription, connexion, getProfil, updateProfil, updateRefreshToken, getUserByRefreshToken, clearRefreshToken } = require('../models/comptesModel');
require('dotenv').config();

const ACCESS_TOKEN_SECRET = process.env.ACCESS_TOKEN_SECRET;
const REFRESH_TOKEN_SECRET = process.env.REFRESH_TOKEN_SECRET;

const generateAccessToken = (user) => {
    return jwt.sign({ id: user.id, email: user.email }, ACCESS_TOKEN_SECRET, { expiresIn: '1h' });
};

const generateRefreshToken = (user) => {
    return jwt.sign({ id: user.id, email: user.email }, REFRESH_TOKEN_SECRET, { expiresIn: '90d' });
};

exports.inscription = async (req, res) => {
    const { email, username, password } = req.body.email ? req.body : req.query;
    if (!email || !username || !password) {
        return res.status(400).json({ message: "Tous les champs (email, username, password) sont obligatoires." });
    }
    
    try {
        const reussite = await inscription({ email, username, password });
        res.json({ status: "Inscription bien reçue", success: true });
    } catch (error) {
        res.status(500).json({ message: "Erreur interne du serveur.", error: error.message });
    }
};

exports.connexions = async (req, res) => {
    const { EorU, password } = req.body;
    if (!EorU || !password) {
        return res.status(400).json({ message: "Email/Username et mot de passe sont requis." });
    }
    
    try {
        const result = await connexion(EorU, password);
        if (!result) {
            return res.status(401).json({ success: false, message: "Identifiants incorrects." });
        }
        
        const accessToken = generateAccessToken(result);
        const refreshToken = generateRefreshToken(result);
        
        await updateRefreshToken(result.id, refreshToken);
        
        res.json({ success: true, message: "Connexion réussie.", accessToken, refreshToken });
    } catch (error) {
        res.status(401).json({ success: false, message: error.message });
    }
};

exports.getProfil = async (req, res) => {
    const { pseudo } = req.body;
    
    try {
        const result = await getProfil(pseudo);
        res.json(result);
    } catch (error) {
        res.status(401).json({ message: error.message });
    }
};

exports.updateProfil = async (req, res) => {
    res.json({ result: "un jour insh' allah" });
};

exports.refreshToken = async (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.sendStatus(401);
    
    try {
        const user = await getUserByRefreshToken(refreshToken);
        if (!user) return res.sendStatus(403);
        
        jwt.verify(refreshToken, REFRESH_TOKEN_SECRET, (err, decodedUser) => {
            if (err) return res.sendStatus(403);
            const newAccessToken = generateAccessToken(decodedUser);
            res.json({ accessToken: newAccessToken });
        });
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error });
    }
};

exports.logout = async (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.sendStatus(401);
    
    try {
        await clearRefreshToken(refreshToken);
        res.sendStatus(204);
    } catch (error) {
        res.status(500).json({ message: 'Erreur serveur', error });
    }
};
