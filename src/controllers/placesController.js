const { LPlaces, bboxPlaces, amenitylist, bestPlaces } = require('../services/placesService'); // Assure-toi que l'importation est correcte

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
        console.log("Appel à amenitylist controller avec les paramètres :", amenity, startid);
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
        //on fait passer avgstars de string à float
        liste.forEach((element) => {
            element.avg_stars = parseFloat(element.avg_stars);
        });
        
        return res.status(200).json(liste);
    } catch (error) {
        console.error("Erreur dans bestPlaces :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
}