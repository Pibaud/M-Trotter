const axios = require('axios');
const config = require('../config/default');

exports.getRoute = async (start, end, mode = 'driving') => {
    try {
        const url = `${config.osrmUrl}/route/v1/${mode}/${start[1]},${start[0]};${end[1]},${end[0]}?overview=full&geometries=geojson`;
        const response = await axios.get(url);
        return response.data;
    } catch (error) {
        throw new Error('Failed to fetch route from OSRM');
    }
};
