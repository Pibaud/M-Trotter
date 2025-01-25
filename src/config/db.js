require('dotenv').config();

const { Pool } = require('pg');

// Configuration de la base de données
const pool = new Pool({
    user: 'postgres',
    host: '217.182.79.84',
    database: 'mtrotter',
    password: process.env.DB_PASSWORD,
    port: 5432,
});

module.exports = pool;
