const { Pool } = require('pg');

// Configuration de la base de données
const pool = new Pool({
    user: 'postgres',          // Remplacez par votre nom d'utilisateur PostgreSQL
    host: '217.182.79.84',                  // Adresse du serveur
    database: 'mtrotter',  // Nom de votre base
    password: '5877Kjn}U~qJ643J7sMjXS#]fjh4,2sn![/RQ+}2ZrYi.bK8aE7+$_h)#ebP6sWqhKg63XPK7p[2ni{:773=r4=WH7U8Pc4Q54BqtA-^?%@@VAEJ(79;2e-r(fR*2gF5',     // Mot de passe
    port: 5432,                         // Port PostgreSQL (par défaut : 5432)
});

// Exporter le pool pour l'utiliser dans les autres fichiers
module.exports = pool;
