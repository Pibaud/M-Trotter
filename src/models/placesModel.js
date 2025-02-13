const pool = require('../config/db');

exports.ListePlaces = async (search) => {
    try {
        console.log("Recherche de :", search);

        // Définition des requêtes
        const pointsQuery = `
            SELECT name, 
                amenity, 
                ST_X(ST_Centroid(ST_Collect(ST_Transform(way,4326)))) AS longitude, 
                ST_Y(ST_Centroid(ST_Collect(ST_Transform(way,4326)))) AS latitude, 
                STRING_AGG(tags::TEXT, '; ') AS tags, 
                MAX(similarity(name, $1)) AS sim, 
                'point' AS type
            FROM planet_osm_point
            WHERE name IS NOT NULL 
            AND (name ILIKE $2 OR similarity(name, $1) > 0.4)
            GROUP BY name, amenity
            ORDER BY CASE 
                WHEN name ILIKE $2 THEN 2
                ELSE MAX(similarity(name, $1))
            END DESC
            LIMIT 10;

        `;

        const roadsQuery = `
            SELECT name, amenity, 
                ST_AsGeoJSON(ST_Union(ST_Transform(way,4326))) AS geojson, 
                'road' AS type
            FROM planet_osm_line
            WHERE name IS NOT NULL 
            AND (name ILIKE $2 OR similarity(name, $1) > 0.4)
            GROUP BY name, amenity
            ORDER BY CASE 
                WHEN name ILIKE $2 THEN 2
                ELSE similarity(name, $1)
            END DESC
            LIMIT 10;

        `;

        const roadsQuery2 = `
            SELECT name, highway AS amenity, ST_AsGeoJSON(ST_Transform(ST_Collect(way), 4326)) AS geojson, 'road' AS type
            FROM planet_osm_roads
            WHERE highway IS NOT NULL 
            AND name IS NOT NULL 
            AND (name ILIKE $2 OR similarity(name, $1) > 0.4)
            GROUP BY name, highway
            LIMIT 5;
        `;


        // Exécution des requêtes en parallèle
        const [pointsResult, roadsResult, roadsResult2] = await Promise.all([
            pool.query(pointsQuery, [search, `%${search}%`]),
            pool.query(roadsQuery, [search, `%${search}%`]),
            pool.query(roadsQuery2, [search, `%${search}%`])
        ]);

        // Fusion des résultats
        const finalResults = [
            ...pointsResult.rows,
            ...roadsResult.rows.map(row => ({ ...row, longitude: null, latitude: null, tags: null, sim: null })),
            ...roadsResult2.rows.map(row => ({ ...row, longitude: null, latitude: null, tags: null, sim: null }))
        ];

        console.log(finalResults);
        return finalResults; // Renvoie un tableau avec les résultats fusionnés
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw error;
    }
};

exports.BoxPlaces = async (minlat, minlon, maxlat, maxlon) => {
    try {
        const result = await pool.query(
            `SELECT DISTINCT name, amenity,
                ST_X(ST_Transform(way, 4326)) AS lon, 
                ST_Y(ST_Transform(way, 4326)) AS lat,
                STRING_AGG(tags::TEXT, '; ') AS tags
            FROM planet_osm_point 
            WHERE name IS NOT NULL AND amenity IS NOT NULL
            AND ST_Intersects(
                ST_Transform(way, 4326), 
                ST_MakeEnvelope($1, $2, $3, $4, 4326)
                )
            GROUP BY name, amenity, way
            LIMIT 50`,
                [minlon, minlat, maxlon, maxlat]
            );
        return result.rows;
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw { error: "Erreur interne du serveur." };
    }
};

