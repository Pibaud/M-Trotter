const pool = require('../config/db');
const { getLocationId } = require('../services/tamIdService');

async function pointdepart(latitude, longitude) {
    const query = `
    SELECT location_name FROM (
        -- Requête sur planet_osm_point
        SELECT 
            COALESCE(name, ref, highway, amenity, 'Lieu inconnu') AS location_name, 
            ST_DistanceSphere(ST_Transform(way, 4326), ST_SetSRID(ST_MakePoint($2, $1), 4326)) AS distance
        FROM planet_osm_point
        WHERE name IS NOT NULL OR ref IS NOT NULL OR highway IS NOT NULL OR amenity IS NOT NULL

        UNION ALL

        -- Requête sur planet_osm_roads
        SELECT 
            COALESCE(name, ref, highway, 'Rue inconnue') AS location_name, 
            ST_DistanceSphere(ST_Transform(way, 4326), ST_SetSRID(ST_MakePoint($2, $1), 4326)) AS distance
        FROM planet_osm_roads
        WHERE name IS NOT NULL OR ref IS NOT NULL OR highway IS NOT NULL

        UNION ALL

        -- Requête sur planet_osm_line
        SELECT 
            COALESCE(name, ref, 'Ligne inconnue') AS location_name, 
            ST_DistanceSphere(ST_Transform(way, 4326), ST_SetSRID(ST_MakePoint($2, $1), 4326)) AS distance
        FROM planet_osm_line
        WHERE name IS NOT NULL OR ref IS NOT NULL

        ORDER BY distance
        LIMIT 5
    ) AS nearest_locations;
    `;

    const result = await pool.query(query, [latitude, longitude]);

    for (let row of result.rows) {
        const locationName = row.location_name;
        const locationId = await getLocationId(locationName, latitude, longitude);

        if (locationId !== null) {
            return locationName;
        }
    }

    return "Aucun lieu avec un tam ID trouvé";
}

module.exports = { pointdepart };
