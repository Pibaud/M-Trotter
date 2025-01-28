const {inscription, connexion} = require('../models/comptesModel');

exports.inscription = async (req, res) => {
    // Récupérer les données depuis req.query si elles ne sont pas dans req.body
    const { email, username, password } = req.body.email
        ? req.body
        : req.query;

    // Vérification des données
    if (!email || !username || !password) {
        return res.status(400).json({ message: "Tous les champs (email, username, password) sont obligatoires." });
    }

    console.log("Données reçues du client pour l'inscription:", { email, username, password });

    if (typeof password !== "string") {
        console.error("Erreur : Le mot de passe n'est pas une chaîne de caractères.");
        return res.status(400).json({
          error: "Le mot de passe doit être une chaîne de caractères.",
        });
    }

    try {
        const reussite = await inscription({ email, username, password }); // Appel du service avec les données
        console.log("Inscription réussie :", reussite);
        res.json({ status: "Inscription bien reçue", success: true });
    } catch (error) {
        console.error("Erreur lors de l'inscription :", error.message);
        res.status(500).json({ message: "Erreur interne du serveur.", error: error.message });
    }
};

exports.connexions = async (req, res) => {
    const { EorU, password } = req.body; // On récupère depuis req.query
    console.log("Tentative de connexion :", { EorU });

    if (!EorU || !password) {
        return res.status(400).json({ message: "Email/Username et mot de passe sont requis." });
    }

    try {
        const result = await connexion(EorU, password);
        console.log("Connexion réussie :", result);
        res.json({ success: true, message: "Connexion réussie.", data: result });
    } catch (error) {
        res.status(401).json({ success: false, message: error.message });
    }
};
