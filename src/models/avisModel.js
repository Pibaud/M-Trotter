const pool = require('../config/db');

exports.newavis =  async ({ user_id, place_id, place_table, lavis, avis_parent, nb_etoile}) => {
    const result = await pool.query(
        `INSERT INTO avis (user_id, place_id, place_table, lavis, created_at, avis_parent, nb_etoiles) 
         VALUES ($1, $2, $3, $4, NOW(), $5, $6) RETURNING *`,
        [user_id, place_id, place_table, lavis, avis_parent, nb_etoile]
    );
    return result.rows[0];
};

exports.fetchAvisById = async (place_id, startid) => {
    const result = await pool.query(
        `SELECT a.*, 
                COALESCE(l.like_count, 0) AS like_count
         FROM avis a
         LEFT JOIN (
             SELECT avis_id, COUNT(*) AS like_count
             FROM avis_likes
             GROUP BY avis_id
         ) l ON a.avis_id = l.avis_id
         WHERE a.place_id = $1
         AND a.avis_id > $2
         ORDER BY a.avis_parent NULLS FIRST, a.created_at DESC
         LIMIT 10`,
        [place_id, startid]
    );
    return result.rows.length > 0 ? result.rows : null;
};


exports.deleteAvisById = async (avis_id) => {
    const result = await pool.query(
        `DELETE FROM avis
         WHERE avis_id = $1
         RETURNING *`,
        [avis_id]
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