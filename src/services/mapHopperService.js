const axios = require('axios');

const API_URL = 'https://graphhopper.com/api/1/route';

exports.getRoute = async (start, end, mode) => {
    try {
        const URL = `${API_URL}?point=${start[0]},${start[1]}&point=${end[0]},${end[1]}&profile=${mode}&locale=fr&instructions=true&calc_points=true&points_encoded=false&key=${process.env.MAPHOPPER_API_KEY}`;
        const response = await axios.get(URL);

        console.log('response', response.data);

        return {
            status: 'success',
            start,
            end,
            distance: response.data.paths[0].distance,
            duration: response.data.paths[0].time / 1000, // Conversion en secondes
            path: response.data.paths[0].points.coordinates,
            instructions: response.data.paths[0].instructions

        };
    } catch (error) {
        console.error('Error fetching route:', error.response?.data || error.message);
        throw new Error('Failed to fetch route from MapHopper');
    }
};

exports.getTransitRoute = async (start, end) => {
    try {
        const URL = `${API_URL}?point=${start[0]},${start[1]}&point=${end[0]},${end[1]}&profile=pt&locale=fr&instructions=true&calc_points=true&points_encoded=false&key=${process.env.MAPHOPPER_API_KEY}`;
        const response = await axios.get(URL);

        console.log('response', response.data);

        return {
            status: 'success',
            start,
            end,
            distance: response.data.paths[0].distance,
            duration: response.data.paths[0].time / 1000, // Conversion en secondes
        };
    } catch (error) {
        console.error('Error fetching route:', error.response?.data || error.message);
        throw new Error('Failed to fetch route from MapHopper');
    }
};
