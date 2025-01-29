const pool = require('../config/db');

exports.ListePlaces = async (search) => {
    try {
        console.log("Recherche de :", search);
        const result = await pool.query(
            'SELECT DISTINCT name, amenity, ST_X(ST_Transform(way, 4326)) AS longitude, ST_Y(ST_Transform(way, 4326)) AS latitude, tags ' +
            'FROM planet_osm_point ' +
            'WHERE name IS NOT NULL AND amenity IS NOT NULL AND similarity(name, $1) > 0.3 ' + // Seuil de similarité ajustable
            'LIMIT 10;', 
            [`${search}`] // Recherche approximative
        );
        
        console.log(result.rows);
        return result.rows; // Renvoie un tableau des noms
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw error;
    }
};

exports.BoxPlaces = async (req, res) => {
    try {
        const { minlat, minlon, maxlat, maxlon } = req.body;
        const result = await pool.query(
            `SELECT name FROM planet_osm_point WHERE ST_Contains(ST_MakeEnvelope($1, $2, $3, $4, 4326), way);`,
            [minlon, minlat, maxlon, maxlat]
        );
        console.log(result.rows);
        return result.rows;
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw error;
    }
}
