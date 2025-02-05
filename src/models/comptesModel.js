const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');
const config = require('../config/default');

async function inscription(userData) {
    const { email, username, password } = userData;

    if (typeof password !== "string") {
        throw new Error("Le mot de passe doit être une chaîne de caractères.");
    }

    try {
        const passwordHash = await bcrypt.hash(password, 10);
        const query = `
            INSERT INTO users (email, username, password_hash)
            VALUES ($1, $2, $3)
            RETURNING id, email, username, created_at;
        `;
        const values = [email, username, passwordHash];
        const result = await pool.query(query, values);

        return { success: true, user: result.rows[0] };
    } catch (error) {
        console.error("Erreur lors de l'inscription :", error);
        throw error;
    }
};

async function connexion(emailOrUsername, password) {
    try {
        const query = `
            SELECT id, password_hash, email, username
            FROM users
            WHERE email = $1 OR username = $1
        `;
        const result = await pool.query(query, [emailOrUsername]);

        if (result.rows.length === 0) {
            throw new Error("Aucun compte trouvé avec cet identifiant.");
        }

        const user = result.rows[0];
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);
        if (!isPasswordValid) {
            throw new Error("Mot de passe incorrect.");
        }

        const accessToken = jwt.sign(
            { userId: user.id, email: user.email, username: user.username },
            config.jwtSecret,
            { expiresIn: '1h' }
        );

        const refreshToken = jwt.sign(
            { userId: user.id },
            config.jwtRefreshSecret,
            { expiresIn: '3m' }
        );

        await pool.query(`UPDATE users SET refresh_token = $1 WHERE id = $2`, [refreshToken, user.id]);

        return { success: true, accessToken, refreshToken };
    } catch (error) {
        console.error("Erreur lors de la connexion :", error);
        throw error;
    }
};

async function getProfil(pseudo) {
    try {
        const query = `
            SELECT * FROM users WHERE email = $1 OR username = $1
        `;
        const result = await pool.query(query, [pseudo]);
        return result.rows;
    } catch (error) {
        console.error("Erreur lors de la récupération du profil :", error);
        throw error;
    }
}

async function refreshToken(oldRefreshToken) {
    try {
        const decoded = jwt.verify(oldRefreshToken, config.jwtRefreshSecret);
        const query = `SELECT id FROM users WHERE id = $1 AND refresh_token = $2`;
        const result = await pool.query(query, [decoded.userId, oldRefreshToken]);

        if (result.rows.length === 0) {
            throw new Error("Refresh token invalide.");
        }

        const newAccessToken = jwt.sign(
            { userId: decoded.userId },
            config.jwtSecret,
            { expiresIn: '1h' }
        );

        return { success: true, accessToken: newAccessToken };
    } catch (error) {
        console.error("Erreur lors du rafraîchissement du token :", error);
        throw error;
    }
}

async function deconnexion(userId) {
    try {
        await pool.query(`UPDATE users SET refresh_token = NULL WHERE id = $1`, [userId]);
        return { success: true, message: "Déconnexion réussie." };
    } catch (error) {
        console.error("Erreur lors de la déconnexion :", error);
        throw error;
    }
}

module.exports = {
    inscription,
    connexion,
    getProfil,
    refreshToken,
    deconnexion
};
