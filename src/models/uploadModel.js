const db = require('../config/db'); // Connexion à PostgreSQL

// Récupérer les images d'un lieu
const getImagesByPlaceId = async (id_lieu, user_id) => {
    try {
        const result = await db.query(
            `SELECT 
                p.id_photo, 
                p.id_lieu, 
                p.id_avis,
                COALESCE(SUM(g.vote_type * LOG(COALESCE(u.fiabilite, 0) + 1)), 0) AS weighted_vote_score,
                CASE 
                    WHEN gv.id_user IS NOT NULL THEN true 
                    ELSE false 
                END AS user_has_voted
             FROM photos p
             LEFT JOIN goodimage g ON p.id_photo = g.id_image
             LEFT JOIN users u ON g.id_user = u.id
             LEFT JOIN goodimage gv ON p.id_photo = gv.id_image AND gv.id_user = $2
             WHERE p.id_lieu = $1
             GROUP BY p.id_photo, p.id_lieu, p.id_avis, gv.id_user
             ORDER BY weighted_vote_score DESC, p.id_photo ASC`,
            [id_lieu, user_id]
        );
        return result.rows;
    } catch (error) {
        console.error('❌ Erreur lors de la récupération des images dans la BDD :', error);
        throw new Error('Impossible de récupérer les images depuis la base de données.');
    }
};

// Récupérer les détails d'images par leur ID
const getImagesByIds = async (photoIds) => {
    try {
        // Si la liste est vide, retourner un tableau vide
        if (!photoIds || photoIds.length === 0) {
            return [];
        }
        
        // Construire une requête paramétrée pour sélectionner les images par ID
        if (!photoIds.length) {
            return [];
        }        
        const query = `SELECT id_photo, id_lieu, id_avis FROM photos WHERE id_photo IN (${placeholders})`;
        
        const result = await db.query(query, photoIds);
        return result.rows;
    } catch (error) {
        console.error('❌ Erreur lors de la récupération des images par IDs :', error);
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
    getImagesByIds,
    saveImage
};