const axios = require('axios');

exports.getplacesVelos = async (req, res) => {
    try {
        const URL = `https://montpellier-fr.fifteen.site/gbfs/en/station_status.json`;
        const response = await axios.get(URL);
        res.status(200).json({ response: response.data });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'erreur récupération status station velomag' });
    }
}

exports.getplacesPraking = async (req, res) => {
    try {
        const URL = `https://portail-api-data.montpellier3m.fr/offstreetparking?limit=1000`;
        const response = await axios.get(URL);
        const processedData = triJson(response.data); // Use a new variable for processed data
        res.status(200).json({ response: processedData }); // Send response only once
    } catch (error) {
        console.error(error);
        if (!res.headersSent) { // Ensure headers are not sent before sending error response
            res.status(500).json({ error: 'erreur récupération status station velomag' });
        }
    }
};

function triJson(json) {
    let jfinal = [];
    for (let elem = 0; elem < json.length; elem++) { // Fixed loop condition and 'length' typo
        let j = {};
        j['id'] = json[elem].id;
        j['name'] = json[elem]['name']?.value;
        j['location'] = json[elem]['location']?.value;
        j['nbplaces'] = json[elem]['availableSpotNumber']?.value;
        j['ouvert'] = json[elem]['status']?.value;
        j['placestotal'] = json[elem]['totalSpotNumber']?.value;
        j['info'] = json[elem]['category']?.value;
        jfinal.push(j); // Changed to push objects into an array
    }
    return jfinal; // Return an array instead of an object
};