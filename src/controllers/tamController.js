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
