const pool = require('../config/db');

async function inscription(userData) {
    // exemple de code qui interagirait avec une base de données
    // const result = await database.insert('users', userData);
    // return result;

    console.log('nouveau compte enregistré :', userData);
    return { success: true, message: 'compte enregistré avec succée' };
}

async function connexion(credentials) {
    // exemple de code qui interagirait avec une base de données
    // const user = await database.find('users', { email: credentials.email });
    // if (user && user.password === credentials.password) {
    //     return { success: true, message: 'User logged in successfully' };
    // } else {
    //     return { success: false, message: 'Invalid credentials' };
    // }

    console.log('Le compte vient de se connecter:', credentials);
    return { success: true, message: 'Utilisateur connecté avec succée' };
}

module.exports = {
    inscription,
    connexion
};