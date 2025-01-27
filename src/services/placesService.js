const { ListePlaces, BoxPlaces } = require('../models/placesModel');

// GET pour récupérer des lieux
exports.LPlaces = async (req, res) => {
    try {
        const search = req.query.search || '';
        const lieux = await ListePlaces(search);
        return lieux;
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
};

exports.bboxPlaces = async (req, res) => {
    try {
        const lieux = await BoxPlaces(req, res);
        return lieux;
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
}
