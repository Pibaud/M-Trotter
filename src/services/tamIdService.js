const axios = require('axios');

exports.getLocationId = async (placeName, lat, lon) => {
    try {
        const url = `https://api.tam.cityway.fr/address?Key=TAM&Keywords=${encodeURIComponent(placeName)}&MaxItems=5`;
        const response = await axios.get(url);
        
        if (response.data.StatusCode !== 200 || !response.data.Data || response.data.Data.length === 0) {
            throw new Error('Lieu non trouvé');
        }

        // Trouver le meilleur match en fonction des coordonnées GPS
        let bestMatch = null;
        let bestDistance = Infinity;

        response.data.Data.forEach(location => {
            if (location.Latitude && location.Longitude) {
                const distance = Math.sqrt(
                    Math.pow(location.Latitude - lat, 2) + Math.pow(location.Longitude - lon, 2)
                );
                if (distance < bestDistance) {
                    bestDistance = distance;
                    bestMatch = location;
                }
            }
        });

        if (!bestMatch) {
            throw new Error('Aucune correspondance de coordonnées trouvée');
        }

        return {
            id: bestMatch.Id,
            name: bestMatch.Name,
            latitude: bestMatch.Latitude,
            longitude: bestMatch.Longitude
        };

    } catch (error) {
        console.error('Erreur lors de la récupération de l\'ID du lieu:', error.message);
        return null;
    }
};
if (require.main === module) {
    console.log("Testing TAM ID service...");
    getLocationId("Saint-Éloi", 43.624305, 3.861029)
        .then(data => console.log(data))
        .catch(err => console.error(err));
}