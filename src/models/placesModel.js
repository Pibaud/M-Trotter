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
                    p."addr:housenumber",
                    ST_X(ST_Centroid(ST_Collect(ST_Transform(p.way, 4326)))) AS longitude, 
                    ST_Y(ST_Centroid(ST_Collect(ST_Transform(p.way, 4326)))) AS latitude, 
                    STRING_AGG(p.tags::TEXT, '; ') AS tags, 
                    MAX(similarity(p.name, $1)) AS sim, 
                    'point' AS type,
                    AVG(a.nb_etoiles) AS avg_stars,
                    count(a.nb_etoiles) AS nb_avis_stars
                FROM planet_osm_point p
                LEFT JOIN avis a ON p.osm_id = a.place_id
                WHERE p.name IS NOT NULL 
                AND (p.name ILIKE $2 OR similarity(p.name, $1) > 0.4)
                AND p.osm_id > $3
                GROUP BY p.osm_id, p.name, p.amenity, p."addr:housenumber"
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
        console.log("points :");
        console.dir(finalResults.points);
        return finalResults; // Renvoie un objet avec les résultats séparés par type
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw error;
    }
};


exports.BoxPlaces = async (minlat, minlon, maxlat, maxlon) => {
    try {
        const result = await pool.query(
            `SELECT DISTINCT osm_id as id, name, amenity, "addr:housenumber", 
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
            GROUP BY id, name, amenity, way, "addr:housenumber"
            LIMIT 50`,
            [minlon, minlat, maxlon, maxlat]
        );

        // Arrondir avg_stars au dixième
        result.rows.forEach((element) => {
            element.avg_stars = parseFloat(element.avg_stars);
        });

        return result.rows;
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw { error: "Erreur interne du serveur." };
    }
};

exports.AmenityPlaces = async (amenity, startid, ouvert, notemin) => {
    try {
        let result;
        if (ouvert) {
            // Quand l'utilisateur souhaite les établissements ouverts
            result = await pool.query(
                `SELECT p.osm_id as id, p.name, p.amenity, p."addr:housenumber",
                    ST_X(ST_Transform(p.way, 4326)) AS lon, 
                    ST_Y(ST_Transform(p.way, 4326)) AS lat,
                    p.tags->'opening_hours' AS opening_hours,
                    STRING_AGG(p.tags::TEXT, '; ') AS tags,
                    AVG(a.nb_etoiles) AS avg_stars,
                    count(a.nb_etoiles) AS nb_avis_stars
                FROM planet_osm_point p
                LEFT JOIN avis a ON p.osm_id = a.place_id
                WHERE p.name IS NOT NULL 
                  AND p.amenity = $1
                  AND p.osm_id > $2
                  AND p.tags->'opening_hours' IS NOT NULL
                  AND (AVG(a.nb_etoiles) >= $3 OR AVG(a.nb_etoiles) IS NULL)
                GROUP BY p.osm_id, p.name, p.amenity, p.way, p."addr:housenumber", p.tags
                LIMIT 30`,
                [amenity, startid, notemin]
            );

            // Filtrer pour déterminer les établissements actuellement ouverts
            const now = new Date();
            const filteredResults = result.rows.filter(place => {
                const openingHours = place.opening_hours;
                return isOpenNow(openingHours, now);
            });

            // Ne renvoyer que les 10 premiers résultats après filtrage
            return filteredResults.slice(0, 10);
        } else {
            // Requête normale sans filtre d'ouverture
            result = await pool.query(
                `SELECT p.osm_id as id, p.name, p.amenity, p."addr:housenumber",
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
                  AND (AVG(a.nb_etoiles) >= $3 OR AVG(a.nb_etoiles) IS NULL)
                GROUP BY p.osm_id, p.name, p.amenity, p.way, p."addr:housenumber"
                LIMIT 10`,
                [amenity, startid, notemin]
            );
            console.log("result amenity : ", result.rows);
            return result.rows;
        }
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw { error: "Erreur interne du serveur." };
    }
}

