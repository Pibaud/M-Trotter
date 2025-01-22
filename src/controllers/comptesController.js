const {inscription, connexion} = require('../models/comptesModel');

exports.inscription = async (req, res) => {
    const { data } = req.body;
    console.log("Données reçues du client pour l'inscription:", data);
    try {
        const reussite = await inscription(data);
        console.log("inscription reussie : ", reussite);
        res.json({ status: "Inscription bien reçue"});
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
 };

exports.connexions = async (req, res) => {
    const {data} = req.body;
    console.log("Données reçues du client pour la connexion:", data);
    try {
        const reussite = await connexion(data);
        console.log("connexion reussie : ", reussite);
        res.json({ status: "Connexion bien reçue"});
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
 };