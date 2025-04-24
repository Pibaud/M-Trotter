const pool = require('../config/db');

exports.newavis = async ({ user_id, place_id, place_table, lavis, avis_parent, nb_etoile }) => {
    try {
        const result = await pool.query(
            `INSERT INTO avis (user_id, place_id, place_table, lavis, created_at, avis_parent, nb_etoiles) 
            VALUES ($1, $2, $3, $4, NOW(), $5, $6) RETURNING *`,
            [user_id, place_id, place_table, lavis, avis_parent, nb_etoile]
        );
        return result.rows[0];
    } catch (error) {
        console.error('❌ Erreur lors de l\'ajout d\'un avis :', error);
        throw new Error('Impossible d\'ajouter l\'avis dans la base de données, sans doute un erreur d\'utilisateur qui a déjà posté un avis sur ce lieu.');
    }
};

exports.fetchAvisbyUser = async (user_id) => {
    const result = await pool.query(
        `SELECT a.*, 
                COALESCE(l.like_count, 0) AS like_count,
                json_agg(p.id_photo) AS photos
         FROM avis a 
         LEFT JOIN (
             SELECT avis_id, COUNT(*) AS like_count
             FROM avis_likes
             GROUP BY avis_id
         ) l ON a.avis_id = l.avis_id
         LEFT JOIN photos p ON a.avis_id = p.id_avis
         WHERE a.user_id = $1
         GROUP BY a.avis_id, l.like_count`,
        [user_id]
    );

    const avisList = result.rows;

    return avisList.length > 0 ? avisList : null;
};

exports.fetchAvisById = async (place_id, startid, user_id) => {
    const result = await pool.query(
        `SELECT a.*, 
                COALESCE(l.like_count, 0) AS like_count,
                json_agg(p.id_photo) AS photos,
                CASE 
                    WHEN al.user_id IS NOT NULL THEN true 
                    ELSE false 
                END AS user_has_liked,
                CASE 
                    WHEN a.user_id = $3 THEN true 
                    ELSE false
                END AS user_is_author
         FROM avis a
         LEFT JOIN (
             SELECT avis_id, COUNT(*) AS like_count
             FROM avis_likes
             GROUP BY avis_id
         ) l ON a.avis_id = l.avis_id
         LEFT JOIN photos p ON a.avis_id = p.id_avis
         LEFT JOIN avis_likes al ON a.avis_id = al.avis_id AND al.user_id = $3
         WHERE a.place_id = $1
         AND a.avis_id > $2
         GROUP BY a.avis_id, l.like_count, al.user_id
         ORDER BY user_is_author DESC, like_count DESC, a.created_at ASC
         LIMIT 10`,
        [place_id, startid, user_id]
    );

    return result.rows.length > 0 ? result.rows : null;
};

exports.deleteAvisById = async (avis_id, user_id) => {
    const result = await pool.query(
        `DELETE FROM avis
         WHERE avis_id = $1
         AND user_id = $2
         RETURNING *`,
        [avis_id, user_id]
    );

    return result.rows.length > 0 ? result.rows[0] : null;
};

exports.deletelike = async (avis_id, user_id) => {
    const result = await pool.query(
        `DELETE FROM avis_likes
         WHERE avis_id = $1
         AND user_id = $2
         RETURNING *`,
        [avis_id, user_id]
    );

    return result.rows.length > 0 ? result.rows[0] : null;
}

exports.likeAvisById = async (avis_id, user_id) => {
    const result = await pool.query(
        `INSERT INTO avis_likes 
        VALUES ($1, $2) RETURNING *`,
        [avis_id, user_id]
    );

    return result.rows.length > 0 ? result.rows[0] : null;
};

exports.updateAvis = async (avis_id, user_id, lavis, nb_etoile) => {
    const result = await pool.query(
        `UPDATE avis
            SET lavis = $3, nb_etoile = $4, created_at = NOW()
            WHERE avis_id = $1 AND user_id = $2
            RETURNING *`,
        [avis_id, user_id, lavis, nb_etoile]
    );
    return result.rows.length > 0 ? result.rows[0] : null;
}

exports.updatereponses = async (avis_id, user_id, lavis, avis_parent) => {
    const result = await pool.query(
        `UPDATE avis
            SET lavis = $3, avis_parent = $4, created_at = NOW()
            WHERE avis_id = $1 AND user_id = $2
            RETURNING *`,
        [avis_id, user_id, lavis, avis_parent]
    );
    return result.rows.length > 0 ? result.rows[0] : null;
}