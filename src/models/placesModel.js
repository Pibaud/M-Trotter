const pool = require('../config/db');

exports.ListePlaces = async (search) => {
    try {
        console.log("Recherche de :", search);
        const result = await pool.query(
            'SELECT DISTINCT name FROM planet_osm_point WHERE name ILIKE $1 LIMIT 10;', 
            [`%${search}%`] // Le % permet de chercher partout dans le nom
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
