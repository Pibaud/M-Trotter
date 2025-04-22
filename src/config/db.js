require('dotenv').config();

const { Pool } = require('pg');

// Configuration de la base de données
const pool = new Pool({
    user: 'postgres',
    host: 'localhost',
    database: 'mtrotter',
    password: process.env.DB_PASSWORD,
    port: 5432,
});

module.exports = pool;
