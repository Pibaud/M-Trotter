const db = require('../config/db'); // Connexion à PostgreSQL

// Récupérer les images d’un lieu
const getImagesByPlaceId = async (id_lieu) => {
    try {
        const result = await db.query(
            `SELECT id_photo
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

module.exports = {getImagesByPlaceId };
