const db = require('../config/db');

exports.ajouterModification = async ({ osm_id, champ_modifie, ancienne_valeur, nouvelle_valeur, id_utilisateur }) => {
    const query = `
        INSERT INTO modifications (osm_id, champ_modifie, ancienne_valeur, nouvelle_valeur, propose_par, date_proposition)
        VALUES ($1, $2, $3, $4, $5, NOW()) RETURNING *;
    `;
    const { rows } = await db.query(query, [osm_id, champ_modifie, ancienne_valeur, nouvelle_valeur, id_utilisateur]);
    return rows[0];
};

exports.getLieuxProches = async (latitude, longitude, rayon = 100, user_id) => {
    const query = `
        SELECT DISTINCT p.osm_id, p.name, ST_AsGeoJSON(p.way) AS geojson, m.*
        FROM planet_osm_point p
        JOIN modifications m ON p.osm_id = m.osm_id
        WHERE m.etat = 'pending'
        AND NOT EXISTS (
            SELECT 1
            FROM validation_modification vm
            WHERE vm.id_modification = m.id_modification
            AND vm.id_utilisateur = $4
        )
        AND ST_DWithin(
            p.way,
            ST_Transform(ST_SetSRID(ST_MakePoint($1, $2), 4326), ST_SRID(p.way)),
            $3
        )
        LIMIT 10;
    `;

    const { rows } = await db.query(query, [longitude, latitude, rayon, user_id]);
    return rows;
};


exports.ajouterVote = async (id_modification, id_utilisateur, vote) => {
    return db.query(`
        INSERT INTO validation_modification (id_modification, id_utilisateur, vote)
        VALUES ($1, $2, $3)
        ON CONFLICT (id_modification, id_utilisateur)
        DO UPDATE SET vote = EXCLUDED.vote
        RETURNING *;
    `, [id_modification, id_utilisateur, vote]);
};
