const { getRoute, getTransit } = require('../services/mapHopperService');
const { getLocationId } = require('../services/tamIdService');

exports.calculateRoute = async (req, res, next) => {
    try {
        const { startName, startLat, startLon, endName, endLat, endLon, mode, date, time } = req.query;

        if (!startName || !startLat || !startLon || !endName || !endLat || !endLon) {
            return res.status(400).json({ error: 'Missing required parameters' });
        }

        console.log("Calculating route...");

        const start = [parseFloat(startLat), parseFloat(startLon)];
        const end = [parseFloat(endLat), parseFloat(endLon)];

        if (mode === 'transit') {
            // Récupération des ID des lieux
            const startLocation = await getLocationId(startName, start[0], start[1]);
            const endLocation = await getLocationId(endName, end[0], end[1]);

            if (!startLocation || !endLocation) {
                return res.status(400).json({ error: 'Unable to find location IDs' });
            }

            // Appel du service de transport en commun avec les ID trouvés
            const transit = await getTransit(startLocation.id, endLocation.id, date, time);
            return res.status(200).json(transit);
        } else {
            // Calcul d'itinéraire pour les autres modes (ex: marche, vélo, voiture)
            const route = await getRoute(start, end, mode || 'foot');
            return res.status(200).json(route);
        }
    } catch (error) {
        next(error);
    }
};
