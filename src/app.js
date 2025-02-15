const express = require('express');
const placesRoutes = require('./routes/placesRoutes');
const routeRoutes = require('./routes/routeRoutes');
const connexions = require('./routes/connexions');
const departtrajet = require ('./routes/depart')
const avis = require('./routes/avis');
const upload = require('./routes/uploadRoutes');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
app.use(express.json());

// Middleware pour les routes
app.use('/api', routeRoutes); // itinéraires
app.use('/api', placesRoutes); //données
app.use('/api', departtrajet); //départ
app.use('/api', avis); //avis
app.use('/api', upload); //upload
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