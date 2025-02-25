const pool = require('../config/db');

exports.ListePlaces = async (search, startid) => {
    try {
        console.log("Recherche de :", search);

        // Définition des requêtes
        const pointsQuery = `
                SELECT 
                    p.osm_id as id,
                    p.name, 
                    p.amenity, 
                    ST_X(ST_Centroid(ST_Collect(ST_Transform(p.way, 4326)))) AS longitude, 
                    ST_Y(ST_Centroid(ST_Collect(ST_Transform(p.way, 4326)))) AS latitude, 
                    STRING_AGG(p.tags::TEXT, '; ') AS tags, 
                    MAX(similarity(p.name, $1)) AS sim, 
                    'point' AS type,
                    AVG(a.nb_etoiles) AS avg_stars
                FROM planet_osm_point p
                LEFT JOIN avis a ON p.osm_id = a.place_id
                WHERE p.name IS NOT NULL 
                AND (p.name ILIKE $2 OR similarity(p.name, $1) > 0.4)
                AND p.osm_id > $3
                GROUP BY p.osm_id, p.name, p.amenity
                ORDER BY CASE 
                    WHEN p.name ILIKE $2 THEN 2
                    ELSE MAX(similarity(p.name, $1))
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
            pool.query(pointsQuery, [search, `%${search}%`, startid]),
            pool.query(roadsQuery, [search, `%${search}%`]),
            pool.query(roadsQuery2, [search, `%${search}%`])
        ]);

        pointsResult.rows.forEach((element) => {
            element.avg_stars = parseFloat(element.avg_stars);
        });
        
        // Fusion des résultats
        // Création d'un objet avec 3 propriétés distinctes
        const finalResults = {
            points: pointsResult.rows,
            lines: roadsResult.rows.map(row => ({
                ...row,
                longitude: null,
                latitude: null,
                tags: null,
                sim: null
            })),
            roads: roadsResult2.rows.map(row => ({
                ...row,
                longitude: null,
                latitude: null,
                tags: null,
                sim: null
            }))
        };
        console.log("points :", finalResults.points);
        return finalResults; // Renvoie un objet avec les résultats séparés par type
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw error;
    }
};exports.ListePlaces = async (search, startid) => {
    try {
        console.log("Recherche de :", search);

        // Nettoyage du terme de recherche
        const safeSearch = search.replace(/%/g, '');

        // Définition des requêtes
        const pointsQuery = `
            SELECT 
                p.osm_id as id,
                p.name, 
                p.amenity, 
                ST_X(ST_Centroid(ST_Collect(ST_Transform(p.way, 4326)))) AS longitude, 
                ST_Y(ST_Centroid(ST_Collect(ST_Transform(p.way, 4326)))) AS latitude, 
                STRING_AGG(p.tags::TEXT, '; ') AS tags, 
                similarity(p.name, $1) AS sim, 
                'point' AS type,
                AVG(a.nb_etoiles) AS avg_stars,
                Count(a.nb_etoiles) AS nb_avis_stars
            FROM planet_osm_point p
            LEFT JOIN avis a ON p.osm_id = a.place_id
            WHERE p.name IS NOT NULL 
            AND (p.name ILIKE $2 OR similarity(p.name, $1) > 0.4)
            AND p.osm_id > $3
            GROUP BY p.osm_id, p.name, p.amenity
            ORDER BY CASE 
                WHEN p.name ILIKE $2 THEN 2
                ELSE similarity(p.name, $1)
            END DESC
            LIMIT 10;
        `;

        const roadsQuery = `
            SELECT name, amenity, 
                ST_AsGeoJSON(ST_Union(ST_Transform(way,4326))) AS geojson, 
                'road' AS type,
                NULL AS sim,
                NULL AS tags
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
            SELECT name, highway AS amenity, 
                ST_AsGeoJSON(ST_Transform(ST_Collect(way), 4326)) AS geojson, 
                'road' AS type,
                NULL AS sim,
                NULL AS tags
            FROM planet_osm_roads
            WHERE highway IS NOT NULL 
            AND name IS NOT NULL 
            AND (name ILIKE $2 OR similarity(name, $1) > 0.4)
            GROUP BY name, highway
            LIMIT 5;
        `;

        // Exécution des requêtes en parallèle
        const [pointsResult, roadsResult, roadsResult2] = await Promise.all([
            pool.query(pointsQuery, [safeSearch, `%${safeSearch}%`, startid]),
            pool.query(roadsQuery, [safeSearch, `%${safeSearch}%`]),
            pool.query(roadsQuery2, [safeSearch, `%${safeSearch}%`])
        ]);

        // Conversion des valeurs null en 0 pour avg_stars
        pointsResult.rows.forEach((element) => {
            element.avg_stars = parseFloat(element.avg_stars);
        });

        // Fusion des résultats
        const finalResults = {
            points: pointsResult.rows,
            lines: roadsResult.rows,
            roads: roadsResult2.rows
        };

        console.log("points :", finalResults.points);
        return finalResults;
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw error;
    }
};


exports.BoxPlaces = async (minlat, minlon, maxlat, maxlon) => {
    try {
        const result = await pool.query(
            `SELECT DISTINCT osm_id as id, name, amenity,
                ST_X(ST_Transform(way, 4326)) AS lon, 
                ST_Y(ST_Transform(way, 4326)) AS lat,
                STRING_AGG(tags::TEXT, '; ') AS tags,
                AVG(a.nb_etoiles) AS avg_stars,
                count(a.nb_etoiles) AS nb_avis_stars
            FROM planet_osm_point 
            LEFT JOIN avis a ON osm_id = a.place_id
            WHERE name IS NOT NULL AND amenity IS NOT NULL
            AND ST_Intersects(
                ST_Transform(way, 4326), 
                ST_MakeEnvelope($1, $2, $3, $4, 4326)
                )
            GROUP BY id, name, amenity, way
            LIMIT 50`,
            [minlon, minlat, maxlon, maxlat]
        );
        return result.rows;
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw { error: "Erreur interne du serveur." };
    }
};

exports.AmenityPlaces = async (amenity, startid) => {
    try {
        const result = await pool.query(
            `SELECT p.osm_id as id, p.name, p.amenity,
                    ST_X(ST_Transform(p.way, 4326)) AS lon, 
                    ST_Y(ST_Transform(p.way, 4326)) AS lat,
                    STRING_AGG(p.tags::TEXT, '; ') AS tags,
                    AVG(a.nb_etoiles) AS avg_stars,
                    count(a.nb_etoiles) AS nb_avis_stars
            FROM planet_osm_point p
            LEFT JOIN avis a ON p.osm_id = a.place_id
            WHERE p.name IS NOT NULL 
              AND p.amenity = $1
              AND p.osm_id > $2
            GROUP BY p.osm_id, p.name, p.amenity, p.way
            LIMIT 10`,
            [amenity, startid]
        );

        console.log("Places pour l'AMENITY ", amenity, " :")
        console.dir(result.rows)
        return result.rows;
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw { error: "Erreur interne du serveur." };
    }
}
