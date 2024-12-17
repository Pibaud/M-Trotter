const express = require('express');
const dataRoutes = require('./routes/dataRoutes');
const routeRoutes = require('./routes/routeRoutes');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
app.use(express.json());

// Middleware pour les routes
app.use('/api', routeRoutes); // itinéraires
app.use('/api/data', dataRoutes); //données

// Gestion des erreurs
app.use((err, req, res, next) => {
    console.error(err.message);
    res.status(500).json({ error: 'Internal Server Error' });
});

// Démarrer le serveur
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});