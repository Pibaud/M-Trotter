const pool = require('../config/db');

exports.ListePlaces = async (search) => {
    try {
        console.log("Recherche de :", search);
        const result = await pool.query(
            `SELECT name, amenity, ST_X(ST_Transform(way, 4326)) AS longitude, ST_Y(ST_Transform(way, 4326)) AS latitude, tags,
                    similarity(name, $1) AS sim
            FROM planet_osm_point
            WHERE name IS NOT NULL 
              AND (name ILIKE $2 OR similarity(name, $1) > 0.4) -- Priorité à ILIKE, seuil plus strict pour similarity
            ORDER BY CASE 
                WHEN name ILIKE $2 THEN 2  -- Priorité aux résultats exacts (ILIKE)
                ELSE similarity(name, $1)  -- Puis on trie par similarité
            END DESC
            LIMIT 10;`,
            [search, `%${search}%`]
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
