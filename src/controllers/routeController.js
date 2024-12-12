const { getRoute } = require('../services/osrmService');

exports.calculateRoute = async (req, res, next) => {
    try {
        const { startLat, startLon, endLat, endLon, mode } = req.query;

        if (!startLat || !startLon || !endLat || !endLon) {
            return res.status(400).json({ error: 'Missing required coordinates' });
        }

        const start = [parseFloat(startLon), parseFloat(startLat)];
        const end = [parseFloat(endLon), parseFloat(endLat)];
        const data = await getRoute(start, end, mode || 'driving');

        const routeResponse = {
            status: "success",
            start: data.waypoints[0].location, // Point de départ
            end: data.waypoints[1].location, // Point d'arrivée
            distance: data.routes[0].legs[0].distance, // Distance en mètres
            duration: data.routes[0].legs[0].duration, // Durée en secondes
            path: data.routes[0].geometry.coordinates // Coordonnées du chemin
        };

        res.status(200).json(routeResponse);
    } catch (error) {
        next(error);
    }
};
