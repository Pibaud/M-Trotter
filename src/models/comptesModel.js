const bcrypt = require('bcrypt');
const pool = require('../config/db');

async function inscriptionUtilisateur(email, username, password) {
    try {
        const passwordHash = await bcrypt.hash(password, 10);
        const query = `
            INSERT INTO users (email, username, password_hash)
            VALUES ($1, $2, $3)
            RETURNING id, email, username, created_at;
        `;
        const values = [email, username, passwordHash];
        const result = await pool.query(query, values);
        return result.rows[0];
    } catch (error) {
        throw new Error("Erreur lors de l'inscription de l'utilisateur : " + error.message);
    }
}

async function getUtilisateur(emailOrUsername) {
    try {
        const query = `
            SELECT id, email, username, password_hash
            FROM users
            WHERE email = $1 OR username = $1;
        `;
        const result = await pool.query(query, [emailOrUsername]);
        return result.rows[0] || null;
    } catch (error) {
        throw new Error("Erreur lors de la récupération de l'utilisateur : " + error.message);
    }
}

module.exports = {
    inscriptionUtilisateur,
    getUtilisateur
};
