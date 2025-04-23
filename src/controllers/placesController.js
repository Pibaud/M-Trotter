const { LPlaces, bboxPlaces, amenitylist, bestPlaces } = require('../services/placesService');
const { fetchImagesByPlaceId } = require('../services/uploadService');  // Ajout de cette importation

exports.postPlaces = async (req, res) => {
    try {
        const lieux = await LPlaces(req,res); // Appel au service

        return res.status(200).json(lieux); // Envoi de la réponse au client
    } catch (error) {
        console.error("Erreur dans postPlaces :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
};

exports.bboxPlaces = async (req, res) => {
    try {
        const { minlat, minlon, maxlat, maxlon } = req.body;

        if (!minlat || !minlon || !maxlat || !maxlon) {
            return res.status(400).json({ error: "Tous les paramètres bbox sont requis." });
        }

        const lieux = await bboxPlaces(minlat, minlon, maxlat, maxlon); // Appel au service
        return res.status(200).json(lieux); // Envoi de la réponse au client
    } catch (error) {
        console.error("Erreur dans bboxPlaces :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
}

exports.amenitylist = async(req, res) => {
    try {
        const {amenity, startid} = req.body;

        if (!amenity){
            return res.status(400).json({error : "pas d'amenity "});
        }
        const liste = await amenitylist(amenity, startid || 0);
        //on fait passer avgstars de string à float
        liste.forEach((element) => {
            element.avg_stars = parseFloat(element.avg_stars);
        });
        
        return res.status(200).json(liste);
    } catch (error) {
        console.error("Erreur dans amenitylist :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
}

exports.bestPlaces = async(req, res) => {
    try {
        const liste = await bestPlaces();
        
        // Convertir avgstars de string à float
        liste.forEach((element) => {
            element.avg_stars = parseFloat(element.avg_stars);
        });
        
        // Récupérer les photos pour chaque lieu
        const placesWithPhotos = await Promise.all(liste.map(async (place) => {
            try {
                // Pour chaque lieu, récupérer ses photos
                const photosResult = await fetchImagesByPlaceId(place.id.toString());
                
                // Ajouter les photos au lieu
                return {
                    ...place,
                    photos: photosResult.photos || []
                };
            } catch (error) {
                console.error(`Erreur lors de la récupération des photos pour le lieu ${place.id}:`, error);
                // En cas d'erreur, retourner le lieu sans photos
                return {
                    ...place,
                    photos: []
                };
            }
        }));
        
        return res.status(200).json(placesWithPhotos);
    } catch (error) {
        console.error("Erreur dans bestPlaces :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
}