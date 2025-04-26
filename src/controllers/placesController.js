const e = require('express');
const { LPlaces, bboxPlaces, amenitylist, bestPlaces, addRecPhoto, delRecPhoto, alreadyRecPhoto, getPlaceById } = require('../services/placesService');
const { fetchImagesByPlaceId } = require('../services/uploadService');  // Ajout de cette importation
const jwt = require('jsonwebtoken');
const dotenv = require('dotenv');
const { user } = require('pg/lib/defaults');

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

exports.addRecPhoto = async (req, res) => {
    try {
        const { id_photo, accessToken, vote} = req.body;
        console.log("Appel à addRecPhoto avec les paramètres :", id_photo, accessToken);
        
        if (!id_photo || !accessToken || !vote) {
            return res.status(400).json({ error: "id_photo et accessToken et vote requis." });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        if (vote !== 1 && vote !== -1) {
            return res.status(400).json({ error: "Vote doit être 1 ou -1." });
        }
        
        const result = await addRecPhoto(id_photo, user_id, vote); // Appel au service
        return res.status(200).json(result);
    } catch (error) {
        console.error("Erreur dans addRecPhoto :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
}

exports.delRecPhoto = async (req, res) => {
    try {
        const { id_photo, accessToken } = req.body;
        console.log("Appel à delRecPhoto avec les paramètres :", id_photo);
        
        if (!id_photo || !accessToken) {
            return res.status(400).json({ error: "id_photo et accessToken requis." });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }
        
        const result = await delRecPhoto(id_photo, user_id); // Appel au service
        return res.status(200).json(result);
    } catch (error) {
        console.error("Erreur dans delRecPhoto :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
}

exports.alreadyRecPhoto = async (req, res) => {
    try {
        const { id_photo, accessToken } = req.body;
        console.log("Appel à alreadyRecPhoto avec les paramètres :", id_photo);
        
        if (!id_photo || !accessToken) {
            return res.status(400).json({ error: "id_photo et accessToken requis." });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }
        
        const result = await alreadyRecPhoto(id_photo, user_id); // Appel au service
        return res.status(200).json(result);
    } catch (error) {
        console.error("Erreur dans alreadyRecPhoto :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
}

exports.getPlaceById = async (req, res) => {
    try {
        const { id_place } = req.params;
        console.log("Appel à getPlaceById avec l'ID :", id);
        
        if (!id_place) {
            return res.status(400).json({ error: "id_place requis pour getplace." });
        }

        const place = await getPlaceById(id_place); // Appel au service
        if (!place) {
            return res.status(404).json({ error: "Lieu non trouvé." });
        }
        
        return res.status(200).json(place);
    } catch (error) {
        console.error("Erreur dans getPlaceById :", error);
        return res.status(500).json({ message: "Erreur interne du serveur." });
    }
}