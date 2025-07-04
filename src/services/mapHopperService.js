const axios = require('axios');
const puppeteer = require('puppeteer');

const API_URL = 'https://graphhopper.com/api/1/route';

const getRoute = async (start, end, mode) => {
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
            instructions: response.data.paths[0].instructions,
            ascend: response.data.paths[0].ascend,
            descend: response.data.paths[0].descend
        };
    } catch (error) {
        console.error('Erreur de graphHopper:', error.response.data || error.message);
        throw new Error('Failed to fetch route from MapHopper');
    }
};

const getTransit = async (startId, endId, date, time, DepTypeNum, ArrTypeNum) => {
    const url = "https://www.tam-voyages.com/WebServices/TransinfoService/api/TSI/v1/PlanTrip/json";

    const DepType = DepTypeNum === 4 ? "STOP_PLACE" : "POI";
    const ArrType = ArrTypeNum === 4 ? "STOP_PLACE" : "POI";

    const params = {
        key: "TAM",
        DepId: startId,  // Identifiant de départ
        DepType: DepType, // Vérifie si c'est bien STOP_PLACE
        ArrId: endId,  // Identifiant d'arrivée
        ArrType: ArrType, // Vérifie si c'est bien POI
        date: date,
        DepartureTime: time, // Format HH-mm
        Algorithm: "FASTEST",
        Disruptions: 0,
        MaxWalkDist: "",
        Language: "FR",
    };

    console.log("URL de requête :", url);
    console.log("Paramètres envoyés :", params);

    try {
        const response = await axios.get(url, { params, headers: { "User-Agent": "Mozilla/5.0" } });
        console.log("Réponse API :", response.data);
        return response.data;
    } catch (error) {
        console.error("Erreur lors de la récupération des trajets :", error.message);
        return null;
    }
};

// 🔹 Test avec les valeurs qui fonctionnent sur le site
getTransit("5572$0", "3000822$0", "2025-01-30", "18-00", 4, 1).then(console.log);


module.exports = {
    getRoute,
    getTransit 
};
