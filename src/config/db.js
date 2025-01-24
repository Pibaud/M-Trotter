const { Pool } = require('pg');

// Configuration de la base de données
const pool = new Pool({
    user: DB_USER,          // Remplacez par votre nom d'utilisateur PostgreSQL
    host: DB_HOST,                  // Adresse du serveur
    database: DB_DATABSE,  // Nom de votre base
    password: DB_PASSWORD,     // Mot de passe
    port: 5432,                         // Port PostgreSQL (par défaut : 5432)
});

// Exporter le pool pour l'utiliser dans les autres fichiers
module.exports = pool;
