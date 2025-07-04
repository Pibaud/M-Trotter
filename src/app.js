const express = require('express');
const placesRoutes = require('./routes/placesRoutes');
const routeRoutes = require('./routes/routeRoutes');
const connexions = require('./routes/connexions');
const departtrajet = require ('./routes/depart')
const avis = require('./routes/avis');
const upload = require('./routes/uploadRoutes');
const modfication = require('./routes/modificationRoutes');
const cron = require('node-cron');
const verifierModifications = require('./script/verifierModif');
const verifierLieux = require('./script/verifierLieux');
const favoris = require('./routes/favorisRoutes');
const lieux = require('./routes/lieuxRoutes');
const tam = require('./routes/tamRoutes');
const rapport = require('./script/envoieRapport');
const uploadDir = '/var/www/m-trotter/uploads/';
const versionController = require('./controllers/versionController');
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
app.use('/modification', modfication); //modification
app.use('/favoris', favoris); //favoris
app.use('/lieux', lieux); //lieux
app.use('/tam', tam); //tam
app.use('/photo', express.static(uploadDir));
app.use('/version', versionController.getVersion);

// Gestion des erreurs
app.use((err, req, res, next) => {
    console.error(err.message);
    res.status(500).json({ error: 'Internal Server Error' });
});

// Démarrer le serveur
app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});

cron.schedule('0 5 * * *', () => {
    console.log('⏳ Exécution de la vérification des modifications...');
    verifierModifications();
    console.log('✅ Vérification des modifications terminée.');
    console.log('⏳ Exécution de la vérification des ajouts et suppressions...');
    verifierLieux();
    console.log('✅ Vérification des ajouts et suppressions terminée.');
}, {
    timezone: "Europe/Paris" // Remplacez par le fuseau horaire approprié

});

cron.schedule('0 7 * * *', () => {
    console.log('⏳ Envoi du rapport quotidien...');
    rapport.envoieRapport();
    console.log('✅ Rapport quotidien envoyé.');
}, {
    timezone: "Europe/Paris" // Remplacez par le fuseau horaire approprié
});
