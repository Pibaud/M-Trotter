const {pointdepart} = require('../models/departModel');

exports.depart = async (req, res) => {
    try {
        const {latitude, longitude} = req.body;
        const depart = await pointdepart(latitude, longitude); // Appel au service
        res.status(200).json(depart); // Envoi de la réponse au client
    } catch (error) {
        console.error("Erreur dans depart :", error);
        res.status(500).json({ message: "Erreur interne du serveur." });
    }
};
