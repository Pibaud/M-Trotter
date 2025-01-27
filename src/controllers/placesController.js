const { LPlaces, bboxPlaces } = require('../services/placesService'); // Assure-toi que l'importation est correcte

exports.getPlaces = async (req, res) => {
    try {
        const lieux = await LPlaces(req,res); // Appel au service
        res.status(200).json(lieux); // Envoi de la réponse au client
    } catch (error) {
        console.error("Erreur dans getPlaces :", error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
};


exports.postPlaces = async (req, res) => {
    try {
        const lieux = await LPlaces(req,res); // Appel au service
        res.status(200).json(lieux); // Envoi de la réponse au client
    } catch (error) {
        console.error("Erreur dans postPlaces :", error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
};

exports.bboxPlaces = async (req, res) => {
    try {
        const lieux = await bboxPlaces(req,res); // Appel au service
        res.status(200).json(lieux); // Envoi de la réponse au client
    } catch (error) {
        console.error("Erreur dans bboxPlaces :", error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
}