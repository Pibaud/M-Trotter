const db = require('../config/db');
const { log } = Math;

// Fonction pour calculer la valeur d'un utilisateur en fonction de sa fiabilité
const calculerValeurUtilisateur = (fiabilite) => {
    if (fiabilite < 0) {
        return 1 / -fiabilite;
    }
    return (fiabilite + 1) / log(fiabilite + 3);
};

// Fonction pour vérifier les modifications à valider
const verifierModifications = async () => {
    try {
        // Récupérer toutes les modifications en attente depuis au moins 7 jours
        const modifications = await db.query(`
            SELECT id_modification
            FROM modifications
            WHERE etat = 'pending' AND date_proposition <= NOW() - INTERVAL '7 days'
        `);

        for (const { id_modification } of modifications.rows) {
            // Récupérer les votes et la fiabilité des utilisateurs ayant voté
            const votes = await db.query(`
                SELECT v.vote, u.fiabilite
                FROM validation_modification v
                JOIN users u ON v.id_utilisateur = u.id
                WHERE v.id_modification = $1
            `, [id_modification]);

            // Si le nombre total de votes est inférieur à 20, on ignore la modification
            if (votes.rows.length < 20) {
                await db.query(`
                    UPDATE modifications SET etat = 'refusee' WHERE id_modification = $1
                `, [id_modification]);
                continue;
            }

            // Calcul du score de la modification
            let score = 0;
            votes.rows.forEach(({ vote, fiabilite }) => {
                const valeur = calculerValeurUtilisateur(fiabilite);
                if (vote === 'confirm') {
                    score += valeur;
                } else if (vote === 'infirme') {
                    score -= valeur;
                }
            });

            // Appliquer ou refuser la modification selon le score
            const nouveauEtat = score > 0 ? 'validee' : 'refusee';
            await db.query(`
                UPDATE modifications SET etat = $1 WHERE id_modification = $2
            `, [nouveauEtat, id_modification]);

            console.log(`Modification ${id_modification} => ${nouveauEtat}`);
        }
    } catch (error) {
        console.error("Erreur lors de la vérification des modifications :", error);
    }
};

module.exports = verifierModifications;