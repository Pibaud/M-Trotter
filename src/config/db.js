require('dotenv').config();

const { Pool } = require('pg');

console.log('affichage du db password')
console.log(process.env.DB_PASSWORD)

// Configuration de la base de données
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'mtrotter',
    password: process.env.DB_PASSWORD,
    port: 5432,
});

module.exports = pool;
