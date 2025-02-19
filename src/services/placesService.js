const { ListePlaces, BoxPlaces, AmenityPlaces } = require('../models/placesModel');

// GET pour récupérer des lieux
exports.LPlaces = async (req, res) => {
    try {
        const search = req.body.search;
        const lieux = await ListePlaces(search);
        return lieux;
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
};

exports.bboxPlaces = async (minlat, minlon, maxlat, maxlon) => {
    try {
        const lieux = await BoxPlaces(minlat, minlon, maxlat, maxlon);
        return lieux;
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
}

exports.amenitylist = async (amenity) => {
    try {
        const lieux = await AmenityPlaces(amenity);
        return lieux;
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
}
