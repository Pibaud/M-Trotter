const db = require('../config/db');

exports.addFavorite = async (userId, osmId) => {
    console.log("on est dans le model pour addFavorites avec le userId : ", userId);
    return db.query('INSERT INTO favoris (id_user, osm_id) VALUES ($1, $2) ON CONFLICT DO NOTHING', [userId, osmId]);
};

exports.delFavorite = async (userId, osmId) => {
    return db.query('DELETE FROM favoris WHERE id_user = $1 AND osm_id = $2', [userId, osmId]);
};

exports.getFavorites = async (userId) => {
    console.log("on est dans le model pour getFavorites avec le userId : ", userId);
    const querry = `SELECT 
                        f.osm_id AS id,
                        p.name, 
                        p.amenity, 
                        ST_X(ST_Centroid(ST_Collect(ST_Transform(p.way, 4326)))) AS longitude, 
                        ST_Y(ST_Centroid(ST_Collect(ST_Transform(p.way, 4326)))) AS latitude, 
                        STRING_AGG(p.tags::TEXT, '; ') AS tags, 
                        'point' AS type,
                        AVG(a.nb_etoiles) AS avg_stars
                    FROM favoris f
                    JOIN planet_osm_point p ON f.osm_id = p.osm_id
                    LEFT JOIN avis a ON p.osm_id = a.place_id
                    WHERE f.id_user = $1
                    GROUP BY f.osm_id, p.name, p.amenity;`
    return db.query(querry, [userId]);
};
