const {newavis, fetchAvisById, deleteAvisById } = require('../models/avisModel');

exports.getAvisByPlaceId = async (req, res) => {
    try {
        const { place_id } = req.body; // On récupère place_id dans le corps de la requête

        if (!place_id) {
            return res.status(400).json({ error: 'place_id est requis.' });
        }

        const avis = await fetchAvisById(place_id);

        if (!avis || avis.length === 0) {
            return res.status(404).json({ error: 'Aucun avis trouvé pour ce lieu.' });
        }

        res.status(200).json({ avis });
    } catch (error) {
        console.error('Erreur lors de la récupération des avis:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
    }
};


exports.postAvis = async (req, res) => {
    try {
        const { user_id, place_id, place_table, lavis, photo_urls, avis_parent, nb_etoile } = req.body;

        // Vérification des champs obligatoires
        if (!user_id || !place_id || !place_table || !lavis) {
            return res.status(400).json({ error: 'Champs obligatoires manquants' });
        }

        // Vérification de la valeur de nb_etoile
        if (avis_parent === null && (nb_etoile === undefined || nb_etoile < 1 || nb_etoile > 5)) {
            return res.status(400).json({ error: 'Les avis principaux doivent contenir une note entre 1 et 5 étoiles.' });
        }

        if (avis_parent !== null) {
            // Un avis qui est une réponse ne doit pas avoir de note
            if (nb_etoile !== undefined) {
                return res.status(400).json({ error: 'Les réponses aux avis ne doivent pas contenir de note.' });
            }
        }

        // Appel du modèle pour ajouter l'avis
        const nouvelAvis = await newavis({
            user_id,
            place_id,
            place_table,
            lavis,
            photo_urls: photo_urls || [],
            avis_parent,
            nb_etoile: avis_parent === null ? nb_etoile : null // Force null pour les réponses
        });

        res.status(201).json({ message: 'Avis ajouté avec succès', avis: nouvelAvis });
    } catch (error) {
        console.error('Erreur lors de l\'ajout d\'un avis:', error);
        res.status(500).json({ error: 'Erreur interne du serveur' });
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
