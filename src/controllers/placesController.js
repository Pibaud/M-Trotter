const { LPlaces } = require('../services/placesService'); // Assure-toi que l'importation est correcte

exports.getPlaces = async (req, res) => {
    const { search } = req.query; // Récupère le paramètre `search`
    if (!search) {
        return res.status(400).json({ message: "Le paramètre 'search' est requis." });
    }
    try {
        const lieux = await LPlaces(search);
        res.json(lieux);
    } catch (error) {
        console.error(error);
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