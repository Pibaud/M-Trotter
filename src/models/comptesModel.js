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

async function getUtilisateurconnect(emailOrUsername) {
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

async function getUtilisateurById(id) {
    try {
        const query = `
            SELECT id, username, profile_pic
            FROM users
            WHERE id = $1;
        `;
        const result = await pool.query(query, [id]);
        return result.rows[0] || null;
    } catch (error) {
        throw new Error("Erreur lors de la récupération de l'utilisateur : " + error.message);
    }
}

// Fonction pour mettre à jour un utilisateur
async function updateUtilisateur(id, updatedFields){
    if (!id || Object.keys(updatedFields).length === 0) {
        throw new Error("ID utilisateur ou données de mise à jour manquants.");
    }

    const fields = [];
    const values = [];
    let index = 1;

    // Construction dynamique des champs et valeurs
    for (const [key, value] of Object.entries(updatedFields)) {
        fields.push(`${key} = $${index}`);
        values.push(value);
        index++;
    }

    // Ajout du champ updated_at avec la date et heure actuelle
    fields.push(`updated_at = NOW()`);

    // Ajout de l'ID à la liste des valeurs pour la condition WHERE
    values.push(id);

    const query = `UPDATE users SET ${fields.join(', ')} WHERE id = $${index} RETURNING *;`;

    try {
        const result = await pool.query(query, values);
        return result.rows[0]; // Retourne l'utilisateur mis à jour
    } catch (error) {
        console.error("Erreur lors de la mise à jour du profil :", error);
        throw new Error("Échec de la mise à jour du profil.");
    }
};
// Fonction pour récupérer un utilisateur par son id, celui renvoie des données sensibles
async function getUtilisateur(id) {
    try {
        const query = `
            SELECT id, email, username, created_at, updated_at, dark_mode, language, profile_pic, two_factor_enabled, fiabilite, last_login
            FROM users
            WHERE id = $1;
        `;
        const result = await pool.query(query, [id]);
        return result.rows[0] || null;
    } catch (error) {
        throw new Error("Erreur lors de la récupération de l'utilisateur : " + error.message);
    }
}



module.exports = {
    inscriptionUtilisateur,
    getUtilisateurconnect,
    updateUtilisateur,
    getUtilisateurById,
    getUtilisateur
};
