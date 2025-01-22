const express = require('express');
const placesRoutes = require('./routes/placesRoutes');
const routeRoutes = require('./routes/routeRoutes');
const inscritpions = require('./routes/inscriptions');
const connexions = require('./routes/connexions');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
app.use(express.json());

// Middleware pour les routes
app.use('/api', routeRoutes); // itinéraires
app.use('/api', placesRoutes); //données
app.use('/comptes', inscritpions); //inscription
app.use('/comptes', connexions); //connexion

// Gestion des erreurs
app.use((err, req, res, next) => {
    console.error(err.message);
    res.status(500).json({ error: 'Internal Server Error' });
});

// Démarrer le serveur
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});