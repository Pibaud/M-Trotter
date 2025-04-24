const { user } = require('pg/lib/defaults');
const { newavis, fetchAvisById, deleteAvisById, likeAvisById, deletelike, fetchAvisbyUser, updateAvis, updatereponses } = require('../models/avisModel');
const uploadService = require('../services/uploadService');
const jwt = require('jsonwebtoken');
const e = require('express');
require('dotenv').config();

exports.getAvisByPlaceId = async (req, res) => {
    try {
        const { place_id, startid, accessToken} = req.body; // On récupère place_id dans le corps de la requête

        if (!place_id || !accessToken) {
            return res.status(400).json({ error: 'place_id est requis.' });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        const avis = await fetchAvisById(place_id, startid || 0, user_id);

        if (!avis || avis.length === 0) {
            return res.status(200).json({avis: []});
        }

        res.status(200).json({ avis });
    } catch (error) {
        console.error('Erreur lors de la récupération des avis:', error);
        res.status(500).json({ error: 'Erreur interne du serveur : '+ error  });
    }
};

exports.getAvisbyUser = async (req, res) => {
    try {
        const { accessToken } = req.body; // On récupère user_id dans le corps de la requête

        if (!accessToken) {
            return res.status(400).json({ error: "token d'acces est requis." });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accesstoken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }
        
        const avis = await fetchAvisbyUser(user_id);

        if (!avis || avis.length === 0) {
            return res.status(200).json({ error: 'Aucun avis trouvé pour cet utilisateur.' });
        }

        res.status(200).json({ avis });
    } catch (error) {
        console.error('Erreur lors de la récupération des avis:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
    }
};


exports.postAvis = async (req, res) => {
    console.log("paramètres reçus :")
    console.dir(req.body);
    console.log("Contenu de req.file :", req.file);
    try {
        const { accesstoken, place_id, place_table, lavis, avis_parent, nb_etoile } = req.body;
        console.log("Contenu de req.file :", req.file);

        // Récupérer le chemin de la photo
        const photo = req.file ? req.file.path : null;
        console.log("le path de la photo : ", photo);

        console.log("les données reçues : ", req.body);

        let resphoto = "pas de photos";

        // Vérification des champs obligatoires
        if (!accesstoken || !place_id || !place_table || !lavis) {
            return res.status(400).json({ error: 'Champs obligatoires manquants' });
        }

        // Vérification de la valeur de nb_etoile
        if (!avis_parent && (nb_etoile === null || nb_etoile < 1 || nb_etoile > 5)) {
            return res.status(400).json({ error: 'Les avis principaux doivent contenir une note entre 1 et 5 étoiles.' });
        }

        if ((avis_parent && nb_etoile)) {
            return res.status(400).json({ error: 'Une réponse à un avis ne doit pas contenir de note.' });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accesstoken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        // Appel du modèle pour ajouter l'avis
        const nouvelAvis = await newavis({
            user_id,
            place_id,
            place_table,
            lavis,
            avis_parent: avis_parent || null,
            nb_etoile: nb_etoile || null
        });

        if (photo) {
            console.log("le code detecte une image")
            const id_avis = nouvelAvis.avis_id;
            const id_lieu = place_id;
            const id_user = user_id;
            const id_photo = photo;
            resphoto = await uploadService.processAndUploadImage(id_photo, id_lieu, id_avis);
        }

        res.status(201).json({ success: true, message: 'Avis ajouté avec succès', avis: nouvelAvis, Image: resphoto });
    } catch (error) {
        console.error('Erreur lors de l\'ajout d\'un avis:', error);
        res.status(500).json({ success: false, error: 'Erreur interne du serveur : ' + error });
    }
};


exports.deleteAvis = async (req, res) => {
    try {
        const { avis_id, accessToken} = req.body; // Récupère l'ID de l'avis dans le corps de la requête

        if (!avis_id || !accessToken) {
            return res.status(400).json({ error: 'avis_id est requis.' });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        // Appel du modèle pour supprimer l'avis
        try {
            const deletedAvis = await deleteAvisById(avis_id, user_id);
        } catch (error) {
            console.error('Erreur lors de la suppression de l\'avis erreur 406:', error);
            return res.status(406).json({ error });
        }

        if (!deletedAvis) {
            return res.status(404).json({ error: 'Avis non trouvé.' });
        }

        res.status(200).json({ message: 'Avis supprimé avec succès.' });
    } catch (error) {
        console.error('Erreur lors de la suppression de l\'avis:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
    }
};

exports.likeAvis = async (req, res) => {
    try {
        const { avis_id, accessToken } = req.body; // Récupère l'ID de l'avis et l'ID de l'utilisateur dans le corps de la requête

        if (!avis_id || !accessToken) {
            return res.status(400).json({ error: 'avis_id et user_id sont requis.' });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        // Appel du modèle pour ajouter le like
        const likedAvis = await likeAvisById(avis_id, user_id);

        if (!likedAvis) {
            return res.status(404).json({ error: 'Avis non trouvé.' });
        }

        res.status(200).json({ message: 'Like ajouté avec succès.' });
    } catch (error) {
        console.error('Erreur lors de l\'ajout d\'un like:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
    }
};

exports.unlikeAvis = async (req, res) => {
    try {
        const { avis_id, accessToken } = req.body; // Récupère l'ID de l'avis et l'ID de l'utilisateur dans le corps de la requête

        if (!avis_id || !accessToken) {
            return res.status(400).json({ error: 'avis_id et user_id sont requis.' });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        // Appel du modèle pour supprimer le like
        const unlikedAvis = await deletelike(avis_id, user_id);

        if (!unlikedAvis) {
            return res.status(404).json({ error: 'Avis non trouvé.' });
        }

        res.status(200).json({ message: 'Like supprimé avec succès.' });
    } catch (error) {
        console.error('Erreur lors de la suppression d\'un like:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
    }
}

exports.updateAvis = async (req, res) => {
    try {
        const { avis_id, accessToken, lavis, nb_etoile, avis_parent } = req.body; // Récupère l'ID de l'avis et l'ID de l'utilisateur dans le corps de la requête

        if (!avis_id || !accessToken || !lavis) {
            return res.status(400).json({ error: 'avis_id et accessToken et lavis sont requis.' });
        }

        let user_id;
        try {
            const decodedToken = jwt.verify(accessToken, process.env.ACCESS_TOKEN_SECRET);
            user_id = decodedToken.id;
        } catch (err) {
            return res.status(401).json({ error: 'Token invalide ou expiré' });
        }

        // Vérification de la valeur de nb_etoile
        if (nb_etoile && (nb_etoile < 1 || nb_etoile > 5)) {
            return res.status(400).json({ error: 'La note doit être comprise entre 1 et 5 étoiles.' });
        }

        if (avis_parent && nb_etoile) {
            return res.status(400).json({ error: 'Une réponse à un avis ne doit pas contenir de note.' });
        }
        
        if (avis_parent) {
            updatedAvis = await updatereponses(avis_id, user_id, lavis, avis_parent);
        }
        else {
            updatedAvis = await updateAvis(avis_id, user_id, lavis, nb_etoile);
        }

        if (!updatedAvis) {
            return res.status(404).json({ error: 'Avis non trouvé.' });
        }

        res.status(200).json({ message: 'Avis mis à jour avec succès.', avis: updatedAvis });
    } catch (error) {
        console.error('Erreur lors de la mise à jour de l\'avis:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
    }
}