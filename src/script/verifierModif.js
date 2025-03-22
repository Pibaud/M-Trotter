const db = require('../config/db');
const { log } = Math;

const calculerValeurUtilisateur = (fiabilite) => {
    if (fiabilite < 0) {
        return 1 / -fiabilite;
    }
    return (fiabilite + 1) / log(fiabilite + 3);
};

const verifierModifications = async () => {
    try {
        const modifications = await db.query(`
            SELECT id_modification
            FROM modifications
            WHERE etat = 'pending' AND date_proposition <= NOW() - INTERVAL '7 days'
        `);

        for (const { id_modification } of modifications.rows) {
            const votes = await db.query(`
                SELECT v.vote, v.id_utilisateur, u.fiabilite
                FROM validation_modification v
                JOIN users u ON v.id_utilisateur = u.id
                WHERE v.id_modification = $1
            `, [id_modification]);

            if (votes.rows.length < 20) {
                await db.query(`
                    UPDATE modifications SET etat = 'refusee' WHERE id_modification = $1
                `, [id_modification]);
                continue;
            }

            let score = 0;
            votes.rows.forEach(({ vote, fiabilite }) => {
                const valeur = calculerValeurUtilisateur(fiabilite);
                score += (vote === 'confirm' ? valeur : -valeur);
            });

            const nouveauEtat = score > 0 ? 'validee' : 'refusee';

            await db.query('BEGIN'); // Début de la transaction
            try {
                await db.query(`
                    UPDATE modifications SET etat = $1 WHERE id_modification = $2
                `, [nouveauEtat, id_modification]);

                const queries = votes.rows.map(({ vote, id_utilisateur }) => {
                    const bonChoix = (vote === 'confirm' && nouveauEtat === 'validee') ||
                                     (vote === 'infirme' && nouveauEtat === 'refusee');
                    return `WHEN id = ${id_utilisateur} THEN fiabilite + (${bonChoix ? 1 : -1})`;
                });

                if (queries.length > 0) {
                    await db.query(`
                        UPDATE users
                        SET fiabilite = CASE ${queries.join(" ")} END
                        WHERE id IN (${votes.rows.map(v => v.id_utilisateur).join(",")})
                    `);
                }

                await db.query('COMMIT'); // Valider la transaction
            } catch (error) {
                await db.query('ROLLBACK'); // Annuler en cas d'erreur
                console.error("Erreur lors de la mise à jour des fiabilités :", error);
            }

            console.log(`Modification ${id_modification} => ${nouveauEtat}`);
        }
    } catch (error) {
        console.error("Erreur lors de la vérification des modifications :", error);
    }
};

module.exports = verifierModifications;
