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
        `SELECT * FROM avis 
         WHERE place_id = $1
         AND avis_id > $2
         ORDER BY avis_parent NULLS FIRST, created_at DESC
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

exports.likeAvisById = async (avis_id, user_id) => { 
    const result = await pool.query(
        `INSERT INTO avis_likes 
        VALUES ($1, $2) RETURNING *`,
        [avis_id, user_id]
    );

    return result.rows.length > 0 ? result.rows[0] : null;
};