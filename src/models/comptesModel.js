const bcrypt = require('bcrypt');
const pool = require('../config/db');

async function inscription(userData) {
    const { email, username, password } = userData;

    try {
        // Hash du mot de passe
        const passwordHash = await bcrypt.hash(password, 10);

        // Insertion dans la base de données
        const query = `
            INSERT INTO users (email, username, password_hash)
            VALUES ($1, $2, $3)
            RETURNING id, email, username, created_at;
        `;
        const values = [email, username, passwordHash];

        const result = await pool.query(query, values);

        // Retourne le nouvel utilisateur (sans mot de passe)
        return { success: true, user: result.rows[0] };
    } catch (error) {
        console.error('Erreur lors de l\'inscription de l\'utilisateur :', error);
        throw error;
    }
};

async function connexion(emailOrUsername, password) {
    try {
        // Chercher l'utilisateur par email ou username
        const query = `
            SELECT id, password_hash, email, username 
            FROM users 
            WHERE email = $1 OR username = $1
        `;
        const result = await pool.query(query, [emailOrUsername]);

        // Si aucun utilisateur trouvé
        if (result.rows.length === 0) {
            throw new Error("Aucun compte trouvé avec cet identifiant.");
        }

        const user = result.rows[0];

        // Vérifier le mot de passe
        const isPasswordValid = await bcrypt.compare(password, user.password_hash);
        if (!isPasswordValid) {
            throw new Error("Mot de passe incorrect.");
        }

        return { success: true, userId: user.id, email: user.email, username: user.username };
    } catch (error) {
        console.error("Erreur lors de la connexion :", error.message);
        throw error;
    }
};


module.exports = {
    inscription,
    connexion
};