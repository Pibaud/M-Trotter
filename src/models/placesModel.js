const pool = require('../config/db');

exports.ListePlaces = async (search) => {
    try {
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
