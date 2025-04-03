const db = require('../config/db'); // Connexion à PostgreSQL

// Récupérer les images d'un lieu
const getImagesByPlaceId = async (id_lieu) => {
    try {
        const result = await db.query(
            `SELECT id_photo, id_lieu, id_avis
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

// Enregistrer une nouvelle image
const saveImage = async (imageData) => {
    try {
        const { id_photo, id_lieu, id_avis } = imageData;
        
        const query = `INSERT INTO photos (id_photo, id_lieu, id_avis) 
                      VALUES ($1, $2, $3) 
                      RETURNING *`;
        const values = [id_photo, id_lieu, id_avis || null];
        
        const result = await db.query(query, values);
        return result.rows[0];
    } catch (error) {
        console.error('❌ Erreur lors de l\'enregistrement de l\'image dans la BDD :', error);
        throw new Error('Impossible d\'enregistrer l\'image dans la base de données.');
    }
};

module.exports = {
    getImagesByPlaceId,
    saveImage
};