// Fonction simplifiée pour déterminer si un établissement est actuellement ouvert
function isOpenNow(openingHours, now) {
    try {
        // Cas faciles à détecter
        if (!openingHours) return false;
        if (openingHours === '24/7') return true;
        
        const currentDay = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'][now.getDay()];
        const currentTime = now.getHours() * 100 + now.getMinutes();
        
        // Format courant: "Mo-Fr 08:00-20:00"
        // Pour une première version, on détecte quelques patterns communs
        const dayPatterns = {
            'Mo-Fr': ['Mo', 'Tu', 'We', 'Th', 'Fr'],
            'Mo-Sa': ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'],
            'Sa-Su': ['Sa', 'Su']
        };
        
        // Diviser en sections (chaque section séparée par un point-virgule)
        const sections = openingHours.split(';').map(s => s.trim());
        
        for (const section of sections) {
            // Vérifier si le jour actuel est mentionné ou dans une plage
            let includesToday = false;
            
            // Vérifier les plages de jours (Mo-Fr, etc.)
            for (const [pattern, days] of Object.entries(dayPatterns)) {
                if (section.includes(pattern) && days.includes(currentDay)) {
                    includesToday = true;
                    break;
                }
            }
            
            // Vérifier mention directe du jour
            if (section.includes(currentDay)) {
                includesToday = true;
            }
            
            // Si les jours ne sont pas mentionnés, on suppose tous les jours
            if (!section.match(/Mo|Tu|We|Th|Fr|Sa|Su/)) {
                includesToday = true;
            }
            
            // Si cette section concerne le jour actuel, vérifier les heures
            if (includesToday) {
                // Extraire les intervalles de temps (ex: "08:00-20:00")
                const timeRanges = section.match(/\d{1,2}:\d{2}-\d{1,2}:\d{2}/g) || [];
                
                for (const range of timeRanges) {
                    const [start, end] = range.split('-');
                    const [startHour, startMin] = start.split(':').map(Number);
                    const [endHour, endMin] = end.split(':').map(Number);
                    
                    const startTime = startHour * 100 + startMin;
                    const endTime = endHour * 100 + endMin;
                    
                    // Gérer le cas où la fermeture est après minuit
                    if (endTime < startTime) {
                        if (currentTime >= startTime || currentTime <= endTime) {
                            return true;
                        }
                    } else if (currentTime >= startTime && currentTime <= endTime) {
                        return true;
                    }
                }
            }
        }
        
        return false;
    } catch (e) {
        console.error("Erreur lors de l'analyse des heures d'ouverture:", e);
        return false; // En cas d'erreur, considérer comme fermé
    }
}
exports.BestPlaces = async () => {
    try {
        const result = await pool.query(
            `SELECT 
                p.osm_id AS id, 
                p.name, 
                p.amenity, 
                p."addr:housenumber", 
                ST_X(ST_Transform(p.way, 4326)) AS lon, 
                ST_Y(ST_Transform(p.way, 4326)) AS lat,
                STRING_AGG(p.tags::TEXT, '; ') AS tags,
                AVG(a.nb_etoiles) AS avg_stars,
                COUNT(a.nb_etoiles) AS nb_avis_stars,
                -- Calcul du score pondéré
                (AVG(a.nb_etoiles) * 0.7 + COUNT(a.nb_etoiles) * 0.3) AS score
            FROM 
                planet_osm_point p
            LEFT JOIN 
                avis a ON p.osm_id = a.place_id
            WHERE 
                p.name IS NOT NULL
            GROUP BY 
                p.osm_id, p.name, p.amenity, p.way, p."addr:housenumber"
            HAVING 
                COUNT(a.nb_etoiles) > 0
            ORDER BY 
                score DESC
            LIMIT 10`
        );

        console.log("Meilleures places :")
        console.dir(result.rows)
        return result.rows;
    } catch (error) {
        console.error("Erreur lors de la récupération des places :", error);
        throw { error: "Erreur interne du serveur." };
    }
}

exports.addRecPhoto = async (id_photo, id_user, vote) => {
    try {
        const result = await pool.query(
            `INSERT INTO goodimage (id_image, id_user, vote_type) VALUES ($1, $2, $3) RETURNING *`,
            [id_photo, id_user, vote]
        );
        return result.rows[0];
    } catch (error) {
        console.error("Erreur lors de l'ajout de la photo :", error);
        throw { error: "Erreur interne du serveur." };
    }
}

exports.delRecPhoto = async (id_photo, id_user) => {
    try {
        const result = await pool.query(
            `DELETE FROM goodimage WHERE id_image = $1 AND id_user = $2 RETURNING *`,
            [id_photo, id_user]
        );
        return result.rows[0];
    } catch (error) {
        console.error("Erreur lors de la suppression de la photo :", error);
        throw { error: "Erreur interne du serveur." };
    }
}

exports.alreadyRecPhoto = async (id_photo, user_id) => {
    try {
        const result = await pool.query(
            `SELECT * FROM goodimage WHERE id_image = $1 AND id_user = $2`,
            [id_photo, user_id]
        );
        return result.rows.length > 0;
    } catch (error) {
        console.error("Erreur lors de la vérification de la photo :", error);
        throw { error: "Erreur interne du serveur." };
    }
}

exports.addOrUpdateRecPhoto = async (id_photo, id_user, vote) => {
    try {
        const result = await pool.query(
            `INSERT INTO goodimage (id_image, id_user, vote_type)
             VALUES ($1, $2, $3)
             ON CONFLICT (id_image, id_user)
             DO UPDATE SET vote_type = $3
             RETURNING *`,
            [id_photo, id_user, vote]
        );
        return result.rows[0];
    } catch (error) {
        console.error("Erreur lors de l'ajout ou de la mise à jour de la photo :", error);
        throw { error: "Erreur interne du serveur." };
    }
};

exports.getPlaceById = async (id) => {
    try {
        const result = await pool.query(
            `SELECT p.osm_id as id, p.name, p.amenity, p."addr:housenumber",
                    ST_X(ST_Transform(p.way, 4326)) AS lon, 
                    ST_Y(ST_Transform(p.way, 4326)) AS lat,
                    STRING_AGG(p.tags::TEXT, '; ') AS tags,
                    AVG(a.nb_etoiles) AS avg_stars,
                    count(a.nb_etoiles) AS nb_avis_stars
            FROM planet_osm_point p
            LEFT JOIN avis a ON p.osm_id = a.place_id
            WHERE p.name IS NOT NULL 
              AND p.osm_id = $1
            GROUP BY p.osm_id, p.name, p.amenity, p.way, p."addr:housenumber"`,
            [id]
        );

        console.log("Place pour l'ID ", id, " :")
        console.dir(result.rows)
        return result.rows;
    } catch (error) {
        console.error("Erreur lors de la récupération de la place :", error);
        throw { error: "Erreur interne du serveur." };
    }
}