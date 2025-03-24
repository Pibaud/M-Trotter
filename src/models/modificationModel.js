const db = require('../config/db');

exports.ajouterModification = async ({ osm_id, champ_modifie, ancienne_valeur, nouvelle_valeur, id_utilisateur }) => {
    const query = `
        INSERT INTO modifications (osm_id, champ_modifie, ancienne_valeur, nouvelle_valeur, propose_par, date_proposition)
        VALUES ($1, $2, $3, $4, $5, NOW()) RETURNING *;
    `;
    const { rows } = await db.query(query, [osm_id, champ_modifie, ancienne_valeur, nouvelle_valeur, id_utilisateur]);
    return rows[0];
};

exports.getLieuxProches = async (latitude, longitude, rayon = 100) => {
    const query = `
        SELECT osm_id, name, ST_AsGeoJSON(way) AS geojson
        FROM planet_osm_point
        WHERE ST_DWithin(
            way,
            ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
            $3
        )
        LIMIT 10;
    `;

    const { rows } = await db.query(query, [longitude, latitude, rayon]);
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
