const db = require('../config/db'); // Connexion à PostgreSQL

// Ajouter une image dans la BDD
const addImage = async (id_lieu, id_avis) => {
    try {
        const result = await db.query(
            `INSERT INTO photos (id_lieu, id_avis, created_at) 
             VALUES ($1, $2, NOW()) 
             RETURNING id_photo, created_at`,
            [id_lieu, id_avis]
        );
        return result.rows[0];
    } catch (error) {
        console.error('❌ Erreur lors de l’insertion de l’image dans la BDD :', error);
        throw new Error('Impossible d’enregistrer l’image dans la base de données.');
    }
};

// Récupérer les images d’un lieu
const getImagesByPlaceId = async (id_lieu) => {
    try {
        const result = await db.query(
            `SELECT id_photo, id_avis, created_at 
             FROM photos 
             WHERE id_lieu = $1`,
            [id_lieu]
        );
        return result.rows;
    } catch (error) {
        console.error('❌ Erreur lors de la récupération des images dans la BDD :', error);
        throw new Error('Impossible de récupérer les images depuis la base de données.');
    }
};

module.exports = { addImage, getImagesByPlaceId };
