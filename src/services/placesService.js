const { ListePlaces, BoxPlaces, AmenityPlaces, BestPlaces, addRecPhoto, delRecPhoto, alreadyRecPhoto, getPlaceById } = require('../models/placesModel');

// GET pour récupérer des lieux
exports.LPlaces = async (req, res) => {
    try {
        const {search, startid} = req.body;
        const lieux = await ListePlaces(search, startid || 0);
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

exports.amenitylist = async (amenity, startid, ouver, notemin, wheelchair, takeaway, religion) => {
    console.log("Appel à amenitylist service avec les paramètres :", amenity, startid);
    try {
        const lieux = await AmenityPlaces(amenity, startid, ouver, notemin, wheelchair, takeaway, religion);
        console.log("Lieux récupérés :", lieux);
        return lieux;
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
}

exports.bestPlaces = async () => {
    try {
        const lieux = await BestPlaces();
        return lieux;
    } catch (error) {
        console.error(error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
}

exports.addRecPhoto = async (id_photo, id_user, vote) => {
    try {
        const result = await addRecPhoto(id_photo, id_user, vote);
        return result;
    } catch (error) {
        console.error(error);
        throw error; // Propager l'erreur pour la gestion ultérieure
    }
}

exports.delRecPhoto = async (id_photo, id_user) => {
    try {
        const result = await delRecPhoto(id_photo, id_user);
        return result;
    } catch (error) {
        console.error(error);
        throw error; // Propager l'erreur pour la gestion ultérieure
    }
}

exports.alreadyRecPhoto = async (id_photo, user_id) => {
    try {
        const result = await alreadyRecPhoto(id_photo, user_id);
        return result;
    } catch (error) {
        console.error(error);
        throw error; // Propager l'erreur pour la gestion ultérieure
    }
}

exports.getPlaceById = async (id) => {
    try {
        const result = await getPlaceById(id);
        return result;
    } catch (error) {
        console.error(error);
        throw error; // Propager l'erreur pour la gestion ultérieure
    }
}