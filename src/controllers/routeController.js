const { getRoute } = require('../services/mapHopperService');

exports.calculateRoute = async (req, res, next) => {
    try {
        const { startLat, startLon, endLat, endLon, mode } = req.query;

        if (!startLat || !startLon || !endLat || !endLon) {
            return res.status(400).json({ error: 'Missing required coordinates' });
        }

        console.log("calcuating route")

        const start = [parseFloat(startLat), parseFloat(startLon)];
        const end = [parseFloat(endLat), parseFloat(endLon)];
        const route = await getRoute(start, end, mode || 'foot');

        res.status(200).json(route);
    } catch (error) {
        next(error);
    }
};

