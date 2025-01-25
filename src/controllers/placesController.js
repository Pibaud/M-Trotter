const { LPlaces } = require('../services/placesService'); // Assure-toi que l'importation est correcte

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
    const { data } = req.body;
    console.log("Données reçues du client :", data);
    try {
        const reponse = await LPlaces(data);  // Assure-toi que LPlaces est bien une fonction
        console.log("resto conseillé : ", reponse);
        res.json({ status: "Données bien reçues", places: reponse });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};