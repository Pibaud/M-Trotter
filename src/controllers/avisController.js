const {newavis, fetchAvisById, deleteAvisById, likeAvisById, deletelike, fetchAvisbyUser} = require('../models/avisModel');
const jwt = require('jsonwebtoken');

const ACCESS_TOKEN_SECRET = 'votre_secret_access';

exports.getAvisByPlaceId = async (req, res) => {
    try {
        const { place_id, startid } = req.body; // On récupère place_id dans le corps de la requête

        if (!place_id) {
            return res.status(400).json({ error: 'place_id est requis.' });
        }

        const avis = await fetchAvisById(place_id, startid || 0);

        if (!avis || avis.length === 0) {
            return res.status(404).json({ error: 'Aucun avis trouvé pour ce lieu.' });
        }

        res.status(200).json({ avis });
    } catch (error) {
        console.error('Erreur lors de la récupération des avis:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
    }
};

exports.getAvisbyUser = async(req,res) => {
    try {
        const { accessToken } = req.body; // On récupère user_id dans le corps de la requête

        if (!accessToken) {
            return res.status(400).json({ error: "token d'acces est requis." });
        }

        const user_id = jwt.verify(accessToken, ACCESS_TOKEN_SECRET).id;

        const avis = await fetchAvisbyUser(user_id);

        if (!avis || avis.length === 0) {
            return res.status(404).json({ error: 'Aucun avis trouvé pour cet utilisateur.' });
        }

        res.status(200).json({ avis });
    } catch (error) {
        console.error('Erreur lors de la récupération des avis:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
    }
};


exports.postAvis = async (req, res) => {
    try {
        const { accesstoken, place_id, place_table, lavis, avis_parent, nb_etoile } = req.body;

        console.log("les données reçues : ", req.body);

        // Vérification des champs obligatoires
        if (!accesstoken || !place_id || !place_table || !lavis) {
            return res.status(400).json({ error: 'Champs obligatoires manquants' });
        }
        
        // Vérification de la valeur de nb_etoile
        if (avis_parent === undefined && (nb_etoile === undefined || nb_etoile < 1 || nb_etoile > 5)) {
            return res.status(400).json({ error: 'Les avis principaux doivent contenir une note entre 1 et 5 étoiles.' });
        }

        if (avis_parent !== undefined) {
            // Un avis qui est une réponse ne doit pas avoir de note
            if (nb_etoile !== undefined) {
                return res.status(400).json({ error: 'Les réponses aux avis ne doivent pas contenir de note.' });
            }
        }
        //on récupère le user_id à partir du token
        const decodedToken = jwt.verify(accesstoken, ACCESS_TOKEN_SECRET);
        console.log("le token : ", accesstoken, " le payload décodé : ", decodedToken);
        const user_id = decodedToken.id;
        console.log("le user_id : ", user_id);
    

        // Appel du modèle pour ajouter l'avis
        const nouvelAvis = await newavis({
            user_id,
            place_id,
            place_table,
            lavis,
            avis_parent : avis_parent || null,
            nb_etoile: nb_etoile || null
        });

        res.status(201).json({ success: true, message: 'Avis ajouté avec succès', avis: nouvelAvis });
    } catch (error) {
        console.error('Erreur lors de l\'ajout d\'un avis:', error);
        res.status(500).json({ success: false, error: 'Erreur interne du serveur' });
    }
};

exports.deleteAvis = async (req, res) => {
    try {
        const { avis_id } = req.body; // Récupère l'ID de l'avis dans le corps de la requête

        if (!avis_id) {
            return res.status(400).json({ error: 'avis_id est requis.' });
        }

        // Appel du modèle pour supprimer l'avis
        const deletedAvis = await deleteAvisById(avis_id);

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
        const { avis_id, user_id } = req.body; // Récupère l'ID de l'avis et l'ID de l'utilisateur dans le corps de la requête

        if (!avis_id || !user_id) {
            return res.status(400).json({ error: 'avis_id et user_id sont requis.' });
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
    try{ 
        const { avis_id, user_id } = req.body; // Récupère l'ID de l'avis et l'ID de l'utilisateur dans le corps de la requête

        if (!avis_id || !user_id) {
            return res.status(400).json({ error: 'avis_id et user_id sont requis.' });
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